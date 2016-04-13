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

After receiving an ID Token you need to decode it and validate it. Validating the token is **really** important, as you need to make sure that this token was not manipulated in any way by a malicious user.

There are several libraries for decoding and validating JWT. You can find a list of those libraries here: [https://jwt.io/](https://jwt.io/).


#### 1.4 Obtaining user groups (permissions) from Okta

TBD

### 2.1 Example 1: Using OpenID with browser based authentication

The source code for this demo is available inside the folder `rails-app`.


### 2.2 Example 2: Machine-to-machine authentication

This example shows how to authenticate with Okta without using a browser.

The source code for this demo is available inside the folder `rails-api`.


## References

  - [Example Python Implementation](https://github.com/jpf/okta-oidc-beta)
  - [Okta OIDC Documentation](http://developer.okta.com/docs/api/resources/oidc)
  - [Okta OAuth Documentation](http://developer.okta.com/docs/api/resources/oauth-clients)
  - [Okta Authentication API](http://developer.okta.com/docs/api/resources/authn.html)
