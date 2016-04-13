require 'httparty'
require 'pry'


class AuthController < ApplicationController

  def auth
    okta_session_token = get_okta_session_token
    open_id_token = authorize_client(okta_session_token)
    render json: { token: open_id_token }
  end

  private

  # First we need to get a session token from Okta, using its session API.
  # It is important that the provided user does not require multi-factor authentication,
  # or this request will fail. (it is possible, although harder, to authenticate MFA users)
  def get_okta_session_token
    url =  "#{APP_CONFIG['okta_base_url']}/api/v1/authn"
    body = { username: APP_CONFIG['okta_username'], password: APP_CONFIG['okta_password'] }.to_json
    result = HTTParty.post(url, body: body, headers: {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    })
    result['sessionToken']
  end

  # After retrieving a session token from Okta's API we then need to authorize it in order
  # to receive a JWT Open ID token
  def authorize_client session_token
    base_url = "#{APP_CONFIG['okta_base_url']}/oauth2/v1/authorize"
    redirect_uri = "#{APP_CONFIG['okta_openid_redirect_uri']}"
    client_id = "#{APP_CONFIG['okta_client_id']}"
    scopes = ["openid", "email", "groups"].join("%20")
    url = "#{base_url}?sessionToken=#{session_token}&redirect_uri=#{redirect_uri}&response_type=id_token&client_id=#{client_id}&scope=#{scopes}&response_mode=fragment"

    begin
      HttpClient.get(url)
    rescue HTTParty::RedirectionTooDeep => e
      open_id_token = e.response.header['location']
    end
    open_id_token.split('=').last
  end

end
