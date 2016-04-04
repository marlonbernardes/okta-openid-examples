class ApplicationController < ActionController::Base

  before_filter :authenticate

  def authenticate
    unless session[:auth]
      params = {
        redirect_uri: APP_CONFIG['okta_openid_redirect_uri'],
        client_id: APP_CONFIG['okta_client_id'],
        response_type: 'id_token',
        response_mode: 'form_post',
        scope: 'openid email groups'
      }.to_query

      redirect_to "#{APP_CONFIG['okta_base_url']}/oauth2/v1/authorize?#{params}"
    end
  end

end
