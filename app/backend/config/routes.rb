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
  get "api/tradesmen/compare" => "tradesmen#compare", as: :api_compare_tradesmen
  get "tradesman/:id/schedule" => "schedules#show", as: :tradesman_schedule
  post "tradesman/:id/schedule" => "schedules#create", as: :create_schedule
  post "tradesman/:id/schedule/bulk" => "schedules#bulk_create", as: :bulk_create_schedules
  put "schedules/:id" => "schedules#update", as: :update_schedule
  delete "schedules/:id" => "schedules#destroy", as: :delete_schedule
  post "appointments" => "appointments#create"
  put "appointments/:id/accept" => "appointments#accept", as: :accept_appointment
  put "appointments/:id/reject" => "appointments#reject", as: :reject_appointment
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
  get "projects-listing" => "projects#listing", as: :projects_listing
  get "projects/:id" => "projects#show", as: :project_details_page
  post "projects" => "projects#create", as: :create_project
  get "manage-profile" => "manage_profile#index", as: :manage_profile
  
  # API Routes for projects
  # IMPORTANT: More specific routes must come before parameterized routes
  get "api/projects/search" => "api/projects#search", as: :api_projects_search
  get "api/projects/user/:user_id" => "projects#user_projects", as: :api_user_projects
  get "api/projects/:id" => "projects#project_details", as: :api_project_details
  
  # Bids API
  post "api/projects/:project_id/bids" => "api/bids#create", as: :api_create_bid
  get "api/projects/:project_id/bids" => "api/bids#index", as: :api_project_bids
  get "api/tradesmen/:tradesman_id/bids" => "api/bids#index", as: :api_tradesman_bids
  get "api/bids/:id" => "api/bids#show", as: :api_bid
  put "api/bids/:id" => "api/bids#update", as: :api_update_bid
  post "api/projects/:project_id/bids/:bid_id/accept" => "api/bids#accept", as: :api_accept_bid
  post "api/projects/:project_id/bids/:bid_id/reject" => "api/bids#reject", as: :api_reject_bid
  
  # Estimates API
  post "api/appointments/:appointment_id/estimates" => "api/estimates#create", as: :api_create_appointment_estimate
  post "api/projects/:project_id/estimates" => "api/estimates#create", as: :api_create_project_estimate
  get "api/estimates" => "api/estimates#index", as: :api_estimates
  get "api/estimates/:id" => "api/estimates#show", as: :api_estimate
  get "api/estimates/:id/history" => "api/estimates#history", as: :api_estimate_history
  put "api/estimates/:id" => "api/estimates#update", as: :api_update_estimate
  post "api/estimates/:id/accept" => "api/estimates#accept", as: :api_accept_estimate
  post "api/estimates/:id/reject" => "api/estimates#reject", as: :api_reject_estimate
  
  # Notifications API
  get "api/notifications" => "api/notifications#index", as: :api_notifications
  get "api/notifications/:id" => "api/notifications#show", as: :api_notification
  put "api/notifications/:id/read" => "api/notifications#mark_read", as: :mark_notification_read
  put "api/notifications/mark-all-read" => "api/notifications#mark_all_read", as: :mark_all_notifications_read
  get "api/notifications/unread-count" => "api/notifications#unread_count", as: :api_notifications_unread_count
  
  # Admin API
  get "api/admin/dashboard" => "api/admin#dashboard", as: :api_admin_dashboard
  get "api/admin/users" => "api/admin/users#index", as: :api_admin_users
  get "api/admin/users/search" => "api/admin/users#search", as: :api_admin_users_search
  get "api/admin/users/:id" => "api/admin/users#show", as: :api_admin_user
  put "api/admin/users/:id/suspend" => "api/admin/users#suspend", as: :api_admin_suspend_user
  put "api/admin/users/:id/activate" => "api/admin/users#activate", as: :api_admin_activate_user
  get "api/admin/tradesman-verifications" => "api/admin/tradesman_verifications#index", as: :api_admin_tradesman_verifications
  get "api/admin/tradesman-verifications/:id" => "api/admin/tradesman_verifications#show", as: :api_admin_tradesman_verification
  post "api/admin/tradesman-verifications/:id/approve" => "api/admin/tradesman_verifications#approve", as: :api_admin_approve_verification
  post "api/admin/tradesman-verifications/:id/reject" => "api/admin/tradesman_verifications#reject", as: :api_admin_reject_verification
  
  # 2FA Setup
  post "auth/setup-2fa" => "auth#setup_2fa", as: :setup_2fa
  post "auth/verify-2fa" => "auth#verify_2fa", as: :verify_2fa
  
  # Tradesman Profile Updates
  put "api/tradesman/profile" => "api/tradesman_profiles#update", as: :update_tradesman_profile
  
  # Project Management
  put "api/projects/:id" => "projects#update", as: :api_update_project
  post "api/projects/:id/publish" => "projects#publish", as: :api_publish_project
  
  # Contractor Dashboard
  get "api/contractors/:id/dashboard" => "api/contractors#dashboard", as: :api_contractor_dashboard
  
  # Account Deletion
  delete "api/accounts/:id" => "api/accounts#destroy", as: :api_delete_account
  
  # Defines the root path route ("/")
  root "home#index"
end
