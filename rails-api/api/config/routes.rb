Rails.application.routes.draw do
  root 'welcome#index'
  match '/api/*', via: [:options], to:  lambda {|_| [204, {'Content-Type' => 'text/plain'}, []]}
  get '/api/events', to: 'events_api#index'
  post '/api/events', to: 'events_api#create'
end
