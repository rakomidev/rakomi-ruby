# frozen_string_literal: true

require "minitest/autorun"
require "rack/test"
require "omniauth-rakomi"

OmniAuth.config.logger = Logger.new(IO::NULL)
OmniAuth.config.request_validation_phase = nil

class StrategyTest < Minitest::Test
  include Rack::Test::Methods

  ISSUER = "https://api.rakomi.com"

  DiscoveredConfig = Struct.new(:issuer, :authorization_endpoint, :token_endpoint, :userinfo_endpoint, :jwks_uri,
                                :end_session_endpoint, keyword_init: true)

  def setup
    @discovered_issuers = []
    discovered = @discovered_issuers
    config = DiscoveredConfig.new(
      issuer: ISSUER,
      authorization_endpoint: "https://accounts.rakomi.com/authorize",
      token_endpoint: "#{ISSUER}/oauth/token",
      userinfo_endpoint: "#{ISSUER}/oauth/userinfo",
      jwks_uri: "#{ISSUER}/.well-known/jwks.json"
    )
    @config_class = ::OpenIDConnect::Discovery::Provider::Config
    @original_discover = @config_class.method(:discover!)
    @config_class.singleton_class.send(:remove_method, :discover!)
    @config_class.define_singleton_method(:discover!) do |issuer, *|
      discovered << issuer
      config
    end
    @strategy_options = {}
  end

  def teardown
    @config_class.singleton_class.send(:remove_method, :discover!)
    @config_class.define_singleton_method(:discover!, @original_discover)
  end

  def app
    options = { client_options: { identifier: "client-123", redirect_uri: "https://app.example.com/auth/rakomi/callback" } }
    options = options.merge(@strategy_options)
    Rack::Builder.new do
      use OmniAuth::Builder do
        provider :rakomi, options
      end
      run ->(_env) { [404, {}, ["not found"]] }
    end
  end

  def authorize_redirect
    post "/auth/rakomi", {}, "rack.session" => {}
    assert_equal 302, last_response.status
    location = URI(last_response.headers["Location"])
    [location, URI.decode_www_form(location.query).to_h]
  end

  def test_strategy_is_registered_as_rakomi
    assert_equal "rakomi", OmniAuth::Strategies::Rakomi.default_options[:name]
    assert_operator OmniAuth::Strategies::Rakomi, :<, OmniAuth::Strategies::OpenIDConnect
  end

  def test_defaults
    options = OmniAuth::Strategies::Rakomi.default_options
    assert_equal ISSUER, options[:issuer]
    assert_equal true, options[:discovery]
    assert_equal true, options[:pkce]
    assert_equal "code", options[:response_type]
    assert_equal %i[openid email profile], options[:scope]
  end

  def test_request_phase_discovers_the_rakomi_issuer_and_redirects_with_pkce
    location, query = authorize_redirect

    assert_equal [ISSUER], @discovered_issuers
    assert_equal "accounts.rakomi.com", location.host
    assert_equal "/authorize", location.path
    assert_equal "client-123", query["client_id"]
    assert_equal "code", query["response_type"]
    assert_equal "openid email profile", query["scope"]
    assert_equal "https://app.example.com/auth/rakomi/callback", query["redirect_uri"]
    assert_equal "S256", query["code_challenge_method"]
    refute_empty query["code_challenge"].to_s
    refute_empty query["state"].to_s
    refute_empty query["nonce"].to_s
  end

  def test_issuer_can_be_overridden
    @strategy_options = { issuer: "https://id.example.com" }
    authorize_redirect
    assert_equal ["https://id.example.com"], @discovered_issuers
  end
end
