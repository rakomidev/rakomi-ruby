# frozen_string_literal: true

require_relative "lib/rakomi/version"

Gem::Specification.new do |spec|
  spec.name = "rakomi"
  spec.version = Rakomi::VERSION
  spec.authors = ["CRE8EVE Sp. z o.o."]
  spec.email = ["security@rakomi.com"]
  spec.summary = "Ruby client for Rakomi: OpenID Connect discovery of a Rakomi issuer."
  spec.description = "Fetches and checks the OpenID Connect discovery document and the JSON Web Key Set " \
                     "of a Rakomi issuer over HTTPS, using only the Ruby standard library."
  spec.homepage = "https://rakomi.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/rakomidev/rakomi-ruby/tree/main/rakomi",
    "bug_tracker_uri" => "https://github.com/rakomidev/rakomi-ruby/issues",
    "changelog_uri" => "https://github.com/rakomidev/rakomi-ruby/blob/main/rakomi/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb"] + %w[LICENSE README.md CHANGELOG.md]
  spec.require_paths = ["lib"]
end
