# rakomi-ruby

Ruby libraries for [Rakomi](https://rakomi.com).

| Gem | What it does |
|---|---|
| [`rakomi`](rakomi/) | Fetches and checks the OpenID Connect discovery document and JWKS of a Rakomi issuer. Standard library only. |
| [`omniauth-rakomi`](omniauth-rakomi/) | OmniAuth strategy `:rakomi`, built on `omniauth_openid_connect`. |

Both need Ruby 3.1 or newer.

## Development

```sh
cd rakomi && bundle install && bundle exec rake test
cd omniauth-rakomi && bundle install && bundle exec rake test
```

The tests stub HTTP and make no network calls.

## Security

See [SECURITY.md](SECURITY.md).

## License

MIT, see [LICENSE](LICENSE).
