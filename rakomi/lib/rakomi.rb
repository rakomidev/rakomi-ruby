# frozen_string_literal: true

require_relative "rakomi/version"

# Ruby client for Rakomi.
module Rakomi
  DEFAULT_ISSUER = "https://api.rakomi.com"

  class Error < StandardError; end

  class DiscoveryError < Error; end

  # Fetches <issuer>/.well-known/openid-configuration and the JWKS at its jwks_uri.
  #
  # Both URLs must be https. The document must name exactly the issuer given here and carry the
  # fields OpenID Connect Discovery 1.0 requires. Raises Rakomi::DiscoveryError otherwise.
  #
  #   discovery = Rakomi.discover
  #   discovery.token_endpoint # => "https://api.rakomi.com/oauth/token"
  #   discovery.keys           # => [{ "kty" => "RSA", "kid" => "...", ... }]
  def self.discover(issuer = DEFAULT_ISSUER, open_timeout: HTTPClient::DEFAULT_TIMEOUT,
                    read_timeout: HTTPClient::DEFAULT_TIMEOUT, http: nil)
    http ||= HTTPClient.new(open_timeout: open_timeout, read_timeout: read_timeout)
    Discoverer.call(issuer, http: http)
  end
end

require_relative "rakomi/http_client"
require_relative "rakomi/discovery"
