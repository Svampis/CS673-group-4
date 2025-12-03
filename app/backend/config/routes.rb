Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # User & Authentication APIs
  post "register" => "auth#register"
  post "login" => "auth#login"
  get "profile/:user_id" => "profiles#show", as: :user_profile
  put "profile/:user_id" => "profiles#update", as: :update_user_profile

  # API Routes
  
  # Tradesman Availability & Scheduling
  get "tradesmen" => "tradesmen#index"
  get "tradesmen/:id" => "tradesmen#show", as: :tradesman_api
  get "tradesman/:id/schedule" => "schedules#show", as: :tradesman_schedule
  post "appointments" => "appointments#create"
  put "appointments/:id/cancel" => "appointments#cancel", as: :cancel_appointment
  
  # Messaging
  get "messages-page" => "messages#index_page", as: :messages_page
  get "messages" => "messages#index", as: :messages_list
  get "messages/:conversation_id" => "messages#show", as: :messages
  post "messages" => "messages#create"
  put "messages/:id/read" => "messages#mark_read", as: :mark_message_read
  get "messages/unread-counts" => "messages#unread_counts", as: :unread_counts
  
  # Reviews
  post "reviews" => "reviews#create"
  get "reviews/:tradesman_id" => "reviews#show", as: :tradesman_reviews
  
  # Tradesman Profile API
  post "tradesman/profile" => "api/tradesman_profiles#create", as: :create_tradesman_profile
  
  # Frontend pages
  get "tradesmen-listing" => "tradesmen_listing#index", as: :tradesmen_listing
  get "tradesman/:id/profile" => "tradesman_profiles#show", as: :tradesman_profile
  get "start-project" => "projects#new", as: :new_project
  get "my-projects" => "projects#index", as: :my_projects
  get "projects/:id" => "projects#show", as: :project_details_page
  post "projects" => "projects#create", as: :create_project
  get "manage-profile" => "manage_profile#index", as: :manage_profile
  
  # API Routes for projects
  get "api/projects/user/:user_id" => "projects#user_projects", as: :api_user_projects
  get "api/projects/:id" => "projects#project_details", as: :api_project_details
  
  # Defines the root path route ("/")
  root "home#index"
end
