# frozen_string_literal: true

require "omniauth_openid_connect"

module OmniAuth
  module Strategies
    # Signs users in with a Rakomi issuer: authorization code flow with PKCE, endpoints and keys taken from
    # the issuer's OpenID Connect discovery document. Every option of omniauth_openid_connect still applies.
    class Rakomi < OmniAuth::Strategies::OpenIDConnect
      DEFAULT_ISSUER = "https://api.rakomi.com"

      option :name, "rakomi"
      option :issuer, DEFAULT_ISSUER
      option :discovery, true
      option :response_type, "code"
      option :pkce, true
      option :scope, %i[openid email profile]
      option :client_options, {
        identifier: nil,
        secret: nil,
        redirect_uri: nil,
        scheme: "https",
        host: URI(DEFAULT_ISSUER).host,
        port: 443,
        authorization_endpoint: nil,
        token_endpoint: nil,
        userinfo_endpoint: nil,
        jwks_uri: nil,
        end_session_endpoint: nil
      }
    end
  end
end
