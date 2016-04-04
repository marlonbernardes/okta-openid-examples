Rails.application.routes.draw do
  root 'welcome#index'
  post '/oauth/callback', to: 'sessions#create'
  post '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/show', to: 'sessions#show'
end
