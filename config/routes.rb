Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  resources :tasks
  resources :wishlist_items

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
