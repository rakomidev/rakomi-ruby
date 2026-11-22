# frozen_string_literal: true

require "json"
require "uri"

module Rakomi
  # The OpenID Provider metadata of an issuer and the JSON Web Key Set it publishes.
  Discovery = Struct.new(:configuration, :jwks, keyword_init: true) do
    def issuer
      configuration.fetch("issuer")
    end

    def authorization_endpoint
      configuration.fetch("authorization_endpoint")
    end

    def token_endpoint
      configuration.fetch("token_endpoint")
    end

    def userinfo_endpoint
      configuration["userinfo_endpoint"]
    end

    def jwks_uri
      configuration.fetch("jwks_uri")
    end

    def keys
      jwks.fetch("keys")
    end
  end

  # Fetches and checks OpenID Connect Discovery 1.0 metadata.
  module Discoverer
    WELL_KNOWN_PATH = "/.well-known/openid-configuration"

    REQUIRED_FIELDS = %w[
      issuer
      authorization_endpoint
      token_endpoint
      jwks_uri
      response_types_supported
      subject_types_supported
      id_token_signing_alg_values_supported
    ].freeze

    URL_FIELDS = %w[
      authorization_endpoint
      token_endpoint
      userinfo_endpoint
      jwks_uri
      registration_endpoint
      end_session_endpoint
      revocation_endpoint
      introspection_endpoint
    ].freeze

    module_function

    def call(issuer, http:)
      issuer_uri = parse_https(issuer, "issuer")
      raise DiscoveryError, "issuer must not carry a query or fragment" if issuer_uri.query || issuer_uri.fragment

      configuration = fetch_json(http, configuration_uri(issuer_uri), "openid-configuration")
      check_configuration(configuration, issuer)

      jwks = fetch_json(http, parse_https(configuration["jwks_uri"], "jwks_uri"), "jwks")
      check_jwks(jwks)

      Discovery.new(configuration: configuration.freeze, jwks: jwks.freeze)
    end

    def configuration_uri(issuer_uri)
      uri = issuer_uri.dup
      uri.path = uri.path.sub(%r{/\z}, "") + WELL_KNOWN_PATH
      uri
    end

    def parse_https(value, name)
      raise DiscoveryError, "#{name} must be a string" unless value.is_a?(String)

      uri = URI.parse(value)
      unless uri.is_a?(URI::HTTPS) && uri.host && !uri.host.empty?
        raise DiscoveryError, "#{name} must be an https URL: #{value.inspect}"
      end
      raise DiscoveryError, "#{name} must not carry user information" if uri.userinfo

      uri
    rescue URI::InvalidURIError
      raise DiscoveryError, "#{name} is not a valid URL: #{value.inspect}"
    end

    def fetch_json(http, uri, what)
      status, body = http.get(uri)
      raise DiscoveryError, "#{what} at #{uri} answered HTTP #{status}" unless status == 200

      document = JSON.parse(body)
      raise DiscoveryError, "#{what} at #{uri} is not a JSON object" unless document.is_a?(Hash)

      document
    rescue JSON::ParserError
      raise DiscoveryError, "#{what} at #{uri} is not valid JSON"
    end

    def check_configuration(configuration, issuer)
      missing = REQUIRED_FIELDS.reject { |field| configuration.key?(field) }
      raise DiscoveryError, "openid-configuration lacks #{missing.join(", ")}" unless missing.empty?

      unless configuration["issuer"] == issuer
        raise DiscoveryError,
              "openid-configuration names issuer #{configuration["issuer"].inspect}, expected #{issuer.inspect}"
      end

      URL_FIELDS.each do |field|
        parse_https(configuration[field], field) if configuration.key?(field)
      end
    end

    def check_jwks(jwks)
      keys = jwks["keys"]
      raise DiscoveryError, "jwks has no keys array" unless keys.is_a?(Array)
      raise DiscoveryError, "jwks has no keys" if keys.empty?
      raise DiscoveryError, "jwks holds an entry that is not an object" unless keys.all?(Hash)
    end
  end
end
