# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "rakomi"

class FakeHTTP
  attr_reader :requested

  def initialize(responses)
    @responses = responses
    @requested = []
  end

  def get(uri)
    @requested << uri.to_s
    @responses.fetch(uri.to_s) { [404, "{}"] }
  end
end

class DiscoverTest < Minitest::Test
  ISSUER = "https://api.rakomi.com"
  CONFIG_URL = "#{ISSUER}/.well-known/openid-configuration".freeze
  JWKS_URL = "#{ISSUER}/.well-known/jwks.json".freeze

  def configuration(overrides = {})
    {
      "issuer" => ISSUER,
      "authorization_endpoint" => "https://accounts.rakomi.com/authorize",
      "token_endpoint" => "#{ISSUER}/oauth/token",
      "userinfo_endpoint" => "#{ISSUER}/oauth/userinfo",
      "jwks_uri" => JWKS_URL,
      "response_types_supported" => ["code"],
      "subject_types_supported" => ["public"],
      "id_token_signing_alg_values_supported" => ["RS256"]
    }.merge(overrides)
  end

  def jwks
    { "keys" => [{ "kty" => "RSA", "kid" => "k1", "alg" => "RS256", "use" => "sig", "n" => "AQAB", "e" => "AQAB" }] }
  end

  def http(config = configuration, keys = jwks)
    FakeHTTP.new(CONFIG_URL => [200, JSON.generate(config)], JWKS_URL => [200, JSON.generate(keys)])
  end

  def assert_refused(pattern, &block)
    error = assert_raises(Rakomi::DiscoveryError, &block)
    assert_match pattern, error.message
  end

  def test_discovers_configuration_and_keys
    fake = http
    discovery = Rakomi.discover(ISSUER, http: fake)

    assert_equal ISSUER, discovery.issuer
    assert_equal "https://accounts.rakomi.com/authorize", discovery.authorization_endpoint
    assert_equal "#{ISSUER}/oauth/token", discovery.token_endpoint
    assert_equal "#{ISSUER}/oauth/userinfo", discovery.userinfo_endpoint
    assert_equal "k1", discovery.keys.first["kid"]
    assert_equal [CONFIG_URL, JWKS_URL], fake.requested
  end

  def test_default_issuer
    assert_equal ISSUER, Rakomi::DEFAULT_ISSUER
    assert_equal ISSUER, Rakomi.discover(http: http).issuer
  end

  def test_issuer_with_path_keeps_the_path
    issuer = "https://id.example.com/tenant"
    fake = FakeHTTP.new(
      "#{issuer}/.well-known/openid-configuration" => [200, JSON.generate(configuration("issuer" => issuer))],
      JWKS_URL => [200, JSON.generate(jwks)]
    )
    assert_equal issuer, Rakomi.discover(issuer, http: fake).issuer
  end

  def test_refuses_http_issuer
    assert_refused(/issuer must be an https URL/) { Rakomi.discover("http://api.rakomi.com", http: http) }
  end

  def test_refuses_issuer_with_query
    assert_refused(/query or fragment/) { Rakomi.discover("#{ISSUER}?x=1", http: http) }
  end

  def test_refuses_issuer_with_userinfo
    assert_refused(/user information/) { Rakomi.discover("https://u:p@api.rakomi.com", http: http) }
  end

  def test_refuses_issuer_mismatch
    config = configuration("issuer" => "https://evil.example.com")
    assert_refused(/expected "#{Regexp.escape(ISSUER)}"/) { Rakomi.discover(ISSUER, http: http(config)) }
  end

  def test_trailing_slash_is_not_the_same_issuer
    fake = FakeHTTP.new(CONFIG_URL => [200, JSON.generate(configuration)], JWKS_URL => [200, JSON.generate(jwks)])
    assert_refused(/names issuer/) { Rakomi.discover("#{ISSUER}/", http: fake) }
  end

  def test_refuses_missing_required_field
    config = configuration
    config.delete("jwks_uri")
    config.delete("subject_types_supported")
    assert_refused(/lacks jwks_uri, subject_types_supported/) { Rakomi.discover(ISSUER, http: http(config)) }
  end

  def test_refuses_http_jwks_uri
    config = configuration("jwks_uri" => "http://api.rakomi.com/.well-known/jwks.json")
    assert_refused(/jwks_uri must be an https URL/) { Rakomi.discover(ISSUER, http: http(config)) }
  end

  def test_refuses_http_endpoint
    config = configuration("token_endpoint" => "http://api.rakomi.com/oauth/token")
    assert_refused(/token_endpoint must be an https URL/) { Rakomi.discover(ISSUER, http: http(config)) }
  end

  def test_refuses_non_200
    fake = FakeHTTP.new(CONFIG_URL => [302, ""])
    assert_refused(/answered HTTP 302/) { Rakomi.discover(ISSUER, http: fake) }
  end

  def test_refuses_invalid_json
    fake = FakeHTTP.new(CONFIG_URL => [200, "<html>"])
    assert_refused(/not valid JSON/) { Rakomi.discover(ISSUER, http: fake) }
  end

  def test_refuses_non_object_json
    fake = FakeHTTP.new(CONFIG_URL => [200, "[]"])
    assert_refused(/not a JSON object/) { Rakomi.discover(ISSUER, http: fake) }
  end

  def test_refuses_empty_jwks
    assert_refused(/jwks has no keys/) { Rakomi.discover(ISSUER, http: http(configuration, { "keys" => [] })) }
  end

  def test_refuses_jwks_without_keys_array
    assert_refused(/no keys array/) { Rakomi.discover(ISSUER, http: http(configuration, { "keys" => "x" })) }
  end

  def test_results_are_frozen
    discovery = Rakomi.discover(ISSUER, http: http)
    assert_predicate discovery.configuration, :frozen?
    assert_predicate discovery.jwks, :frozen?
  end
end

class HTTPClientTest < Minitest::Test
  def test_refuses_non_https_before_connecting
    error = assert_raises(Rakomi::DiscoveryError) do
      Rakomi::HTTPClient.new.get(URI("http://api.rakomi.com/.well-known/openid-configuration"))
    end
    assert_match(/non-https/, error.message)
  end

  def test_wraps_timeouts
    client = Rakomi::HTTPClient.new
    raise_timeout = ->(*_args, **_kwargs) { raise Net::OpenTimeout }
    with_net_http_start(raise_timeout) do
      error = assert_raises(Rakomi::DiscoveryError) { client.get(URI("https://api.rakomi.com/x")) }
      assert_match(/timed out/, error.message)
    end
  end

  def test_passes_timeouts_and_peer_verification
    seen = nil
    capture = lambda do |_host, _port, **options|
      seen = options
      raise Net::ReadTimeout
    end
    with_net_http_start(capture) do
      assert_raises(Rakomi::DiscoveryError) do
        Rakomi::HTTPClient.new(open_timeout: 2, read_timeout: 3).get(URI("https://api.rakomi.com/x"))
      end
    end
    assert_equal true, seen[:use_ssl]
    assert_equal OpenSSL::SSL::VERIFY_PEER, seen[:verify_mode]
    assert_equal 2, seen[:open_timeout]
    assert_equal 3, seen[:read_timeout]
  end

  private

  def with_net_http_start(replacement)
    original = Net::HTTP.method(:start)
    Net::HTTP.singleton_class.send(:remove_method, :start)
    Net::HTTP.define_singleton_method(:start, &replacement)
    yield
  ensure
    Net::HTTP.singleton_class.send(:remove_method, :start)
    Net::HTTP.define_singleton_method(:start, original)
  end
end
