class ApiController < ActionController::Base

  before_filter :authenticate

  def authenticate
    if request.method != 'OPTIONS'
      header = request.headers['Authorization']
      token = header.gsub('Bearer ', '') if header
      begin
        result = parse_openid_token? token
      rescue Exception => e
        render json: { message: e.message }, status: 401
      end
    end
  end

  private

  def parse_openid_token? token
    dirty_token = JWT.decode token, nil, false
    dirty_header = dirty_token.last
    raw_certificate = Base64.decode64(APP_CONFIG['okta_public_keys'][dirty_header['kid']])
    certificate = OpenSSL::X509::Certificate.new raw_certificate
    token = JWT.decode token, certificate.public_key, true, { algorithm: 'RS256' }
    token
  end

end
