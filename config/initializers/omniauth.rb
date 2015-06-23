require 'omniauth/strategies/event_token'

Rails.configuration.login_url          = '/auth/auth0'
Rails.configuration.login_callback_url = '/auth/auth0/callback'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    client_id:     ENV.fetch('AUTH0_CLIENT_ID', nil),
    client_secret: ENV.fetch('AUTH0_CLIENT_SECRET', nil),
    namespace:     ENV.fetch('AUTH0_DOMAIN', 'fundingcircle.auth0.com'),
    connection:    ENV.fetch('AUTH0_CONNECTION', 'Username-Password-Authentication'),
    request_path:  Rails.configuration.login_url,
    callback_path: Rails.configuration.login_callback_url,
  )
  provider(:event_token, event_prefix: '/events')
end
