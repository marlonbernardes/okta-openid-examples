## Okta OpenID Examples

Here you will find some examples on how to use Okta's OpenID feature to secure your web applications.
Those examples were written using Ruby on Rails.

I strongly suggest that you also check the example Python implementation (and documentation) made by one of Okta's developers. Some parts of this documentation were extracted from there. You can check it [here](https://github.com/jpf/okta-oidc-beta).

### 1 Getting started

  - 1.1 Adding a new application to Okta & configuring OpenID
  - 1.2 Redirecting unauthenticated users to Okta
  - 1.3 Validating the ID Token (JWT)
  - 1.4 Obtaining user groups (permissions) from Okta

#### 1.1 Adding a new application to Okta & configuring OpenID

  - Log in to your Okta account as an administrator.
  - Click on applications and then on "Add Application"
  ![add application](https://cloud.githubusercontent.com/assets/2975955/14510101/1b94cb5e-01a6-11e6-8817-522285d7e5d3.png)
  - On the next screen, click on the big green button "Create new app"
  ![create new app button](https://cloud.githubusercontent.com/assets/2975955/14510123/316d44a6-01a6-11e6-8760-3c823f11ebef.png)
  - Select "Single Page App (SPA)" as the platform and make sure that Single on method is set to "OpenID Connect" (right now this is the only option available for Single Page Apps)
  ![setting the sign on method](https://cloud.githubusercontent.com/assets/2975955/14510136/4623ef30-01a6-11e6-92ee-240f702bee41.png)
  - Click on create.
  - Configure your application name/logo
  ![general settings](https://cloud.githubusercontent.com/assets/2975955/14510157/5c289970-01a6-11e6-8946-8920ca237bcb.png)
  - Configure one or more "Redirect URIs" for your application. This is a whitelist of endpoints that Okta trust and represents where Okta can send the ID Token after a successful authentication.  
  ![open id](https://cloud.githubusercontent.com/assets/2975955/14510523/540a3ada-01a8-11e6-9406-d70792a275e3.png)
  - Click on "Finish"
  - Using the "People" or "Groups" tabs, assign people to your newly created application. Note: Users will not be able to authenticate to your application if they are not assigned!
  - Take note of your "Client ID" in the "General" tab. You will need it later.

#### 1.2 Redirecting unauthenticated users to Okta

After adding an application to Okta, you will have to make sure that your application redirects unauthenticated users to Okta's authorize endpoint (`https://myorganization.okta.com/oauth2/v1/authorize?<params>`). During this redirection you will need to pass your Client ID and also tell Okta which URL it should redirect users to after a successful authentication, among other things. Remember that Okta will only redirect users to URLs configured as "Redirect URIs" on the previous step.

To see the full list of request parameters supported check Okta's OIDC Documentation here: http://developer.okta.com/docs/api/resources/oidc#oauth-20-endpoints

Rails example:
```ruby
# application_controller.rb
before_filter :authenticate

 def authenticate
   unless session[:auth]
     params = {
       # Remember the Redirect URI on step 1.1? Add one of those URLs here
       redirect_uri: APP_CONFIG['okta_openid_redirect_uri'],
       # Client ID obtained after adding a new application in Okta
       client_id: APP_CONFIG['okta_client_id'],
       response_type: 'id_token',
       # This tells Okta how it should notify your app after a successful
       # authentication. Check the documentation for all valid values.
       response_mode: 'form_post',
       # After a successful authentication, Okta will send back to your
       # app a JSON Web Token (JWT). The scope parameter below determines
       # what attributes should be contained in this token. OpenID is
       # required, email and groups are optional, but are really useful if
       # you want to obtain (in an easy way) the users's email and
       # permissions. Please note that if you want to obtain the users'
       # groups you also need to configure what groups Okta should send
       # back to your app. (see step 1.5)
       scope: 'openid email groups'
     }.to_query

     redirect_to "#{APP_CONFIG['okta_base_url']}/oauth2/v1/authorize?#{params}"
   end
 end

```

Python example: [click here](https://github.com/jpf/okta-oidc-beta/blob/master/app.py#L178-185)

#### 1.3 Validating the ID Token (JWT)

After a successful authentication Okta will generate an ID Token (which is a JSON Web Token - JWT). This token contains authentication information (e.g: user id, email (optional - depends on scope attribute), expiration date, groups (optional - depends on scope attribute and okta configuration), etc).

An ID token looks something like this:

```
eyJhbGciOiJSUzI1NiIsImtpZCI6Im1MaTFVZFhDa205MEtscTlaSnk1cDZyQVp4NV9YMkdRZ
WUyRV9MajNlVXMifQ.eyJzdWIiOiIwMGExYjMzY2RlNGZINWlqNjBrNyIsImVtYWlsIjoibXl
1c2VyQG15Y29tcGFueS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vbXljb21wYW55Lm9r
dGFwcmV2aWV3LmNvbSIsImF1ZCI6ImtkOGE3N0hMRG1hc1NUIiwiaWF0IjoxNDU5NDUwMjg0L
CJleHAiOjE0NTk0NTM4ODQsImp0aSI6ImpHYmJuVENid1dxc0dfT0s1M1RSIiwiYW1yIjpbIn
B3ZCJdLCJpZHAiOiIwMG8xZWlnOHlBQkNERUZHSElKS0wiLCJ1cGRhdGVkX2F0IjowLCJlbWF
pbF92ZXJpZmllZCI6dHJ1ZSwiYXV0aF90aW1lIjoxNDU5NDUwMjg0LCJncm91cHMiOlsiRXZl
cnlvbmUiLCJjdXN0b20tdXNlci1ncm91cCIsImFub3RoZXItdXNlci1ncm91cCJdfQ==.Zp8a
6o0nLEw_pEJEAgNgcT9CCvjizqBmGmvO-fjzEOmo1lqoUiBkRCZxTKW43vhInQ8pxa3Ms7G95
GwT_TjDZZuexPPsGRewMNZXJCiUm6bD7NEMzRqrWzsPhP6p-vcbPm4NCyXqu63CpLGODSeFtJ
An-khTOTcmQBKqNqZveoD0IgJWP_my4_PDjsFMRFHbeiccRfBHHdgAoTGvu1jWul7Bz25QCzh
6PMdXPpWJgbPZ1DUoXef2m_a71IGsjn_RLKB0u5UKmvlKPvAxf3U48w257pRF7Gx-g6za_E9A
gY703cd1MJjDFRL4DQPPo6yhLWWs7UCyG2o9SORJc4Qoig
```

This token is basically a base 64 encoded string, divided in 3 parts (separated by dots): the **header**, the **payload** and the **signature**. As an example, the token above contain the following contents:

**Header**
```js
{
  "alg": "RS256",
  "kid": "mLi1UdXCkm90Klq9ZJy5p6rAZx5_X2GQee2E_Lj3eUs"
}
```

**Payload**
```js
{
  "sub": "00a1b33cde4fH5ij60k7",
  "email": "myuser@mycompany.com",
  "ver": 1,
  "iss": "https://mycompany.oktapreview.com",
  "aud": "kd8a77HLDmasST",
  "iat": 1459450284,
  "exp": 1459453884,
  "jti": "jGbbnTCbwWqsG_OK53TR",
  "amr": [
    "pwd"
  ],
  "idp": "00o1eig8yABCDEFGHIJKL",
  "updated_at": 0,
  "email_verified": true,
  "auth_time": 1459450284,
  "groups": [
    "Everyone",
    "custom-user-group",
    "another-user-group"
  ]
}
```

After receiving an ID Token you need to decode it and validate it. Validating the token is **really** important, as you need to make sure that this token was not manipulated in any way by a malicious user.

There are several libraries for decoding and validating JWT. You can find a list of those libraries here: [https://jwt.io/](https://jwt.io/).

In short, the process of validating the token works like this:

  1. Decode the token 
  2. Extract the key id from the token's header ("kid" attribute)
  3. Obtain the public key associated with this key id.
  4. Use the public key to validate the contents of this id token (don't do this manually - use a library!)
  5. Optionally (**recommended!**) validate the issuer against a whitelist of allowed domains (e.g: validate if the "iss" domain is `okta.com` or `oktapreview.com`).
  
To obtain the public key:

  1. Open https://mycompany.oktapreview.com/.well-known/openid-configuration
  2. Find the URL present in the attribute `jwks_uri`
  3. Open this URL (e.g: https://mycompany.oktapreview.com/oauth2/v1/keys) and find the x5c certificate associated with the key id you want to validate
  
  
You can see how this is done in python here: [https://github.com/jpf/okta-oidc-beta/blob/master/app.py#L110-L147](https://github.com/jpf/okta-oidc-beta/blob/master/app.py#L110-L147)

Another example, in Ruby:

```ruby
 private
  def parse_jwt_token? token
    # decode the token without validating it (to extract the key id)
    dirty_token = JWT.decode token, nil, false
    dirty_header = dirty_token.last
    
    # Instead of accesing https://mycompany.oktapreview.com/.well-known/openid-configuration
    # and then https://mycompany.oktapreview.com/oauth2/v1/keys, I did this manually (using the browser) 
    # and added my X5C certificate to my configuration file. 
    
    # Decoding the x5c certificate data
    raw_certificate = Base64.decode64(APP_CONFIG['okta_public_keys'][dirty_header['kid']])
    
    # Using the certificate data to create a X5C certificate object
    certificate = OpenSSL::X509::Certificate.new raw_certificate
    
    # Validate the token using the public key from the certificate
    token = JWT.decode token, certificate.public_key, true, { algorithm: 'RS256' }
    token
  end
```

After validating the token, you can then create a session in your application for the user using the token information. 

An example in Python (again, extracted from https://github.com/jpf/okta-oidc-beta/blob/master/app.py#L219-L229)

```python
@app.route("/sso/oidc", methods=['GET', 'POST'])
def sso_oidc():
    if 'error' in request.form:
        flash(request.form['error_description'])
        return redirect(url_for('main_page', _external=True, _scheme='https'))
    id_token = request.form['id_token']
    decoded = parse_jwt(id_token)
    user_id = decoded['sub']
    user = UserSession(user_id)
    login_user(user)
    return redirect(url_for('logged_in', _external=True, _scheme='https'))
```

In ruby:

```ruby
 def create
    begin
      # you can find the implementation of parse_jwt_token above
      token = parse_jwt_token? params['id_token']
      # if the parse_jwt_token didn't throw an exception, we can safely create a session for the user
      session[:auth] = {
        email: token.first['email'],
        groups: token.first['groups']
      }
      redirect_to '/'
    rescue Exception => e
      redirect_to '/401'
    end
  end
```

(link to the source code: https://github.com/marlonbernardes/okta-openid-examples/blob/master/rails-app/app/controllers/sessions_controller.rb)


#### 1.4 Obtaining user groups (permissions) from Okta

First you need to specify that the id token should contain the user groups:

```ruby
 params = {
  # tell okta that you want to retrieve the users' groups 
  scope: 'openid email groups'
  # other params ommited for brevity
 }.to_query
 
 redirect_to "https://mycompany.oktapreview.com/oauth2/v1/authorize?#{params}"
```

Configure which groups Okta should return after a successful authentication. To do so:

  1. Log in to your Okta account as an administrator
  2. Find your application name in the "Applications" page and open it
  3. Open the "general" tab and then click on "Edit" in the "OAuth 2.0 Settings" pane.
  
  ![editing oauth 2.0 settings](https://cloud.githubusercontent.com/assets/2975955/14547869/41e8a310-0288-11e6-9513-b44428000767.png)

  4. Configure which groups should be returned. In the example below, I configured a regex that matches all groups (`.*`).
  
  ![configuring groups](https://cloud.githubusercontent.com/assets/2975955/14547836/09353b64-0288-11e6-89f0-401814f3ffa5.png)

  5. In order to test it, generate a new id token, decode it (tip: https://jwt.io) and verify that it contains the users' groups:
  
  ```js
    // other attributes ommited for brevity
    "groups": [
      "Everyone",
      "custom-user-group",
      "another-user-group"
    ]
  ````
 
 
### 2.1 Example 1: Using OpenID with browser based authentication

The source code for this demo is available inside the folder `rails-app`.


### 2.2 Example 2: Machine-to-machine authentication

This example shows how to authenticate with Okta without using a browser.
The source code for this demo is available inside the folder `rails-api`.

To authenticate without requiring human interaction:
  
  1. Use okta's authentication API ([documentation](http://developer.okta.com/docs/api/resources/authn.html)) to authenticate (**hint**: administrators can disable multi-factor authentication which will make things easier (less requests to authenticate))
  2. After a successful authentication, you will receive a response like this:
  
```js
{
  "expiresAt": "2015-11-03T10:15:57.000Z",
  "status": "SUCCESS",
  "relayState": "/myapp/some/deep/link/i/want/to/return/to",
  "sessionToken": "00Fpzf4en68pCXTsMjcX8JPMctzN2Wiw4LDOBL_9pe",
  "_embedded": {
    "user": {
      "id": "00ub0oNGTSWTBKOLGLNR",
      "passwordChanged": "2015-09-08T20:14:45.000Z",
      "profile": {
        "login": "dade.murphy@example.com",
        "firstName": "Dade",
        "lastName": "Murphy",
        "locale": "en_US",
        "timeZone": "America/Los_Angeles"
      }
    }
  }
}
```

  3. Exchange the sessionToken (see JSON above) for an id token using the `authorize` endpoint:
  
**Client**
```ruby
# See https://github.com/marlonbernardes/okta-openid-examples/blob/master/rails-api/client/app/controllers/auth_controller.rb
# pseudo code

session_token = authenticate_using_okta_authentication_api
params = {
   # Remember the Redirect URI on step 1.1? Add one of those URLs here
   redirect_uri: APP_CONFIG['okta_openid_redirect_uri'],
   # Client ID obtained after adding a new application in Okta
   client_id: APP_CONFIG['okta_client_id'],
   response_type: 'id_token',
   # IMPORTANT: since we might not have a browser (remember: we are talking about machine-to-machine authentication) 
   # then it makes no sense to user 'form_post' as response_mode. That's why we are telling Okta to send the token
   # as an URL fragment
   response_mode: 'fragment',
   scope: 'openid email groups',
   # when we include the sessionToken as a parameter, Okta will validate it and assume we already authenticated - 
   # thus it will generate an id token without showing the login form
   sessionToken: session_token
 }.to_query

 # performs a GET request passing the parameters above
 response = get "#{APP_CONFIG['okta_base_url']}/oauth2/v1/authorize?#{params}"
 
 # extract the id token from the URL fragment contained inside the location header
 id_token = extract_id_token_from_location_response_header(response)
 
 # the creators of mycoolapp's API decided that we can send an ID TOKEN as part of the Authorization header.
 # It's up to then to decode this token and validate it
 auth_headers = { "Authorization": "Bearer #{id_token}" }
 bla = get 'https://mycoolapp/api/foo/protected/endpoint/bla.json, { headers: auth_headers }

```

**Server**:

```ruby
 # See https://github.com/marlonbernardes/okta-openid-examples/blob/master/rails-api/api/app/controllers/api_controller.rb
 def authenticate
    if request.method != 'OPTIONS'
      header = request.headers['Authorization']
      token = header.gsub('Bearer ', '') if header
      begin
        result = validate_id_token? token
        session[:user_groups] = result.first['groups']
      rescue Exception => e
        render json: { message: e.message }, status: 401
      end
    end
  end

```

## References

  - [Example Python Implementation](https://github.com/jpf/okta-oidc-beta)
  - [Okta OIDC Documentation](http://developer.okta.com/docs/api/resources/oidc)
  - [Okta OAuth Documentation](http://developer.okta.com/docs/api/resources/oauth-clients)
  - [Okta Authentication API](http://developer.okta.com/docs/api/resources/authn.html)
