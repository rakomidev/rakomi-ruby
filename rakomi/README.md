# rakomi

Ruby client for [Rakomi](https://rakomi.com). Version 0.1.0 does one thing: OpenID Connect discovery of a
Rakomi issuer. It uses only the Ruby standard library (`net/http`, `json`).

## Install

```sh
gem install rakomi
```

## Use

```ruby
require "rakomi"

discovery = Rakomi.discover # issuer https://api.rakomi.com
discovery.issuer                 # => "https://api.rakomi.com"
discovery.authorization_endpoint
discovery.token_endpoint
discovery.userinfo_endpoint
discovery.jwks_uri
discovery.keys                   # the keys of the issuer's JWKS, as hashes
discovery.configuration          # the whole discovery document
```

`Rakomi.discover(issuer = "https://api.rakomi.com", open_timeout: 5, read_timeout: 5)` fetches
`<issuer>/.well-known/openid-configuration` and then the JWKS at its `jwks_uri`. It raises
`Rakomi::DiscoveryError` when:

- the issuer, `jwks_uri` or an endpoint URL is not `https`;
- a response is not HTTP 200 (redirects are not followed), is not a JSON object, or is larger than 1 MiB;
- the document names an issuer other than exactly the one passed in (a trailing slash counts);
- the document lacks `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`,
  `response_types_supported`, `subject_types_supported` or `id_token_signing_alg_values_supported`;
- the JWKS has no keys;
- a connection or read times out.

TLS certificates are verified. This gem does not verify tokens; for signing users in to a Rack or Rails
app, see [`omniauth-rakomi`](../omniauth-rakomi/).

## License

MIT, see [LICENSE](LICENSE).
