require 'jwt'

class SessionsController < ApplicationController

  skip_before_filter :authenticate

  def create
    begin
      token = parse_jwt_token? params['id_token']
      session[:auth] = {
        email: token.first['email'],
        groups: token.first['groups']
      }
      redirect_to '/'
    rescue Exception => e
      redirect_to '/401'
    end
  end

  def destroy
    reset_session
    redirect_to "#{APP_CONFIG['okta_base_url']}/login/signout"
  end

  def show
    render json: session[:auth]
  end

  private
  def parse_jwt_token? token
    dirty_token = JWT.decode token, nil, false
    dirty_header = dirty_token.last
    raw_certificate = Base64.decode64(APP_CONFIG['okta_public_keys'][dirty_header['kid']])
    certificate = OpenSSL::X509::Certificate.new raw_certificate
    token = JWT.decode token, certificate.public_key, true, { algorithm: 'RS256' }
    token
  end
end
