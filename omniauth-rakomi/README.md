# omniauth-rakomi

[OmniAuth](https://github.com/omniauth/omniauth) strategy for signing users in with
[Rakomi](https://rakomi.com). It is a thin subclass of
[`omniauth_openid_connect`](https://github.com/omniauth/omniauth_openid_connect) with Rakomi defaults:

| Option | Default |
|---|---|
| `name` | `rakomi` |
| `issuer` | `https://api.rakomi.com` |
| `discovery` | `true` (endpoints and keys come from the issuer's discovery document) |
| `response_type` | `code` |
| `pkce` | `true` |
| `scope` | `[:openid, :email, :profile]` |

Every other `omniauth_openid_connect` option works as documented there.

## Install

```ruby
# Gemfile
gem "omniauth-rakomi"
```

## Use

Create an OAuth client in the Rakomi dashboard with the redirect URI `https://<your app>/auth/rakomi/callback`.

```ruby
# config/initializers/omniauth.rb (Rails) or your Rack builder
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :rakomi,
           client_options: {
             identifier: ENV.fetch("RAKOMI_CLIENT_ID"),
             secret: ENV.fetch("RAKOMI_CLIENT_SECRET"),
             redirect_uri: "https://app.example.com/auth/rakomi/callback"
           }
end
```

OmniAuth 2 starts the flow only on a POST to `/auth/rakomi`; protect that request against CSRF (in Rails, with
`omniauth-rails_csrf_protection`). After the callback, `request.env["omniauth.auth"]` holds the user, with
`uid` set to the `sub` claim.

## License

MIT, see [LICENSE](LICENSE).
