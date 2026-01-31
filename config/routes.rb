Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  resources :tasks

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
