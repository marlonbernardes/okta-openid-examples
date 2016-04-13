Rails.application.routes.draw do
  root 'welcome#index'
  get '/auth', to: 'auth#auth'
end
