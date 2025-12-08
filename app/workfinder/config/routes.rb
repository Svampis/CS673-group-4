Rails.application.routes.draw do
  get "registrations/new"
  get "registrations/create"
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  get "/users", to: "users#index"
  get "/users/:id", to: "users#show"

  get "/signup", to: "registrations#new", as: "signup"
  post "/signup", to: "registrations#create"

  get "/messages/", to: "messages#index"
  get "/messages/:id", to: "messages#show", as: :message
  post "/messages", to: "messages#create"

  get "/appointments/", to: "appointments#index"
  post "/appointments/", to: "appointments#create"

  resources :appointments do
    member do
      patch :schedule
      patch :cancel
    end
  end
  root "users#index"
  resources :users
  resources :messages
end
