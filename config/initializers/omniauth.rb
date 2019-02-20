# frozen_string_literal: true

require 'omniauth/strategies/api_token'

Rails.configuration.login_url          = '/auth/auth0'
Rails.configuration.login_callback_url = '/auth/auth0/callback'

auth0_provider_args = {
  client_id: ENV.fetch('AUTH0_CLIENT_ID', nil),
  client_secret: ENV.fetch('AUTH0_CLIENT_SECRET', nil),
  namespace: ENV.fetch('AUTH0_DOMAIN', 'fundingcircle.auth0.com'),
  connection: ENV.fetch('AUTH0_CONNECTION', 'Username-Password-Authentication'),
  request_path: Rails.configuration.login_url,
  callback_path: Rails.configuration.login_callback_url,
}

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?
  provider(:auth0, **auth0_provider_args)
  provider(:api_token, prefix: '/events')
  provider(:api_token, prefix: '/github_notifications')
end

DelayedJobWeb.use OmniAuth::Builder do
  provider(:auth0, **auth0_provider_args)
end
