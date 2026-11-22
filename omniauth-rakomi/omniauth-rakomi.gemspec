# frozen_string_literal: true

require_relative "lib/omniauth/rakomi/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-rakomi"
  spec.version = OmniAuth::Rakomi::VERSION
  spec.authors = ["CRE8EVE Sp. z o.o."]
  spec.email = ["security@rakomi.com"]
  spec.summary = "OmniAuth strategy for signing in with Rakomi over OpenID Connect."
  spec.description = "An OmniAuth strategy named :rakomi, built on omniauth_openid_connect, that signs users in " \
                     "with a Rakomi issuer using the authorization code flow, PKCE and OpenID Connect discovery."
  spec.homepage = "https://rakomi.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/rakomidev/rakomi-ruby/tree/main/omniauth-rakomi",
    "bug_tracker_uri" => "https://github.com/rakomidev/rakomi-ruby/issues",
    "changelog_uri" => "https://github.com/rakomidev/rakomi-ruby/blob/main/omniauth-rakomi/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb"] + %w[LICENSE README.md CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "omniauth_openid_connect", "~> 0.8"
end
