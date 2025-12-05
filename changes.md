diff --git a/app/backend/Gemfile b/app/backend/Gemfile
index 0de1477..2c9efd4 100644
--- a/app/backend/Gemfile
+++ b/app/backend/Gemfile
@@ -4,8 +4,10 @@ source "https://rubygems.org"
 gem "rails", "~> 8.1.1"
 # The modern asset pipeline for Rails [https://github.com/rails/propshaft]
 gem "propshaft"
-# Using JSON file storage instead of database
+# Database
 gem "sqlite3", ">= 2.1"
+# Environment variable management
+gem "dotenv-rails", groups: [:development, :production]
 # Use the Puma web server [https://github.com/puma/puma]
 gem "puma", ">= 5.0"
 # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
@@ -20,6 +22,10 @@ gem "jbuilder"
 # Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
 # gem "bcrypt", "~> 3.1.7"
 
+# Two-factor authentication
+gem "rotp", "~> 6.2"
+gem "rqrcode", "~> 2.2"
+
 # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
 gem "tzinfo-data", platforms: %i[ windows jruby ]
 
diff --git a/app/backend/Gemfile.lock b/app/backend/Gemfile.lock
index 4348606..855efa3 100644
--- a/app/backend/Gemfile.lock
+++ b/app/backend/Gemfile.lock
@@ -101,6 +101,7 @@ GEM
       rack-test (>= 0.6.3)
       regexp_parser (>= 1.5, < 3.0)
       xpath (~> 3.2)
+    chunky_png (1.4.0)
     concurrent-ruby (1.3.5)
     connection_pool (2.5.4)
     crass (1.0.6)
@@ -108,7 +109,10 @@ GEM
     debug (1.11.0)
       irb (~> 1.10)
       reline (>= 0.3.8)
-    dotenv (3.1.8)
+    dotenv (3.2.0)
+    dotenv-rails (3.2.0)
+      dotenv (= 3.2.0)
+      railties (>= 6.1)
     drb (2.2.3)
     ed25519 (1.4.0)
     erb (6.0.0)
@@ -276,6 +280,11 @@ GEM
     reline (0.6.3)
       io-console (~> 0.5)
     rexml (3.4.4)
+    rotp (6.3.0)
+    rqrcode (2.2.0)
+      chunky_png (~> 1.0)
+      rqrcode_core (~> 1.0)
+    rqrcode_core (1.2.0)
     rubocop (1.81.7)
       json (~> 2.3)
       language_server-protocol (~> 3.17.0.2)
@@ -400,6 +409,7 @@ DEPENDENCIES
   bundler-audit
   capybara
   debug
+  dotenv-rails
   image_processing (~> 1.2)
   importmap-rails
   jbuilder
@@ -407,6 +417,8 @@ DEPENDENCIES
   propshaft
   puma (>= 5.0)
   rails (~> 8.1.1)
+  rotp (~> 6.2)
+  rqrcode (~> 2.2)
   rubocop-rails-omakase
   selenium-webdriver
   solid_cable
diff --git a/app/backend/app/controllers/api/tradesman_profiles_controller.rb b/app/backend/app/controllers/api/tradesman_profiles_controller.rb
index a929f52..cb72254 100644
--- a/app/backend/app/controllers/api/tradesman_profiles_controller.rb
+++ b/app/backend/app/controllers/api/tradesman_profiles_controller.rb
@@ -1,27 +1,66 @@
 class Api::TradesmanProfilesController < ApiController
   def create
-    profile_params = params.permit(:user_id, :name, :email, :trade, :license_number, :business_name, :experience, :location, :address).to_h.symbolize_keys
-    tradesman = Tradesman.find_by_id(profile_params[:user_id])
+    profile_params = params.permit(:user_id, :trade_specialty, :license_number, :business_name, 
+                                    :years_of_experience, :service_radius, :hourly_rate,
+                                    :street, :city, :state, :number, :description).to_h.symbolize_keys
     
-    if tradesman.nil?
-      # Create new tradesman if doesn't exist
-      tradesman = Tradesman.new(profile_params)
+    user_id = profile_params[:user_id]
+    return render_error("user_id is required", :bad_request) unless user_id
+    
+    user = User.find_by(id: user_id)
+    return render_error("User not found", :not_found) unless user
+    return render_error("User is not a tradesman", :forbidden) unless user.role == 'tradesman'
+    
+    tradesman = user.tradesman || Tradesman.new(user: user)
+    
+    # Update tradesman profile
+    tradesman.trade_specialty = profile_params[:trade_specialty] if profile_params[:trade_specialty].present?
+    tradesman.license_number = profile_params[:license_number] if profile_params[:license_number].present?
+    tradesman.business_name = profile_params[:business_name] if profile_params[:business_name].present?
+    tradesman.years_of_experience = profile_params[:years_of_experience] if profile_params[:years_of_experience].present?
+    tradesman.service_radius = profile_params[:service_radius] if profile_params[:service_radius].present?
+    tradesman.hourly_rate = profile_params[:hourly_rate] if profile_params[:hourly_rate].present?
+    tradesman.street = profile_params[:street] if profile_params[:street].present?
+    tradesman.city = profile_params[:city] if profile_params[:city].present?
+    tradesman.state = profile_params[:state] if profile_params[:state].present?
+    tradesman.number = profile_params[:number] if profile_params[:number].present?
+    tradesman.description = profile_params[:description] if profile_params[:description].present?
+    
+    if tradesman.save
+      render json: {
+        message: "Tradesman profile saved successfully",
+        tradesman_id: tradesman.id,
+        service_radius: tradesman.service_radius,
+        hourly_rate: tradesman.hourly_rate
+      }, status: :created
     else
-      # Update existing tradesman
-      tradesman.name = profile_params[:name] if profile_params[:name]
-      tradesman.email = profile_params[:email] if profile_params[:email]
-      tradesman.trade = profile_params[:trade] if profile_params[:trade]
-      tradesman.license_number = profile_params[:license_number] if profile_params[:license_number]
-      tradesman.business_name = profile_params[:business_name] if profile_params[:business_name]
-      tradesman.experience = profile_params[:experience] if profile_params[:experience]
-      tradesman.location = profile_params[:location] if profile_params[:location]
-      tradesman.address = profile_params[:address] if profile_params[:address]
+      render_error("Failed to save tradesman profile: #{tradesman.errors.full_messages.join(', ')}")
     end
+  end
+  
+  def update
+    user_id = params[:user_id]
+    return render_error("user_id is required", :bad_request) unless user_id
     
-    if tradesman.save
-      render json: { message: "Tradesman profile saved successfully" }, status: :created
+    user = User.find_by(id: user_id)
+    return render_error("User not found", :not_found) unless user
+    
+    tradesman = user.tradesman
+    return render_error("Tradesman profile not found", :not_found) unless tradesman
+    
+    profile_params = params.permit(:trade_specialty, :license_number, :business_name,
+                                    :years_of_experience, :service_radius, :hourly_rate,
+                                    :street, :city, :state, :number, :description).to_h.symbolize_keys
+    
+    if tradesman.update(profile_params)
+      render json: {
+        message: "Tradesman profile updated successfully",
+        tradesman_id: tradesman.id,
+        service_radius: tradesman.service_radius,
+        hourly_rate: tradesman.hourly_rate
+      }
     else
-      render_error("Failed to save tradesman profile")
+      render_error("Failed to update tradesman profile: #{tradesman.errors.full_messages.join(', ')}")
     end
   end
 end
diff --git a/app/backend/app/controllers/appointments_controller.rb b/app/backend/app/controllers/appointments_controller.rb
index d404fdc..49896dc 100644
--- a/app/backend/app/controllers/appointments_controller.rb
+++ b/app/backend/app/controllers/appointments_controller.rb
@@ -4,8 +4,11 @@ class AppointmentsController < ApiController
     appointment = Appointment.new(appointment_params.merge(status: 'pending'))
     
     if appointment.save
+      # Notify tradesman of new appointment request
+      NotificationService.notify_appointment_created(appointment)
+      
       render json: {
-        appointment_id: appointment.appointment_id,
+        appointment_id: appointment.id,
         status: appointment.status
       }, status: :created
     else
@@ -13,15 +16,90 @@ class AppointmentsController < ApiController
     end
   end
   
+  def accept
+    appointment = Appointment.find_by(id: params[:id])
+    
+    if appointment.nil?
+      render_error("Appointment not found", :not_found)
+    elsif appointment.status != 'pending'
+      render_error("Appointment is not pending", :unprocessable_entity)
+    else
+      reason = params[:reason]
+      appointment.accept(reason)
+      
+      # Notify homeowner
+      NotificationService.notify_appointment_accepted(appointment)
+      
+      # Schedule auto-confirmation job (5 minutes after acceptance)
+      AppointmentConfirmationJob.set(wait: 5.minutes).perform_later(appointment.id)
+      
+      render json: {
+        message: "Appointment accepted",
+        appointment_id: appointment.id,
+        status: appointment.status,
+        accepted_at: appointment.accepted_at
+      }
+    end
+  end
+  
+  def reject
+    appointment = Appointment.find_by(id: params[:id])
+    
+    if appointment.nil?
+      render_error("Appointment not found", :not_found)
+    elsif appointment.status != 'pending'
+      render_error("Appointment is not pending", :unprocessable_entity)
+    else
+      reason = params[:reason]
+      appointment.reject(reason)
+      
+      # Notify homeowner
+      NotificationService.notify_appointment_rejected(appointment, reason)
+      
+      # Reopen schedule slot if needed
+      reopen_schedule_slot(appointment)
+      
+      render json: {
+        message: "Appointment rejected",
+        appointment_id: appointment.id,
+        status: appointment.status,
+        rejected_at: appointment.rejected_at,
+        rejection_reason: appointment.rejection_reason
+      }
+    end
+  end
+  
   def cancel
-    appointment = Appointment.find_by_id(params[:id])
+    appointment = Appointment.find_by(id: params[:id])
     
     if appointment.nil?
       render_error("Appointment not found", :not_found)
     else
+      cancelled_by_user_id = params[:user_id] || appointment.homeowner.user.id
       appointment.cancel
+      
+      # Notify the other party
+      NotificationService.notify_appointment_cancelled(appointment, cancelled_by_user_id)
+      
+      # Reopen schedule slot
+      reopen_schedule_slot(appointment)
+      
       render json: { message: "Appointment canceled" }
     end
   end
+  
+  private
+  
+  def reopen_schedule_slot(appointment)
+    # Find and update the schedule slot to available
+    schedule = Schedule.where(
+      tradesman_id: appointment.tradesman_id,
+      date: appointment.scheduled_start.to_date,
+      start_time: appointment.scheduled_start.strftime('%H:%M:%S'),
+      end_time: appointment.scheduled_end.strftime('%H:%M:%S')
+    ).first
+    
+    schedule&.update(status: 'available')
+  end
 end
 
diff --git a/app/backend/app/controllers/auth_controller.rb b/app/backend/app/controllers/auth_controller.rb
index 65ee857..d92f7dc 100644
--- a/app/backend/app/controllers/auth_controller.rb
+++ b/app/backend/app/controllers/auth_controller.rb
@@ -1,6 +1,9 @@
 class AuthController < ApiController
   def register
-    user_params = params.permit(:name, :email, :password, :role, :address).to_h.symbolize_keys
+    user_params = params.permit(:name, :email, :password, :role, :address,
+                                 :street, :city, :state, :number,
+                                 :trade_specialty, :license_number, :business_name,
+                                 :years_of_experience, :hourly_rate, :service_radius).to_h.symbolize_keys
     
     # Validate required fields
     if user_params[:name].blank? || user_params[:email].blank? || user_params[:password].blank? || user_params[:role].blank?
@@ -13,31 +16,94 @@ class AuthController < ApiController
       return render_error("User with this email already exists", :conflict)
     end
     
-    # Create new user
-    user = User.new(
-      name: user_params[:name],
-      email: user_params[:email],
-      password_hash: user_params[:password], # In production, hash this with bcrypt
-      role: user_params[:role],
-      address: user_params[:address],
-      status: 'active'
-    )
-    
-    if user.save
+    # Normalize role
+    role = user_params[:role].downcase
+    role = 'homeowner' if role == 'homeowner'
+    role = 'tradesman' if ['tradesman', 'plumber', 'electrician', 'hvac worker'].include?(role)
+    role = 'contractor' if role == 'contractor'
+    role = 'admin' if role == 'admin'
+    
+    # Parse name into fname and lname
+    name_parts = parse_name(user_params[:name])
+    
+    # Create new user and profile in a transaction
+    ActiveRecord::Base.transaction do
+      user = User.create!(
+        email: user_params[:email],
+        password_hash: user_params[:password], # In production, hash this with bcrypt
+        role: role,
+        status: 'activated'
+      )
+      
+      # Create role-specific profile
+      case role
+      when 'homeowner'
+        Homeowner.create!(
+          user: user,
+          fname: name_parts[:fname],
+          lname: name_parts[:lname],
+          street: user_params[:street],
+          city: user_params[:city],
+          state: user_params[:state],
+          number: user_params[:number]
+        )
+      when 'contractor'
+        Contractor.create!(
+          user: user,
+          fname: name_parts[:fname],
+          lname: name_parts[:lname],
+          street: user_params[:street],
+          city: user_params[:city],
+          state: user_params[:state],
+          number: user_params[:number]
+        )
+      when 'tradesman'
+        tradesman = Tradesman.create!(
+          user: user,
+          fname: name_parts[:fname],
+          lname: name_parts[:lname],
+          trade_specialty: user_params[:trade_specialty],
+          license_number: user_params[:license_number],
+          business_name: user_params[:business_name],
+          years_of_experience: user_params[:years_of_experience]&.to_i,
+          street: user_params[:street],
+          city: user_params[:city],
+          state: user_params[:state],
+          number: user_params[:number],
+          hourly_rate: user_params[:hourly_rate]&.to_f || 50.0,
+          service_radius: user_params[:service_radius]&.to_f || 25.0,
+          verification_status: 'pending'
+        )
+        
+        # Auto-create tradesman verification record
+        TradesmanVerification.create!(
+          tradesman: tradesman,
+          status: 'pending'
+        )
+      when 'admin'
+        Admin.create!(
+          user: user,
+          fname: name_parts[:fname],
+          lname: name_parts[:lname]
+        )
+      end
+      
       render json: {
-        user_id: user.user_id,
-        name: user.name,
+        user_id: user.id,
+        name: user_params[:name],
         email: user.email,
         role: user.role,
         status: user.status
       }, status: :created
-    else
-      render_error("Failed to create user")
     end
+  rescue ActiveRecord::RecordInvalid => e
+    render_error("Failed to create user: #{e.record.errors.full_messages.join(', ')}")
+  rescue => e
+    render_error("Failed to create user: #{e.message}")
   end
   
   def login
-    login_params = params.permit(:email, :password).to_h.symbolize_keys
+    login_params = params.permit(:email, :password, :two_factor_code).to_h.symbolize_keys
     
     if login_params[:email].blank? || login_params[:password].blank?
       return render_error("Email and password are required", :bad_request)
@@ -49,21 +115,126 @@ class AuthController < ApiController
       return render_error("Invalid email or password", :unauthorized)
     end
     
-    if user.status != 'active'
-      return render_error("Account is not active", :forbidden)
+    if user.status != 'activated'
+      suspension_message = "Account is not active"
+      if user.status == 'suspended'
+        suspension_message = "Account has been suspended. Please contact support."
+      end
+      return render_error(suspension_message, :forbidden)
+    end
+    
+    # Check 2FA for admin users
+    if user.role == 'admin' && user.two_factor_enabled
+      if login_params[:two_factor_code].blank?
+        return render_error("Two-factor authentication code required", :unauthorized)
+      end
+      
+      require 'rotp'
+      totp = ROTP::TOTP.new(user.two_factor_secret)
+      
+      unless totp.verify(login_params[:two_factor_code], drift_behind: 15, drift_ahead: 15)
+        return render_error("Invalid two-factor authentication code", :unauthorized)
+      end
     end
     
+    # Get user's name from profile
+    user_name = get_user_name(user)
+    
     # Generate a simple token (in production, use JWT)
     token = JsonStorage.generate_id
     
     render json: {
       access_token: token,
       token_type: "Bearer",
-      user_id: user.user_id,
-      name: user.name,
+      user_id: user.id,
+      name: user_name,
       email: user.email,
       role: user.role
     }
   end
+  
+  def setup_2fa
+    user_id = params[:user_id]
+    user = User.find_by(id: user_id)
+    
+    return render_error("User not found", :not_found) unless user
+    return render_error("Only admin users can enable 2FA", :forbidden) unless user.role == 'admin'
+    
+    require 'rotp'
+    require 'rqrcode'
+    
+    # Generate secret if not exists
+    secret = user.two_factor_secret || ROTP::Base32.random
+    
+    # Generate provisioning URI
+    totp = ROTP::TOTP.new(secret, issuer: "RoofConnect")
+    provisioning_uri = totp.provisioning_uri(user.email)
+    
+    # Generate QR code
+    qr = RQRCode::QRCode.new(provisioning_uri)
+    qr_code_svg = qr.as_svg(module_size: 4)
+    
+    # Save secret (but don't enable yet - user needs to verify first)
+    user.update(two_factor_secret: secret)
+    
+    render json: {
+      secret: secret,
+      qr_code: qr_code_svg,
+      provisioning_uri: provisioning_uri
+    }
+  end
+  
+  def verify_2fa
+    user_id = params[:user_id]
+    code = params[:code]
+    
+    return render_error("User ID and code required", :bad_request) unless user_id && code
+    
+    user = User.find_by(id: user_id)
+    return render_error("User not found", :not_found) unless user
+    return render_error("Two-factor secret not set", :unprocessable_entity) unless user.two_factor_secret
+    
+    require 'rotp'
+    totp = ROTP::TOTP.new(user.two_factor_secret)
+    
+    if totp.verify(code, drift_behind: 15, drift_ahead: 15)
+      user.update(two_factor_enabled: true)
+      render json: { message: "Two-factor authentication enabled successfully" }
+    else
+      render_error("Invalid verification code", :unauthorized)
+    end
+  end
+  
+  private
+  
+  def parse_name(name)
+    return { fname: '', lname: '' } if name.blank?
+    
+    parts = name.split(' ')
+    if parts.length == 1
+      { fname: parts[0], lname: '' }
+    else
+      { fname: parts[0], lname: parts[1..-1].join(' ') }
+    end
+  end
+  
+  def get_user_name(user)
+    case user.role
+    when 'homeowner'
+      homeowner = user.homeowner
+      homeowner ? "#{homeowner.fname} #{homeowner.lname}".strip : user.email
+    when 'contractor'
+      contractor = user.contractor
+      contractor ? "#{contractor.fname} #{contractor.lname}".strip : user.email
+    when 'tradesman'
+      tradesman = user.tradesman
+      tradesman ? "#{tradesman.fname} #{tradesman.lname}".strip : user.email
+    when 'admin'
+      admin = user.admin
+      admin ? "#{admin.fname} #{admin.lname}".strip : user.email
+    else
+      user.email
+    end
+  end
 end
 
diff --git a/app/backend/app/controllers/messages_controller.rb b/app/backend/app/controllers/messages_controller.rb
index 60212ea..1fb12a2 100644
--- a/app/backend/app/controllers/messages_controller.rb
+++ b/app/backend/app/controllers/messages_controller.rb
@@ -82,30 +82,56 @@ class MessagesController < ApplicationController
   end
   
   def create
-    message_params = params.permit(:sender_id, :receiver_id, :appointment_id, :content, :attachment_url).to_h.symbolize_keys
-    message = Message.new(message_params)
+    message_params = params.permit(:sender_id, :receiver_id, :appointment_id, :content, :attachment_url, :conversation_id).to_h.symbolize_keys
     
-    if message.save
-      # Determine conversation_id for broadcasting
-      conversation_id = if message.appointment_id.present?
-        message.appointment_id
+    # Handle conversation-based messaging
+    if message_params[:conversation_id].present?
+      conversation = Conversation.find_by(id: message_params[:conversation_id])
+      return render_error("Conversation not found", :not_found) unless conversation
+      
+      message = Message.new(
+        conversation: conversation,
+        sender_id: message_params[:sender_id],
+        content: message_params[:content],
+        attachment: message_params[:attachment_url]
+      )
+    else
+      # Legacy support - create or find conversation
+      if message_params[:sender_id] && message_params[:receiver_id]
+        conversation = Conversation.find_or_create_between(
+          message_params[:sender_id],
+          message_params[:receiver_id]
+        )
+        message = Message.new(
+          conversation: conversation,
+          sender_id: message_params[:sender_id],
+          content: message_params[:content],
+          attachment: message_params[:attachment_url]
+        )
       else
-        Message.conversation_id(message.sender_id, message.receiver_id)
+        return render_error("Sender ID and receiver ID or conversation ID required", :bad_request)
       end
+    end
+    
+    if message.save
+      # Notify receiver of new message
+      NotificationService.notify_new_message(message)
+      
+      # Determine conversation_id for broadcasting
+      conversation_id = message.conversation.id
       
       # Get sender name for broadcast
-      sender = User.find_by_id(message.sender_id)
+      sender = User.find_by(id: message.sender_id)
       
       # Broadcast via ActionCable
       message_data = {
-        message_id: message.message_id,
+        message_id: message.id,
         sender_id: message.sender_id,
         sender_name: sender&.name || 'Unknown',
-        receiver_id: message.receiver_id,
         content: message.content,
-        timestamp: message.timestamp,
-        attachment_url: message.attachment_url,
-        read: message.read,
+        timestamp: message.created_at,
+        attachment_url: message.attachment,
+        read: message.read_at.present?,
         conversation_id: conversation_id
       }
       
diff --git a/app/backend/app/controllers/profiles_controller.rb b/app/backend/app/controllers/profiles_controller.rb
index 9687241..26a133d 100644
--- a/app/backend/app/controllers/profiles_controller.rb
+++ b/app/backend/app/controllers/profiles_controller.rb
@@ -1,34 +1,87 @@
 class ProfilesController < ApiController
   def show
     user_id = params[:user_id]
-    user = User.find_by_id(user_id)
+    user = User.find_by(id: user_id)
     
     if user.nil?
       return render_error("User not found", :not_found)
     end
     
-    # Build profile response
+    # Get user name from related model
+    user_name = get_user_name(user)
+    
+    # Build address from related model
+    address = get_user_address(user)
+    
+    # Build base profile response (excluding sensitive data like password_hash)
     response_data = {
-      user_id: user.user_id,
-      name: user.name,
+      user_id: user.id,
+      name: user_name,
       email: user.email,
       role: user.role,
-      address: user.address,
-      profile: user.profile || {}
+      status: user.status,
+      address: address
     }
     
     # If tradesman, include tradesman-specific profile data
     if user.role == 'tradesman'
-      tradesman = Tradesman.find_by_id(user_id)
+      tradesman = user.tradesman
       if tradesman
         response_data[:profile] = {
+          fname: tradesman.fname,
+          lname: tradesman.lname,
           license_number: tradesman.license_number,
-          trade: tradesman.trade,
-          experience: tradesman.experience,
+          trade_specialty: tradesman.trade_specialty,
+          years_of_experience: tradesman.years_of_experience,
           rating: tradesman.rating,
           business_name: tradesman.business_name,
-          location: tradesman.location
-        }.merge(response_data[:profile])
+          hourly_rate: tradesman.hourly_rate,
+          service_radius: tradesman.service_radius,
+          verification_status: tradesman.verification_status,
+          street: tradesman.street,
+          city: tradesman.city,
+          state: tradesman.state,
+          number: tradesman.number
+        }
+      end
+    # If contractor, include contractor-specific profile data
+    elsif user.role == 'contractor'
+      contractor = user.contractor
+      if contractor
+        response_data[:profile] = {
+          fname: contractor.fname,
+          lname: contractor.lname,
+          street: contractor.street,
+          city: contractor.city,
+          state: contractor.state,
+          number: contractor.number
+        }
+      end
+    # If homeowner, include homeowner-specific profile data
+    elsif user.role == 'homeowner'
+      homeowner = user.homeowner
+      if homeowner
+        response_data[:profile] = {
+          fname: homeowner.fname,
+          lname: homeowner.lname,
+          street: homeowner.street,
+          city: homeowner.city,
+          state: homeowner.state,
+          number: homeowner.number
+        }
+      end
+    # If admin, include admin-specific profile data
+    elsif user.role == 'admin'
+      admin = user.admin
+      if admin
+        response_data[:profile] = {
+          fname: admin.fname,
+          lname: admin.lname,
+          street: admin.street,
+          city: admin.city,
+          state: admin.state,
+          number: admin.number
+        }
       end
     end
     
@@ -37,36 +90,126 @@ class ProfilesController < ApiController
   
   def update
     user_id = params[:user_id]
-    user = User.find_by_id(user_id)
+    user = User.find_by(id: user_id)
     
     if user.nil?
       return render_error("User not found", :not_found)
     end
     
-    update_params = params.permit(:name, :address, profile: {}).to_h.symbolize_keys
+    update_params = params.permit(:name, profile: {}).to_h.symbolize_keys
     
-    # Update user fields
-    user.name = update_params[:name] if update_params[:name]
-    user.address = update_params[:address] if update_params[:address]
+    # Update name in role-specific profile
+    if update_params[:name]
+      name_parts = parse_name(update_params[:name])
+      
+      case user.role
+      when 'tradesman'
+        tradesman = user.tradesman
+        if tradesman
+          tradesman.fname = name_parts[:fname] if name_parts[:fname]
+          tradesman.lname = name_parts[:lname] if name_parts[:lname]
+          tradesman.save
+        end
+      when 'contractor'
+        contractor = user.contractor
+        if contractor
+          contractor.fname = name_parts[:fname] if name_parts[:fname]
+          contractor.lname = name_parts[:lname] if name_parts[:lname]
+          contractor.save
+        end
+      when 'homeowner'
+        homeowner = user.homeowner
+        if homeowner
+          homeowner.fname = name_parts[:fname] if name_parts[:fname]
+          homeowner.lname = name_parts[:lname] if name_parts[:lname]
+          homeowner.save
+        end
+      when 'admin'
+        admin = user.admin
+        if admin
+          admin.fname = name_parts[:fname] if name_parts[:fname]
+          admin.lname = name_parts[:lname] if name_parts[:lname]
+          admin.save
+        end
+      end
+    end
     
-    # Update profile if provided
+    # Update profile fields if provided
     if update_params[:profile]
-      user.profile = (user.profile || {}).merge(update_params[:profile])
+      case user.role
+      when 'tradesman'
+        tradesman = user.tradesman
+        if tradesman
+          tradesman.update(update_params[:profile].slice(:street, :city, :state, :number, :business_name, :hourly_rate, :service_radius))
+        end
+      when 'contractor'
+        contractor = user.contractor
+        if contractor
+          contractor.update(update_params[:profile].slice(:street, :city, :state, :number))
+        end
+      when 'homeowner'
+        homeowner = user.homeowner
+        if homeowner
+          homeowner.update(update_params[:profile].slice(:street, :city, :state, :number))
+        end
+      end
     end
     
-    # If tradesman, also update tradesman profile
-    if user.role == 'tradesman' && update_params[:profile]
-      tradesman = Tradesman.find_by_id(user_id)
-      if tradesman
-        tradesman.experience = update_params[:profile][:experience] if update_params[:profile][:experience]
-        tradesman.save
+    render json: { message: "Profile updated successfully" }
+  end
+  
+  private
+  
+  def get_user_name(user)
+    case user.role
+    when 'homeowner'
+      homeowner = user.homeowner
+      homeowner ? "#{homeowner.fname} #{homeowner.lname}".strip : user.email
+    when 'contractor'
+      contractor = user.contractor
+      contractor ? "#{contractor.fname} #{contractor.lname}".strip : user.email
+    when 'tradesman'
+      tradesman = user.tradesman
+      tradesman ? "#{tradesman.fname} #{tradesman.lname}".strip : user.email
+    when 'admin'
+      admin = user.admin
+      admin ? "#{admin.fname} #{admin.lname}".strip : user.email
+    else
+      user.email
+    end
+  end
+  
+  def get_user_address(user)
+    case user.role
+    when 'homeowner'
+      homeowner = user.homeowner
+      if homeowner && (homeowner.street || homeowner.city || homeowner.state)
+        parts = [homeowner.street, homeowner.city, homeowner.state].compact
+        parts.join(', ') if parts.any?
+      end
+    when 'contractor'
+      contractor = user.contractor
+      if contractor && (contractor.street || contractor.city || contractor.state)
+        parts = [contractor.street, contractor.city, contractor.state].compact
+        parts.join(', ') if parts.any?
+      end
+    when 'tradesman'
+      tradesman = user.tradesman
+      if tradesman && (tradesman.street || tradesman.city || tradesman.state)
+        parts = [tradesman.street, tradesman.city, tradesman.state].compact
+        parts.join(', ') if parts.any?
       end
     end
+  end
+  
+  def parse_name(name)
+    return { fname: '', lname: '' } if name.blank?
     
-    if user.save
-      render json: { message: "Profile updated successfully" }
+    parts = name.split(' ')
+    if parts.length == 1
+      { fname: parts[0], lname: '' }
     else
-      render_error("Failed to update profile")
+      { fname: parts[0], lname: parts[1..-1].join(' ') }
     end
   end
 end
diff --git a/app/backend/app/controllers/projects_controller.rb b/app/backend/app/controllers/projects_controller.rb
index b1e2321..2406721 100644
--- a/app/backend/app/controllers/projects_controller.rb
+++ b/app/backend/app/controllers/projects_controller.rb
@@ -1,12 +1,16 @@
 class ProjectsController < ApplicationController
-  skip_before_action :verify_authenticity_token, only: [:create, :user_projects, :project_details]
+  skip_before_action :verify_authenticity_token, only: [:create, :user_projects, :project_details, :update, :publish]
   
   def new
     # Display the form for creating a new project
   end
   
   def index
-    # List all projects for a user
+    # List all projects for a user (homeowner/contractor)
+  end
+  
+  def listing
+    # List all open projects for tradesmen to bid on
   end
   
   def show
@@ -14,26 +18,82 @@ class ProjectsController < ApplicationController
   end
   
   def create
-    # Get user_id from params
+    # Get user_id from params (can be at top level)
     user_id = params[:user_id]
     
     if user_id.blank?
       return render json: { error: "User ID is required" }, status: :unauthorized
     end
     
+    # Find user
+    user = User.find_by(id: user_id)
+    if user.nil?
+      return render json: { error: "User not found" }, status: :not_found
+    end
+    
+    # Handle params that may be nested under :project or at top level
+    # Prefer nested params if they exist, otherwise use top-level
+    source_params = params[:project].present? ? params[:project] : params
+    
     # Create project
-    project_params = params.permit(:title, :description, :trade_type, :budget, :location, :preferred_date).to_h.symbolize_keys
-    project_params[:user_id] = user_id
+    project_params = source_params.permit(:title, :description, :trade_type, :budget, :location, :preferred_date).to_h.symbolize_keys
+    
+    # Convert budget to decimal if it's a string
+    if project_params[:budget].is_a?(String)
+      project_params[:budget] = project_params[:budget].to_f
+    end
+    
+    # Normalize trade_type to lowercase
+    if project_params[:trade_type].present?
+      trade_type = project_params[:trade_type].downcase.strip
+      # Normalize common variations
+      trade_type = 'hvac worker' if trade_type == 'hvac'
+      project_params[:trade_type] = trade_type
+    end
+    
+    # Handle empty preferred_date
+    project_params[:preferred_date] = nil if project_params[:preferred_date].blank?
+    # Convert preferred_date to Date if it's a string
+    if project_params[:preferred_date].is_a?(String) && project_params[:preferred_date].present?
+      begin
+        project_params[:preferred_date] = Date.parse(project_params[:preferred_date])
+      rescue ArgumentError
+        project_params[:preferred_date] = nil
+      end
+    end
+    
+    # Set homeowner_id or contractor_id based on user role
+    if user.role == 'contractor'
+      contractor = user.contractor
+      if contractor.nil?
+        return render json: { error: "Contractor profile not found" }, status: :not_found
+      end
+      project_params[:contractor_id] = user.id
+    elsif user.role == 'homeowner'
+      homeowner = user.homeowner
+      if homeowner.nil?
+        return render json: { error: "Homeowner profile not found" }, status: :not_found
+      end
+      project_params[:homeowner_id] = homeowner.id
+    else
+      return render json: { error: "Only homeowners and contractors can create projects" }, status: :forbidden
+    end
+    
+    # Set default status
+    project_params[:status] = 'open' unless project_params[:status]
     
     project = Project.new(project_params)
     
     if project.save
       render json: {
         message: "Project created successfully",
-        project: project.to_hash
+        project: project_to_hash(project)
       }, status: :created
     else
-      render json: { error: "Failed to create project" }, status: :unprocessable_entity
+      render json: { 
+        error: "Failed to create project",
+        errors: project.errors.full_messages
+      }, status: :unprocessable_entity
     end
   rescue => e
     render json: { error: "Server error: #{e.message}" }, status: :internal_server_error
@@ -46,19 +106,106 @@ class ProjectsController < ApplicationController
       return render json: { error: "User ID is required" }, status: :bad_request
     end
     
-    projects = Project.find_by_user_id(user_id)
+    user = User.find_by(id: user_id)
+    if user.nil?
+      return render json: { error: "User not found" }, status: :not_found
+    end
     
-    render json: projects.map(&:to_hash)
+    # Find projects based on user role
+    if user.role == 'contractor'
+      projects = Project.where(contractor_id: user.id)
+    elsif user.role == 'homeowner'
+      homeowner = user.homeowner
+      projects = homeowner ? Project.where(homeowner_id: homeowner.id) : []
+    else
+      projects = []
+    end
+    
+    render json: projects.map { |p| project_to_hash(p) }
   end
   
   def project_details
     project_id = params[:id]
-    project = Project.find_by_id(project_id)
+    project = Project.find_by(id: project_id)
     
     if project
-      render json: project.to_hash
+      render json: project_to_hash(project)
     else
       render json: { error: "Project not found" }, status: :not_found
     end
   end
+  
+  def update
+    project = Project.find_by(id: params[:id])
+    
+    if project.nil?
+      render json: { error: "Project not found" }, status: :not_found
+    else
+      project_params = params.permit(:title, :description, :trade_type, :budget, :location, 
+                                      :preferred_date, :bidding_increments, :status).to_h.symbolize_keys
+      
+      # Handle preferred_date conversion
+      if project_params[:preferred_date].is_a?(String) && project_params[:preferred_date].present?
+        begin
+          project_params[:preferred_date] = Date.parse(project_params[:preferred_date])
+        rescue ArgumentError
+          project_params[:preferred_date] = nil
+        end
+      end
+      project_params[:preferred_date] = nil if project_params[:preferred_date].blank?
+      
+      if project.update(project_params)
+        render json: {
+          message: "Project updated successfully",
+          project: project_to_hash(project)
+        }
+      else
+        render json: { 
+          error: "Failed to update project",
+          errors: project.errors.full_messages
+        }, status: :unprocessable_entity
+      end
+    end
+  end
+  
+  def publish
+    project = Project.find_by(id: params[:id])
+    
+    if project.nil?
+      render json: { error: "Project not found" }, status: :not_found
+    else
+      project.update(status: 'open')
+      
+      render json: {
+        message: "Project published successfully",
+        project_id: project.id,
+        status: project.status
+      }
+    end
+  end
+  
+  private
+  
+  def project_to_hash(project)
+    {
+      id: project.id,
+      project_id: project.id,  # Frontend expects project_id
+      title: project.title,
+      description: project.description,
+      trade_type: project.trade_type,
+      budget: project.budget,
+      location: project.location,
+      preferred_date: project.preferred_date,
+      status: project.status,
+      bidding_increments: project.bidding_increments,
+      timespan: project.timespan,
+      requirements: project.requirements,
+      contractor_id: project.contractor_id,
+      homeowner_id: project.homeowner_id,
+      assigned_id: project.assigned_id,
+      created_at: project.created_at,
+      updated_at: project.updated_at,
+      bid_count: project.bids.count
+    }
+  end
 end
diff --git a/app/backend/app/controllers/reviews_controller.rb b/app/backend/app/controllers/reviews_controller.rb
index f16e011..4ee8085 100644
--- a/app/backend/app/controllers/reviews_controller.rb
+++ b/app/backend/app/controllers/reviews_controller.rb
@@ -4,6 +4,9 @@ class ReviewsController < ApiController
     review = Review.new(review_params)
     
     if review.save
+      # Notify tradesman of new review
+      NotificationService.notify_new_review(review)
+      
       render json: { message: "Review submitted successfully" }, status: :created
     else
       render_error("Failed to submit review")
diff --git a/app/backend/app/controllers/schedules_controller.rb b/app/backend/app/controllers/schedules_controller.rb
index 7d94b86..8256c23 100644
--- a/app/backend/app/controllers/schedules_controller.rb
+++ b/app/backend/app/controllers/schedules_controller.rb
@@ -1,17 +1,138 @@
 class SchedulesController < ApiController
   def show
     tradesman_id = params[:id]
-    schedules = Schedule.find_by_tradesman_id(tradesman_id)
+    schedules = Schedule.where(tradesman_id: tradesman_id)
+    
+    # Optional date filter
+    if params[:date].present?
+      schedules = schedules.where(date: params[:date])
+    end
+    
+    # Optional date range filter
+    if params[:start_date].present? && params[:end_date].present?
+      schedules = schedules.where(date: params[:start_date]..params[:end_date])
+    end
+    
+    schedules = schedules.order(:date, :start_time)
     
     render json: schedules.map { |s|
       {
-        schedule_id: s.schedule_id,
+        schedule_id: s.id,
+        tradesman_id: s.tradesman_id,
         date: s.date,
         start_time: s.start_time,
         end_time: s.end_time,
-        status: s.status
+        status: s.status,
+        created_at: s.created_at,
+        updated_at: s.updated_at
       }
     }
   end
+  
+  def create
+    schedule_params = params.permit(:tradesman_id, :date, :start_time, :end_time, :status).to_h.symbolize_keys
+    
+    # Validate required fields
+    if schedule_params[:tradesman_id].blank? || schedule_params[:date].blank? || 
+       schedule_params[:start_time].blank? || schedule_params[:end_time].blank?
+      return render_error("tradesman_id, date, start_time, and end_time are required", :bad_request)
+    end
+    
+    # Set default status if not provided
+    schedule_params[:status] ||= 'available'
+    
+    schedule = Schedule.new(schedule_params)
+    
+    if schedule.save
+      render json: {
+        schedule_id: schedule.id,
+        tradesman_id: schedule.tradesman_id,
+        date: schedule.date,
+        start_time: schedule.start_time,
+        end_time: schedule.end_time,
+        status: schedule.status
+      }, status: :created
+    else
+      render_error("Failed to create schedule: #{schedule.errors.full_messages.join(', ')}")
+    end
+  end
+  
+  def update
+    schedule = Schedule.find_by(id: params[:id])
+    
+    if schedule.nil?
+      render_error("Schedule not found", :not_found)
+    else
+      schedule_params = params.permit(:date, :start_time, :end_time, :status).to_h.symbolize_keys
+      
+      if schedule.update(schedule_params)
+        render json: {
+          schedule_id: schedule.id,
+          tradesman_id: schedule.tradesman_id,
+          date: schedule.date,
+          start_time: schedule.start_time,
+          end_time: schedule.end_time,
+          status: schedule.status
+        }
+      else
+        render_error("Failed to update schedule: #{schedule.errors.full_messages.join(', ')}")
+      end
+    end
+  end
+  
+  def destroy
+    schedule = Schedule.find_by(id: params[:id])
+    
+    if schedule.nil?
+      render_error("Schedule not found", :not_found)
+    else
+      schedule.destroy
+      render json: { message: "Schedule deleted successfully" }
+    end
+  end
+  
+  def bulk_create
+    tradesman_id = params[:tradesman_id]
+    return render_error("tradesman_id is required", :bad_request) unless tradesman_id
+    
+    schedules_data = params[:schedules] || []
+    return render_error("schedules array is required", :bad_request) if schedules_data.empty?
+    
+    created_schedules = []
+    errors = []
+    
+    schedules_data.each_with_index do |schedule_data, index|
+      schedule_params = schedule_data.permit(:date, :start_time, :end_time, :status).to_h.symbolize_keys
+      schedule_params[:tradesman_id] = tradesman_id
+      schedule_params[:status] ||= 'available'
+      
+      schedule = Schedule.new(schedule_params)
+      
+      if schedule.save
+        created_schedules << {
+          schedule_id: schedule.id,
+          date: schedule.date,
+          start_time: schedule.start_time,
+          end_time: schedule.end_time,
+          status: schedule.status
+        }
+      else
+        errors << { index: index, errors: schedule.errors.full_messages }
+      end
+    end
+    
+    if errors.empty?
+      render json: {
+        message: "Successfully created #{created_schedules.count} schedule(s)",
+        schedules: created_schedules
+      }, status: :created
+    else
+      render json: {
+        message: "Created #{created_schedules.count} schedule(s), #{errors.count} failed",
+        schedules: created_schedules,
+        errors: errors
+      }, status: :partial_content
+    end
+  end
 end
 
diff --git a/app/backend/app/controllers/tradesmen_controller.rb b/app/backend/app/controllers/tradesmen_controller.rb
index 3be55d8..3e86566 100644
--- a/app/backend/app/controllers/tradesmen_controller.rb
+++ b/app/backend/app/controllers/tradesmen_controller.rb
@@ -1,60 +1,162 @@
 class TradesmenController < ApiController
   def index
-    trade = params[:trade]
-    location = params[:location]
-    name = params[:name]
+    tradesmen = Tradesman.all.includes(:user, :reviews)
     
-    tradesmen = if trade.present? || location.present? || name.present?
-      Tradesman.find_by_trade_and_location(trade, location, name)
-    else
-      Tradesman.all
+    # Filter by trade specialty
+    tradesmen = tradesmen.by_trade(params[:trade]) if params[:trade].present?
+    
+    # Filter by location (city)
+    tradesmen = tradesmen.by_location(params[:location]) if params[:location].present?
+    
+    # Filter by verified status (only show verified tradesmen by default)
+    if params[:verified_only] != 'false'
+      tradesmen = tradesmen.verified
+    end
+    
+    # Filter by rating (backend filtering)
+    if params[:min_rating].present?
+      min_rating = params[:min_rating].to_f
+      tradesmen = tradesmen.select { |t| t.rating >= min_rating }
+    end
+    
+    # Filter by hourly rate range
+    if params[:min_hourly_rate].present?
+      min_rate = params[:min_hourly_rate].to_f
+      tradesmen = tradesmen.select { |t| t.hourly_rate && t.hourly_rate >= min_rate }
+    end
+    
+    if params[:max_hourly_rate].present?
+      max_rate = params[:max_hourly_rate].to_f
+      tradesmen = tradesmen.select { |t| t.hourly_rate && t.hourly_rate <= max_rate }
+    end
+    
+    # Filter by distance (if user location provided)
+    if params[:user_latitude].present? && params[:user_longitude].present?
+      user_lat = params[:user_latitude].to_f
+      user_lng = params[:user_longitude].to_f
+      max_distance = params[:max_distance]&.to_f || 50.0 # Default 50 miles
+      
+      tradesmen = tradesmen.select do |t|
+        if t.latitude && t.longitude && t.service_radius
+          distance = calculate_distance_haversine(user_lat, user_lng, t.latitude, t.longitude)
+          distance <= max_distance && distance <= t.service_radius
+        else
+          false
+        end
+      end
+    end
+    
+    # Sort by rating (if requested)
+    if params[:sort] == 'rating'
+      tradesmen = tradesmen.sort_by { |t| -t.rating }
+    elsif params[:sort] == 'hourly_rate'
+      tradesmen = tradesmen.sort_by { |t| t.hourly_rate || Float::INFINITY }
     end
     
     render json: tradesmen.map { |t| 
+      distance = nil
+      if params[:user_latitude].present? && params[:user_longitude].present? && t.latitude && t.longitude
+        distance = calculate_distance_haversine(
+          params[:user_latitude].to_f,
+          params[:user_longitude].to_f,
+          t.latitude,
+          t.longitude
+        )
+      end
+      
       {
+        tradesman_id: t.id,
         user_id: t.user_id,
-        name: t.name,
-        email: t.email,
-        trade: t.trade,
+        name: "#{t.fname} #{t.lname}".strip,
+        email: t.user.email,
+        trade_specialty: t.trade_specialty,
         rating: t.rating,
-        address: t.address,
-        location: t.location,
-        experience: t.experience,
+        hourly_rate: t.hourly_rate,
+        service_radius: t.service_radius,
         business_name: t.business_name,
-        profile: t.profile,
-        distance: calculate_distance(t.location)
+        years_of_experience: t.years_of_experience,
+        license_number: t.license_number,
+        street: t.street,
+        city: t.city,
+        state: t.state,
+        number: t.number,
+        verification_status: t.verification_status,
+        distance: distance ? distance.round(2) : nil
       }
     }
   end
   
   def show
-    tradesman = Tradesman.find_by_id(params[:id])
+    tradesman = Tradesman.find_by(id: params[:id])
     
     if tradesman.nil?
       render json: { error: "Tradesman not found" }, status: :not_found
     else
       render json: {
+        tradesman_id: tradesman.id,
         user_id: tradesman.user_id,
-        name: tradesman.name,
-        email: tradesman.email,
-        trade: tradesman.trade,
+        name: "#{tradesman.fname} #{tradesman.lname}".strip,
+        email: tradesman.user.email,
+        trade_specialty: tradesman.trade_specialty,
         rating: tradesman.rating,
-        address: tradesman.address,
-        location: tradesman.location,
-        experience: tradesman.experience,
+        hourly_rate: tradesman.hourly_rate,
+        service_radius: tradesman.service_radius,
         business_name: tradesman.business_name,
+        years_of_experience: tradesman.years_of_experience,
         license_number: tradesman.license_number,
-        profile: tradesman.profile
+        description: tradesman.description,
+        street: tradesman.street,
+        city: tradesman.city,
+        state: tradesman.state,
+        number: tradesman.number,
+        latitude: tradesman.latitude,
+        longitude: tradesman.longitude,
+        verification_status: tradesman.verification_status
       }
     end
   end
   
+  def compare
+    ids = params[:ids] || params[:id]
+    return render_error("ids parameter required (comma-separated)", :bad_request) unless ids
+    
+    tradesman_ids = ids.to_s.split(',').map(&:strip).map(&:to_i)
+    tradesmen = Tradesman.where(id: tradesman_ids).includes(:user, :reviews)
+    
+    render json: tradesmen.map { |t|
+      {
+        tradesman_id: t.id,
+        user_id: t.user_id,
+        name: "#{t.fname} #{t.lname}".strip,
+        email: t.user.email,
+        trade_specialty: t.trade_specialty,
+        rating: t.rating,
+        hourly_rate: t.hourly_rate,
+        service_radius: t.service_radius,
+        business_name: t.business_name,
+        years_of_experience: t.years_of_experience,
+        license_number: t.license_number,
+        verification_status: t.verification_status,
+        review_count: t.reviews.count
+      }
+    }
+  end
+  
   private
   
-  def calculate_distance(location)
-    # Placeholder distance calculation
-    # In a real app, this would calculate based on user's location and tradesman's location
-    return "12.3" if location.present?
-    "15.0"
+  def calculate_distance_haversine(lat1, lon1, lat2, lon2)
+    # Haversine formula to calculate distance between two points in miles
+    earth_radius_miles = 3959.0
+    
+    dlat = (lat2 - lat1) * Math::PI / 180.0
+    dlon = (lon2 - lon1) * Math::PI / 180.0
+    
+    a = Math.sin(dlat / 2) ** 2 +
+        Math.cos(lat1 * Math::PI / 180.0) *
+        Math.cos(lat2 * Math::PI / 180.0) *
+        Math.sin(dlon / 2) ** 2
+    
+    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
+    earth_radius_miles * c
   end
 end
diff --git a/app/backend/app/models/appointment.rb b/app/backend/app/models/appointment.rb
index c9a2db5..6fd9a88 100644
--- a/app/backend/app/models/appointment.rb
+++ b/app/backend/app/models/appointment.rb
@@ -1,62 +1,31 @@
-class Appointment
-  attr_accessor :appointment_id, :homeowner_id, :tradesman_id, :scheduled_start, 
-                :scheduled_end, :job_description, :status
-  
-  def initialize(attributes = {})
-    @appointment_id = attributes[:appointment_id] || JsonStorage.generate_id
-    @homeowner_id = attributes[:homeowner_id]
-    @tradesman_id = attributes[:tradesman_id]
-    @scheduled_start = attributes[:scheduled_start]
-    @scheduled_end = attributes[:scheduled_end]
-    @job_description = attributes[:job_description]
-    @status = attributes[:status] || 'pending'
-  end
-  
-  def self.all
-    data = JsonStorage.read('appointments')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def self.find_by_id(id)
-    all.find { |a| a.appointment_id == id }
-  end
-  
-  def save
-    appointments = self.class.all
-    existing_index = appointments.find_index { |a| a.appointment_id == @appointment_id }
-    
-    if existing_index
-      appointments[existing_index] = self
-    else
-      appointments << self
-    end
-    
-    JsonStorage.write('appointments', appointments.map(&:to_hash))
-    self
-  end
-  
+class Appointment < ApplicationRecord
+  belongs_to :homeowner
+  belongs_to :tradesman
+  belongs_to :project, optional: true
+
+  validates :scheduled_start, presence: true
+  validates :scheduled_end, presence: true
+  validates :status, inclusion: { in: %w[pending confirmed rejected completed cancelled] }
+
   def cancel
-    @status = 'canceled'
-    save
+    update(status: 'cancelled')
   end
   
-  def to_hash
-    {
-      appointment_id: @appointment_id,
-      homeowner_id: @homeowner_id,
-      tradesman_id: @tradesman_id,
-      scheduled_start: @scheduled_start,
-      scheduled_end: @scheduled_end,
-      job_description: @job_description,
-      status: @status
-    }
+  def accept(reason = nil)
+    update(
+      status: 'confirmed',
+      accepted_at: Time.current,
+      rejected_at: nil,
+      rejection_reason: nil
+    )
   end
   
-  def as_json(options = {})
-    to_hash.as_json(options)
+  def reject(reason = nil)
+    update(
+      status: 'rejected',
+      rejected_at: Time.current,
+      accepted_at: nil,
+      rejection_reason: reason
+    )
   end
 end
-
diff --git a/app/backend/app/models/message.rb b/app/backend/app/models/message.rb
index 7bd0ecf..1e7ae68 100644
--- a/app/backend/app/models/message.rb
+++ b/app/backend/app/models/message.rb
@@ -1,126 +1,51 @@
-class Message
-  attr_accessor :message_id, :sender_id, :receiver_id, :appointment_id, 
-                :content, :timestamp, :attachment_url, :read, :read_at
-  
-  def initialize(attributes = {})
-    @message_id = attributes[:message_id] || JsonStorage.generate_id
-    @sender_id = attributes[:sender_id]
-    @receiver_id = attributes[:receiver_id]
-    @appointment_id = attributes[:appointment_id]
-    @content = attributes[:content]
-    @timestamp = attributes[:timestamp] || Time.now.utc.iso8601
-    @attachment_url = attributes[:attachment_url]
-    @read = attributes[:read] || false
-    @read_at = attributes[:read_at]
-  end
-  
-  def self.all
-    data = JsonStorage.read('messages')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def self.conversation_id(user1_id, user2_id, appointment_id = nil)
-    return appointment_id if appointment_id.present?
-    # Generate consistent conversation ID by sorting user IDs
-    [user1_id, user2_id].sort.join('_')
+class Message < ApplicationRecord
+  belongs_to :conversation
+  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
+
+  validates :content, presence: true
+
+  # Mark message as read
+  def mark_as_read!
+    update(read_at: Time.current)
   end
-  
+
+  # Class methods for backward compatibility during migration
   def self.find_by_conversation_id(conversation_id)
-    # conversation_id can be appointment_id or a combination of sender_id and receiver_id
-    all.select do |m|
-      if m.appointment_id.present?
-        m.appointment_id == conversation_id
-      else
-        # For user-to-user conversations, check if conversation_id matches the sorted user IDs
-        sorted_ids = [m.sender_id, m.receiver_id].sort.join('_')
-        sorted_ids == conversation_id
-      end
-    end.sort_by { |m| m.timestamp || '' }
+    # Try to find by conversation ID (integer)
+    if conversation_id.to_s.match?(/^\d+$/)
+      conversation = Conversation.find_by(id: conversation_id)
+      return conversation&.messages&.order(:created_at) || []
+    end
+    
+    # Legacy: Try to find by appointment_id or user IDs
+    # This is for backward compatibility during migration
+    []
   end
-  
+
   def self.find_conversations_for_user(user_id)
-    # Get all unique conversations for a user
-    user_messages = all.select do |m|
-      m.sender_id == user_id || m.receiver_id == user_id
-    end
+    # Find all conversations where user is a participant
+    conversations = Conversation.where(
+      'participant1_id = ? OR participant2_id = ?', user_id, user_id
+    ).includes(:messages).order('messages.created_at DESC')
     
-    # Group by conversation
-    conversations = {}
-    user_messages.each do |message|
-      conv_id = if message.appointment_id.present?
-        message.appointment_id
-      else
-        [message.sender_id, message.receiver_id].sort.join('_')
-      end
+    conversations.map do |conv|
+      other_user_id = conv.participant1_id == user_id.to_i ? conv.participant2_id : conv.participant1_id
+      last_message = conv.messages.order(:created_at).last
       
-      conversations[conv_id] ||= {
-        conversation_id: conv_id,
-        appointment_id: message.appointment_id,
-        other_user_id: message.sender_id == user_id ? message.receiver_id : message.sender_id,
-        last_message: message,
-        unread_count: 0
+      {
+        conversation_id: conv.id,
+        appointment_id: nil, # Will be handled separately if needed
+        other_user_id: other_user_id,
+        last_message: last_message,
+        unread_count: conv.messages.where('sender_id != ? AND read_at IS NULL', user_id).count
       }
-      
-      # Update last message if this one is newer
-      if conversations[conv_id][:last_message].timestamp.nil? || 
-         (message.timestamp && message.timestamp > conversations[conv_id][:last_message].timestamp)
-        conversations[conv_id][:last_message] = message
-      end
-    end
-    
-    # Calculate unread counts
-    conversations.each do |conv_id, conv_data|
-      conv_data[:unread_count] = unread_count(user_id, conv_id)
     end
-    
-    conversations.values.sort_by { |c| c[:last_message].timestamp || '' }.reverse
   end
-  
+
   def self.unread_count(user_id, conversation_id)
-    find_by_conversation_id(conversation_id).count do |m|
-      m.receiver_id == user_id && !m.read
-    end
-  end
-  
-  def mark_as_read!
-    @read = true
-    @read_at = Time.now.utc.iso8601
-    save
-  end
-  
-  def save
-    messages = self.class.all
-    existing_index = messages.find_index { |m| m.message_id == @message_id }
-    
-    if existing_index
-      messages[existing_index] = self
-    else
-      messages << self
-    end
+    conversation = Conversation.find_by(id: conversation_id)
+    return 0 unless conversation
     
-    JsonStorage.write('messages', messages.map(&:to_hash))
-    self
-  end
-  
-  def to_hash
-    {
-      message_id: @message_id,
-      sender_id: @sender_id,
-      receiver_id: @receiver_id,
-      appointment_id: @appointment_id,
-      content: @content,
-      timestamp: @timestamp,
-      attachment_url: @attachment_url,
-      read: @read,
-      read_at: @read_at
-    }
-  end
-  
-  def as_json(options = {})
-    to_hash.as_json(options)
+    conversation.messages.where('sender_id != ? AND read_at IS NULL', user_id).count
   end
 end
-
diff --git a/app/backend/app/models/project.rb b/app/backend/app/models/project.rb
index 3386e04..4aa1161 100644
--- a/app/backend/app/models/project.rb
+++ b/app/backend/app/models/project.rb
@@ -1,68 +1,18 @@
-class Project
-  attr_accessor :project_id, :user_id, :title, :description, :trade_type, :budget, :location, 
-                :preferred_date, :status, :created_at, :updated_at, :bids
+class Project < ApplicationRecord
+  belongs_to :contractor, class_name: 'User', foreign_key: 'contractor_id', optional: true
+  belongs_to :homeowner, optional: true
+  belongs_to :assigned, class_name: 'Tradesman', foreign_key: 'assigned_id', optional: true
+
+  has_many :bids, dependent: :destroy
+  has_many :appointments, dependent: :destroy
+  has_many :estimates, dependent: :destroy
+
+  validates :title, presence: true
+  validates :status, inclusion: { in: %w[open in_progress completed cancelled] }
   
-  def initialize(attributes = {})
-    @project_id = attributes[:project_id] || JsonStorage.generate_id
-    @user_id = attributes[:user_id]
-    @title = attributes[:title]
-    @description = attributes[:description]
-    @trade_type = attributes[:trade_type]
-    @budget = attributes[:budget]
-    @location = attributes[:location]
-    @preferred_date = attributes[:preferred_date]
-    @status = attributes[:status] || 'open'
-    @created_at = attributes[:created_at] || Time.now.iso8601
-    @updated_at = attributes[:updated_at] || Time.now.iso8601
-    @bids = attributes[:bids] || []
-  end
-  
-  def self.all
-    data = JsonStorage.read('projects')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def self.find_by_id(id)
-    all.find { |p| p.project_id == id }
-  end
-  
-  def self.find_by_user_id(user_id)
-    all.select { |p| p.user_id == user_id }
-  end
-  
-  def save
-    projects = self.class.all
-    existing_index = projects.find_index { |p| p.project_id == @project_id }
-    
-    @updated_at = Time.now.iso8601
-    
-    if existing_index
-      projects[existing_index] = self
-    else
-      projects << self
-    end
-    
-    JsonStorage.write('projects', projects.map(&:to_hash))
-    self
-  end
-  
-  def to_hash
-    {
-      project_id: @project_id,
-      user_id: @user_id,
-      title: @title,
-      description: @description,
-      trade_type: @trade_type,
-      budget: @budget,
-      location: @location,
-      preferred_date: @preferred_date,
-      status: @status,
-      created_at: @created_at,
-      updated_at: @updated_at,
-      bids: @bids
-    }
+  # Get the contractor profile if contractor_id is set
+  def contractor_profile
+    return nil unless contractor_id
+    User.find_by(id: contractor_id)&.contractor
   end
 end
diff --git a/app/backend/app/models/review.rb b/app/backend/app/models/review.rb
index ce0be9d..a10b48d 100644
--- a/app/backend/app/models/review.rb
+++ b/app/backend/app/models/review.rb
@@ -1,72 +1,11 @@
-class Review
-  attr_accessor :review_id, :homeowner_id, :tradesman_id, :appointment_id, 
-                :rating, :comment, :timestamp
-  
-  def initialize(attributes = {})
-    @review_id = attributes[:review_id] || JsonStorage.generate_id
-    @homeowner_id = attributes[:homeowner_id]
-    @tradesman_id = attributes[:tradesman_id]
-    @appointment_id = attributes[:appointment_id]
-    @rating = attributes[:rating]
-    @comment = attributes[:comment]
-    @timestamp = attributes[:timestamp] || Time.now.utc.iso8601
-  end
-  
-  def self.all
-    data = JsonStorage.read('reviews')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def self.find_by_tradesman_id(tradesman_id)
-    all.select { |r| r.tradesman_id == tradesman_id }
-  end
-  
-  def save
-    reviews = self.class.all
-    existing_index = reviews.find_index { |r| r.review_id == @review_id }
-    
-    if existing_index
-      reviews[existing_index] = self
-    else
-      reviews << self
-    end
-    
-    # Update tradesman rating
-    update_tradesman_rating
-    
-    JsonStorage.write('reviews', reviews.map(&:to_hash))
-    self
-  end
-  
-  def update_tradesman_rating
-    tradesman_reviews = self.class.find_by_tradesman_id(@tradesman_id)
-    return if tradesman_reviews.empty?
-    
-    average_rating = tradesman_reviews.sum(&:rating).to_f / tradesman_reviews.size
-    tradesman = Tradesman.find_by_id(@tradesman_id)
-    if tradesman
-      tradesman.rating = average_rating.round(1)
-      tradesman.save
-    end
-  end
-  
-  def to_hash
-    {
-      review_id: @review_id,
-      homeowner_id: @homeowner_id,
-      tradesman_id: @tradesman_id,
-      appointment_id: @appointment_id,
-      rating: @rating,
-      comment: @comment,
-      timestamp: @timestamp
-    }
-  end
-  
-  def as_json(options = {})
-    to_hash.as_json(options)
-  end
-end
+class Review < ApplicationRecord
+  belongs_to :homeowner
+  belongs_to :tradesman
+  belongs_to :appointment, optional: true
+
+  validates :rating, presence: true, numericality: { in: 1..5 }
+  validates :comment, presence: true
 
+  # Note: Rating is calculated from reviews, not stored in tradesmen table
+  # Use tradesman.reviews.average(:rating) to get current rating
+end
diff --git a/app/backend/app/models/schedule.rb b/app/backend/app/models/schedule.rb
index 45676d0..94b4c7f 100644
--- a/app/backend/app/models/schedule.rb
+++ b/app/backend/app/models/schedule.rb
@@ -1,54 +1,8 @@
-class Schedule
-  attr_accessor :schedule_id, :tradesman_id, :date, :start_time, :end_time, :status
-  
-  def initialize(attributes = {})
-    @schedule_id = attributes[:schedule_id] || JsonStorage.generate_id
-    @tradesman_id = attributes[:tradesman_id]
-    @date = attributes[:date]
-    @start_time = attributes[:start_time]
-    @end_time = attributes[:end_time]
-    @status = attributes[:status] || 'available'
-  end
-  
-  def self.find_by_tradesman_id(tradesman_id)
-    all.select { |s| s.tradesman_id == tradesman_id }
-  end
-  
-  def self.all
-    data = JsonStorage.read('schedules')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def save
-    schedules = self.class.all
-    existing_index = schedules.find_index { |s| s.schedule_id == @schedule_id }
-    
-    if existing_index
-      schedules[existing_index] = self
-    else
-      schedules << self
-    end
-    
-    JsonStorage.write('schedules', schedules.map(&:to_hash))
-    self
-  end
-  
-  def to_hash
-    {
-      schedule_id: @schedule_id,
-      tradesman_id: @tradesman_id,
-      date: @date,
-      start_time: @start_time,
-      end_time: @end_time,
-      status: @status
-    }
-  end
-  
-  def as_json(options = {})
-    to_hash.as_json(options)
-  end
-end
+class Schedule < ApplicationRecord
+  belongs_to :tradesman
 
+  validates :date, presence: true
+  validates :start_time, presence: true
+  validates :end_time, presence: true
+  validates :status, inclusion: { in: %w[available booked unavailable] }
+end
diff --git a/app/backend/app/models/tradesman.rb b/app/backend/app/models/tradesman.rb
index e51d580..27eeb5c 100644
--- a/app/backend/app/models/tradesman.rb
+++ b/app/backend/app/models/tradesman.rb
@@ -1,75 +1,26 @@
-class Tradesman
-  attr_accessor :user_id, :name, :email, :trade, :rating, :license_number, 
-                :business_name, :experience, :location, :address, :profile
-  
-  def initialize(attributes = {})
-    @user_id = attributes[:user_id] || JsonStorage.generate_id
-    @name = attributes[:name]
-    @email = attributes[:email]
-    @trade = attributes[:trade]
-    @rating = attributes[:rating] || 0.0
-    @license_number = attributes[:license_number]
-    @business_name = attributes[:business_name]
-    @experience = attributes[:experience] || 0
-    @location = attributes[:location]
-    @address = attributes[:address]
-    @profile = attributes[:profile] || {}
-  end
-  
-  def self.all
-    data = JsonStorage.read('tradesmen')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def self.find_by_id(id)
-    all.find { |t| t.user_id == id }
-  end
-  
-  def self.find_by_trade_and_location(trade, location, name = nil)
-    all.select do |t|
-      matches_trade = trade.nil? || trade.empty? || t.trade&.downcase&.include?(trade.downcase)
-      matches_location = location.nil? || location.empty? || t.location&.downcase == location.downcase || 
-                         t.address&.downcase&.include?(location.downcase)
-      matches_name = name.nil? || name.empty? || t.name&.downcase&.include?(name.downcase)
-      matches_trade && matches_location && matches_name
-    end
-  end
-  
-  def save
-    tradesmen = self.class.all
-    existing_index = tradesmen.find_index { |t| t.user_id == @user_id }
-    
-    if existing_index
-      tradesmen[existing_index] = self
-    else
-      tradesmen << self
-    end
-    
-    JsonStorage.write('tradesmen', tradesmen.map(&:to_hash))
-    self
-  end
-  
-  def to_hash
-    {
-      user_id: @user_id,
-      name: @name,
-      email: @email,
-      trade: @trade,
-      rating: @rating,
-      license_number: @license_number,
-      business_name: @business_name,
-      experience: @experience,
-      location: @location,
-      address: @address,
-      profile: @profile
-    }
-  end
-  
-  def as_json(options = {})
-    to_hash.as_json(options)
+class Tradesman < ApplicationRecord
+  belongs_to :user
+
+  has_many :schedules, dependent: :destroy
+  has_many :appointments, dependent: :destroy
+  has_many :bids, dependent: :destroy
+  has_many :reviews, dependent: :destroy
+  has_many :estimates, dependent: :destroy
+  has_one :tradesman_verification, dependent: :destroy
+
+  validates :trade_specialty, inclusion: { in: %w[plumber electrician hvac\ worker] }, allow_nil: true
+  validates :verification_status, inclusion: { in: %w[pending approved rejected] }, allow_nil: true
+
+  # Scopes for filtering
+  scope :by_trade, ->(trade) { where(trade_specialty: trade) }
+  scope :by_location, ->(city) { where(city: city) }
+  # Note: by_rating scope would need a subquery since rating is calculated
+  # scope :by_rating, ->(min_rating) { joins(:reviews).group('tradesmen.id').having('AVG(reviews.rating) >= ?', min_rating) }
+  scope :verified, -> { where(verification_status: 'approved') }
+  scope :pending_verification, -> { where(verification_status: 'pending') }
+
+  # Calculate rating from reviews (virtual attribute)
+  def rating
+    reviews.average(:rating)&.round(1) || 0.0
   end
 end
-
diff --git a/app/backend/app/models/user.rb b/app/backend/app/models/user.rb
index 595e9af..3ae39ca 100644
--- a/app/backend/app/models/user.rb
+++ b/app/backend/app/models/user.rb
@@ -1,78 +1,27 @@
-class User
-  attr_accessor :user_id, :name, :email, :password_hash, :role, :address, :status, :profile
-  
-  def initialize(attributes = {})
-    @user_id = attributes[:user_id] || JsonStorage.generate_id
-    @name = attributes[:name]
-    @email = attributes[:email]
-    @password_hash = attributes[:password_hash]
-    @role = attributes[:role] # "homeowner" or "tradesman"
-    @address = attributes[:address]
-    @status = attributes[:status] || 'active'
-    @profile = attributes[:profile] || {}
-  end
-  
-  def self.all
-    data = JsonStorage.read('users')
-    data.map { |attrs| 
-      hash = attrs.is_a?(Hash) ? attrs : {}
-      new(hash.symbolize_keys)
-    }
-  end
-  
-  def self.find_by_id(id)
-    all.find { |u| u.user_id == id }
-  end
-  
+class User < ApplicationRecord
+  # Validations
+  validates :email, presence: true, uniqueness: true
+  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
+  validates :password_hash, presence: true
+  validates :role, presence: true, inclusion: { in: %w[homeowner tradesman contractor admin] }
+  validates :status, presence: true, inclusion: { in: %w[activated deactivated suspended] }
+
+  # Associations
+  has_one :homeowner, dependent: :destroy
+  has_one :contractor, dependent: :destroy
+  has_one :tradesman, dependent: :destroy
+  has_one :admin, dependent: :destroy
+  has_many :notifications, dependent: :destroy
+
+  # Class methods
   def self.find_by_email(email)
-    all.find { |u| u.email&.downcase == email&.downcase }
+    where('LOWER(email) = ?', email&.downcase).first
   end
-  
+
   def self.authenticate(email, password)
     user = find_by_email(email)
     return nil unless user
     return nil unless user.password_hash == password # Simple hash comparison - in production use bcrypt
     user
   end
-  
-  def save
-    users = self.class.all
-    existing_index = users.find_index { |u| u.user_id == @user_id }
-    
-    if existing_index
-      users[existing_index] = self
-    else
-      users << self
-    end
-    
-    JsonStorage.write('users', users.map(&:to_hash))
-    self
-  end
-  
-  def to_hash
-    {
-      user_id: @user_id,
-      name: @name,
-      email: @email,
-      password_hash: @password_hash,
-      role: @role,
-      address: @address,
-      status: @status,
-      profile: @profile
-    }
-  end
-  
-  def as_json(options = {})
-    hash = {
-      user_id: @user_id,
-      name: @name,
-      email: @email,
-      role: @role,
-      address: @address,
-      status: @status,
-      profile: @profile
-    }
-    hash.as_json(options)
-  end
 end
-
diff --git a/app/backend/app/views/home/index.html.erb b/app/backend/app/views/home/index.html.erb
index 8888e2f..f2f1116 100644
--- a/app/backend/app/views/home/index.html.erb
+++ b/app/backend/app/views/home/index.html.erb
@@ -241,9 +241,18 @@
     <nav class="container">
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/messages-page" id="messages-nav-link" style="display: none;" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
-        <li id="my-projects-link" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
-        <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="auth-button-container">
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -255,7 +264,7 @@
     <div class="container">
       <h1>Find Trusted Tradesmen Near You</h1>
       <p>Connect with licensed professionals for plumbing, electrical, HVAC, and more. Schedule appointments, get quotes, and read reviews all in one place.</p>
-      <button class="cta-button" onclick="openProfileModal()" style="border: none; cursor: pointer;">Get Started</button>
+      <button class="cta-button" onclick="handleGetStarted()" style="border: none; cursor: pointer;">Get Started</button>
     </div>
   </section>
   
@@ -349,6 +358,7 @@
       <div class="modal-body">
         <div class="role-selector" id="role-selector" style="display: none;">
           <button class="role-button active" onclick="selectRole('homeowner')">Homeowner</button>
+          <button class="role-button" onclick="selectRole('contractor')">Contractor</button>
           <button class="role-button" onclick="selectRole('tradesman')">Tradesman</button>
         </div>
         
@@ -377,10 +387,76 @@
             <label>Password</label>
             <input type="password" id="signup-password" required>
           </div>
-          <div class="form-group">
-            <label>Address</label>
-            <input type="text" id="signup-address" placeholder="123 Main St, City, ZIP">
+          
+          <!-- Homeowner/Contractor specific fields (shared) -->
+          <div id="homeowner-fields" style="display: none;">
+            <div class="form-group">
+              <label>Street Address</label>
+              <input type="text" id="signup-street" placeholder="123 Main St">
+            </div>
+            <div class="form-group">
+              <label>City</label>
+              <input type="text" id="signup-city" placeholder="City">
+            </div>
+            <div class="form-group">
+              <label>State</label>
+              <input type="text" id="signup-state" placeholder="State">
+            </div>
+            <div class="form-group">
+              <label>Phone Number</label>
+              <input type="tel" id="signup-number" placeholder="(555) 123-4567">
+            </div>
+          </div>
+          
+          <!-- Tradesman specific fields -->
+          <div id="tradesman-fields" style="display: none;">
+            <div class="form-group">
+              <label>Trade Specialty</label>
+              <select id="signup-trade-specialty" required>
+                <option value="">Select a trade</option>
+                <option value="plumber">Plumber</option>
+                <option value="electrician">Electrician</option>
+                <option value="hvac worker">HVAC Worker</option>
+              </select>
+            </div>
+            <div class="form-group">
+              <label>License Number</label>
+              <input type="text" id="signup-license-number" placeholder="License number">
+            </div>
+            <div class="form-group">
+              <label>Business Name</label>
+              <input type="text" id="signup-business-name" placeholder="Business name (optional)">
+            </div>
+            <div class="form-group">
+              <label>Years of Experience</label>
+              <input type="number" id="signup-years-experience" min="0" placeholder="Years">
+            </div>
+            <div class="form-group">
+              <label>Street Address</label>
+              <input type="text" id="signup-street" placeholder="123 Main St">
+            </div>
+            <div class="form-group">
+              <label>City</label>
+              <input type="text" id="signup-city" placeholder="City">
+            </div>
+            <div class="form-group">
+              <label>State</label>
+              <input type="text" id="signup-state" placeholder="State">
+            </div>
+            <div class="form-group">
+              <label>Phone Number</label>
+              <input type="tel" id="signup-number" placeholder="(555) 123-4567">
+            </div>
+            <div class="form-group">
+              <label>Hourly Rate ($)</label>
+              <input type="number" id="signup-hourly-rate" min="0" step="0.01" placeholder="50.00">
+            </div>
+            <div class="form-group">
+              <label>Service Radius (miles)</label>
+              <input type="number" id="signup-service-radius" min="0" step="0.1" placeholder="25.0">
+            </div>
           </div>
+          
           <button type="submit" class="submit-button">Sign Up</button>
         </form>
         
@@ -478,7 +554,8 @@
       color: #555;
     }
     
-    .form-group input {
+    .form-group input,
+    .form-group select {
       width: 100%;
       padding: 10px;
       border: 1px solid #ddd;
@@ -487,7 +564,8 @@
       box-sizing: border-box;
     }
     
-    .form-group input:focus {
+    .form-group input:focus,
+    .form-group select:focus {
       outline: none;
       border-color: #3498db;
     }
@@ -570,12 +648,30 @@
         document.getElementById('modal-title').textContent = 'Sign Up';
         document.getElementById('switch-text').textContent = 'Already have an account? ';
         document.getElementById('switch-link').textContent = 'Login';
+        updateSignupFields(); // Update fields when switching to signup
       }
     }
     
     function selectRole(role) {
       selectedRole = role;
       updateRoleButtons();
+      updateSignupFields();
+    }
+    
+    function updateSignupFields() {
+      const homeownerFields = document.getElementById('homeowner-fields');
+      const tradesmanFields = document.getElementById('tradesman-fields');
+      
+      if (selectedRole === 'homeowner' || selectedRole === 'contractor') {
+        if (homeownerFields) homeownerFields.style.display = 'block';
+        if (tradesmanFields) tradesmanFields.style.display = 'none';
+      } else if (selectedRole === 'tradesman') {
+        if (homeownerFields) homeownerFields.style.display = 'none';
+        if (tradesmanFields) tradesmanFields.style.display = 'block';
+      } else {
+        if (homeownerFields) homeownerFields.style.display = 'none';
+        if (tradesmanFields) tradesmanFields.style.display = 'none';
+      }
     }
     
     function updateRoleButtons() {
@@ -626,13 +722,37 @@
       const name = document.getElementById('signup-name').value;
       const email = document.getElementById('signup-email').value;
       const password = document.getElementById('signup-password').value;
-      const address = document.getElementById('signup-address').value;
+      
+      let signupData = {
+        name: name,
+        email: email,
+        password: password,
+        role: selectedRole
+      };
+      
+      if (selectedRole === 'homeowner' || selectedRole === 'contractor') {
+        signupData.street = document.getElementById('signup-street').value;
+        signupData.city = document.getElementById('signup-city').value;
+        signupData.state = document.getElementById('signup-state').value;
+        signupData.number = document.getElementById('signup-number').value;
+      } else if (selectedRole === 'tradesman') {
+        signupData.trade_specialty = document.getElementById('signup-trade-specialty').value;
+        signupData.license_number = document.getElementById('signup-license-number').value;
+        signupData.business_name = document.getElementById('signup-business-name').value;
+        signupData.years_of_experience = document.getElementById('signup-years-experience').value;
+        signupData.street = document.getElementById('signup-street').value;
+        signupData.city = document.getElementById('signup-city').value;
+        signupData.state = document.getElementById('signup-state').value;
+        signupData.number = document.getElementById('signup-number').value;
+        signupData.hourly_rate = document.getElementById('signup-hourly-rate').value;
+        signupData.service_radius = document.getElementById('signup-service-radius').value;
+      }
       
       try {
         const response = await fetch('/register', {
           method: 'POST',
           headers: { 'Content-Type': 'application/json' },
-          body: JSON.stringify({ name, email, password, role: selectedRole, address })
+          body: JSON.stringify(signupData)
         });
         
         const data = await response.json();
@@ -662,6 +782,8 @@
       const authButton = document.getElementById('auth-button');
       const manageProfileLink = document.getElementById('manage-profile-link');
       const myProjectsLink = document.getElementById('my-projects-link');
+      const createProjectLink = document.getElementById('create-project-link');
+      const projectsListingLink = document.getElementById('projects-listing-link');
       const messagesNavLink = document.getElementById('messages-nav-link');
       
       if (token) {
@@ -669,24 +791,17 @@
         if (manageProfileLink) {
           manageProfileLink.style.display = 'block';
         }
-        if (myProjectsLink && userRole === 'homeowner') {
-          myProjectsLink.style.display = 'block';
-        }
         if (messagesNavLink) {
           messagesNavLink.style.display = 'block';
           updateNavUnreadCount();
         }
+        
+        // Show role-specific navbar items
+        setupRoleBasedNavbar(userRole);
       } else {
         authButton.textContent = 'Login';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'none';
-        }
-        if (myProjectsLink) {
-          myProjectsLink.style.display = 'none';
-        }
-        if (messagesNavLink) {
-          messagesNavLink.style.display = 'none';
-        }
+        // Hide all navbar items when not logged in
+        setupRoleBasedNavbar(null);
       }
     }
     
@@ -718,6 +833,69 @@
       }
     }
     
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'contractor') {
+        // Contractor has same navbar as homeowner
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+        // For now, just show common items
+      }
+    }
+    
+    function handleGetStarted() {
+      const token = localStorage.getItem('access_token');
+      const userRole = localStorage.getItem('user_role');
+      
+      if (token && userRole) {
+        // User is logged in - redirect based on role
+        if (userRole === 'homeowner' || userRole === 'contractor') {
+          window.location.href = '/tradesmen-listing';
+        } else if (userRole === 'tradesman') {
+          window.location.href = '/projects-listing';
+        } else {
+          // For other roles, open modal
+          openProfileModal();
+        }
+      } else {
+        // User not logged in - open login modal
+        openProfileModal();
+      }
+    }
+    
     function handleAuthButtonClick() {
       const token = localStorage.getItem('access_token');
       if (token) {
diff --git a/app/backend/app/views/manage_profile/index.html.erb b/app/backend/app/views/manage_profile/index.html.erb
index e35eada..9c1d9b8 100644
--- a/app/backend/app/views/manage_profile/index.html.erb
+++ b/app/backend/app/views/manage_profile/index.html.erb
@@ -122,6 +122,15 @@
       font-size: 3em;
       color: white;
       flex-shrink: 0;
+      overflow: hidden;
+      background-size: cover;
+      background-position: center;
+    }
+    
+    .profile-image img {
+      width: 100%;
+      height: 100%;
+      object-fit: cover;
     }
     
     .profile-info {
@@ -234,10 +243,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" data-turbo="false">Connect with Servicemen</a></li>
-        <li><a href="/messages-page" data-turbo="false">Messages</a></li>
-        <li id="start-project-link" style="display: none;"><a href="/start-project" data-turbo="false">Start a Project</a></li>
-        <li><a href="/manage-profile" class="active" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" class="active" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="auth-button-container">
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -288,33 +305,60 @@
         
         <div class="action-buttons">
           <button class="btn btn-primary" onclick="editProfile()">Edit Profile</button>
-          <button class="btn btn-secondary" onclick="window.location.href='/tradesmen-listing'">Back to Home</button>
+          <button class="btn btn-secondary" onclick="goBack()">Back to Home</button>
         </div>
       </div>
     </div>
   </div>
   
   <script>
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+      }
+    }
+    
     function checkAuthAndLoadProfile() {
       const token = localStorage.getItem('access_token');
       const userRole = localStorage.getItem('user_role');
       const userEmail = localStorage.getItem('user_email');
       
       const authButton = document.getElementById('auth-button');
-      const manageProfileLink = document.getElementById('manage-profile-link');
-      const startProjectLink = document.getElementById('start-project-link');
       
       if (token) {
         // User is logged in
         authButton.textContent = 'Logout';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'block';
-        }
-        
-        // Show Start a Project only for homeowners
-        if (userRole === 'homeowner' && startProjectLink) {
-          startProjectLink.style.display = 'block';
-        }
+        setupRoleBasedNavbar(userRole);
         
         // Show profile container
         document.getElementById('profile-container').style.display = 'block';
@@ -324,13 +368,10 @@
       } else {
         // Not authenticated
         authButton.textContent = 'Login';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'none';
-        }
-        if (startProjectLink) {
-          startProjectLink.style.display = 'none';
-        }
+        setupRoleBasedNavbar(null);
+        
         document.getElementById('auth-required').style.display = 'block';
+        document.getElementById('profile-container').style.display = 'none';
       }
     }
     
@@ -339,39 +380,81 @@
         // Get user data from localStorage
         const userName = localStorage.getItem('user_name');
         const userId = localStorage.getItem('user_id');
+        const token = localStorage.getItem('access_token');
+        
+        // Set initial values from localStorage
+        const displayName = userName || (email ? email.split('@')[0] : 'User');
+        const displayEmail = email || 'Not available';
+        const displayRole = role ? role.charAt(0).toUpperCase() + role.slice(1) : 'User';
         
-        // Get initial from name or email
-        const initial = userName ? userName.charAt(0).toUpperCase() : (email ? email.charAt(0).toUpperCase() : '👤');
+        // Get initial from name or email for profile image
+        const initial = displayName ? displayName.charAt(0).toUpperCase() : (email ? email.charAt(0).toUpperCase() : '👤');
         document.getElementById('profile-image').textContent = initial;
         
-        // Set profile information from localStorage
-        document.getElementById('profile-name').textContent = userName || (email ? email.split('@')[0] : 'User');
-        document.getElementById('profile-email').textContent = email || 'Not available';
-        document.getElementById('profile-role').textContent = role || 'User';
-        document.getElementById('profile-type').textContent = role ? role.charAt(0).toUpperCase() + role.slice(1) : 'User';
+        // Set profile information from localStorage (will be updated from API if available)
+        document.getElementById('profile-name').textContent = displayName;
+        document.getElementById('profile-email').textContent = displayEmail;
+        document.getElementById('profile-role').textContent = displayRole;
+        document.getElementById('profile-type').textContent = displayRole;
         
-        // Try to fetch additional profile data from API if available
-        const token = localStorage.getItem('access_token');
+        // Fetch profile data from API
         if (userId && token) {
           try {
             const response = await fetch(`/profile/${userId}`, {
               headers: {
-                'Authorization': `Bearer ${token}`
+                'Authorization': `Bearer ${token}`,
+                'Content-Type': 'application/json'
               }
             });
             
             if (response.ok) {
               const data = await response.json();
+              
+              // Update name
               if (data.name) {
                 document.getElementById('profile-name').textContent = data.name;
                 localStorage.setItem('user_name', data.name);
+                // Update initial
+                const newInitial = data.name.charAt(0).toUpperCase();
+                const profileImageEl = document.getElementById('profile-image');
+                // Clear any existing image
+                profileImageEl.innerHTML = '';
+                profileImageEl.textContent = newInitial;
+              }
+              
+              // Update profile photo if available
+              if (data.profile && data.profile.photo_url) {
+                const profileImageEl = document.getElementById('profile-image');
+                profileImageEl.innerHTML = `<img src="${data.profile.photo_url}" alt="Profile Photo">`;
               }
+              
+              // Update email
               if (data.email) {
                 document.getElementById('profile-email').textContent = data.email;
               }
+              
+              // Update role
+              if (data.role) {
+                const roleDisplay = data.role.charAt(0).toUpperCase() + data.role.slice(1);
+                document.getElementById('profile-role').textContent = roleDisplay;
+                document.getElementById('profile-type').textContent = roleDisplay;
+              }
+              
+              // Add role-specific profile details
+              if (data.profile) {
+                addProfileDetails(data.profile, data.role);
+              }
+              
+              // Add address if available
+              if (data.address) {
+                addDetailRow('Address', data.address);
+              }
+            } else {
+              const errorData = await response.json().catch(() => ({}));
+              console.error('Failed to fetch profile:', errorData.error || 'Unknown error');
             }
           } catch (apiError) {
-            console.log('Could not fetch additional profile data:', apiError);
+            console.error('Error fetching profile data:', apiError);
             // Continue with localStorage data
           }
         }
@@ -384,6 +467,72 @@
       }
     }
     
+    function addProfileDetails(profile, role) {
+      const detailsContainer = document.querySelector('.profile-details');
+      
+      // Remove existing role-specific details (keep Email, Account Type, Status)
+      const existingRows = Array.from(detailsContainer.querySelectorAll('.detail-row'));
+      // Keep first 3 rows (Email, Account Type, Status), remove the rest
+      existingRows.slice(3).forEach(row => row.remove());
+      
+      // Add role-specific details
+      if (role === 'tradesman') {
+        if (profile.business_name) {
+          addDetailRow('Business Name', profile.business_name);
+        }
+        if (profile.trade_specialty) {
+          addDetailRow('Trade Specialty', profile.trade_specialty);
+        }
+        if (profile.license_number) {
+          addDetailRow('License Number', profile.license_number);
+        }
+        if (profile.years_of_experience !== undefined && profile.years_of_experience !== null) {
+          addDetailRow('Years of Experience', profile.years_of_experience);
+        }
+        if (profile.rating !== undefined && profile.rating !== null) {
+          addDetailRow('Rating', profile.rating.toFixed(1) + ' / 5.0');
+        }
+        if (profile.hourly_rate !== undefined && profile.hourly_rate !== null) {
+          addDetailRow('Hourly Rate', '$' + profile.hourly_rate.toFixed(2));
+        }
+        if (profile.service_radius !== undefined && profile.service_radius !== null) {
+          addDetailRow('Service Radius', profile.service_radius + ' miles');
+        }
+        if (profile.verification_status) {
+          addDetailRow('Verification Status', profile.verification_status.charAt(0).toUpperCase() + profile.verification_status.slice(1));
+        }
+      } else if (role === 'contractor' || role === 'homeowner') {
+        if (profile.fname || profile.lname) {
+          const fullName = [profile.fname, profile.lname].filter(Boolean).join(' ');
+          if (fullName) {
+            addDetailRow('Full Name', fullName);
+          }
+        }
+      }
+      
+      // Add address details if available
+      if (profile.street || profile.city || profile.state) {
+        const addressParts = [profile.street, profile.city, profile.state].filter(Boolean);
+        if (addressParts.length > 0) {
+          addDetailRow('Address', addressParts.join(', '));
+        }
+      }
+      if (profile.number) {
+        addDetailRow('Phone Number', profile.number);
+      }
+    }
+    
+    function addDetailRow(label, value) {
+      const detailsContainer = document.querySelector('.profile-details');
+      const detailRow = document.createElement('div');
+      detailRow.className = 'detail-row';
+      detailRow.innerHTML = `
+        <div class="detail-label">${label}</div>
+        <div class="detail-value">${value || 'Not provided'}</div>
+      `;
+      detailsContainer.appendChild(detailRow);
+    }
+    
     function handleAuthButtonClick() {
       const token = localStorage.getItem('access_token');
       if (token) {
@@ -405,6 +554,17 @@
       alert('Edit profile functionality coming soon!');
     }
     
+    function goBack() {
+      const userRole = localStorage.getItem('user_role');
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        window.location.href = '/tradesmen-listing';
+      } else if (userRole === 'tradesman') {
+        window.location.href = '/projects-listing';
+      } else {
+        window.location.href = '/';
+      }
+    }
+    
     // Run on page load
     checkAuthAndLoadProfile();
   </script>
diff --git a/app/backend/app/views/messages/index.html.erb b/app/backend/app/views/messages/index.html.erb
index 43ff601..453c58e 100644
--- a/app/backend/app/views/messages/index.html.erb
+++ b/app/backend/app/views/messages/index.html.erb
@@ -465,10 +465,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
-        <li><a href="/messages-page" data-turbo="false" id="messages-nav-link">Messages <span id="nav-unread-badge" style="display: none;" class="unread-badge">0</span></a></li>
-        <li id="my-projects-link" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
-        <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false" class="active">Messages <span id="nav-unread-badge" style="display: none;" class="unread-badge">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li>
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -558,10 +566,47 @@
       setTimeout(initializeActionCable, 100);
     });
     
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+      }
+    }
+    
     function checkAuthStatus() {
       const userId = localStorage.getItem('user_id');
       const userName = localStorage.getItem('user_name');
       const token = localStorage.getItem('access_token');
+      const userRole = localStorage.getItem('user_role');
       
       if (!userId || !token) {
         alert('Please login to access messages');
@@ -578,11 +623,8 @@
         authButton.textContent = 'Logout';
       }
       
-      // Show user-specific nav items
-      const manageProfileLink = document.getElementById('manage-profile-link');
-      const myProjectsLink = document.getElementById('my-projects-link');
-      if (manageProfileLink) manageProfileLink.style.display = 'block';
-      if (myProjectsLink) myProjectsLink.style.display = 'block';
+      // Setup role-based navbar
+      setupRoleBasedNavbar(userRole);
       
       // Load conversations
       loadConversations();
diff --git a/app/backend/app/views/projects/index.html.erb b/app/backend/app/views/projects/index.html.erb
index c5ed242..a70aba9 100644
--- a/app/backend/app/views/projects/index.html.erb
+++ b/app/backend/app/views/projects/index.html.erb
@@ -289,10 +289,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" data-turbo="false">Connect with Servicemen</a></li>
-        <li><a href="/messages-page" data-turbo="false">Messages</a></li>
-        <li><a href="/my-projects" class="active" data-turbo="false">My Projects</a></li>
-        <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" class="active" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="auth-button-container">
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -338,33 +346,63 @@
       const userId = localStorage.getItem('user_id');
       
       const authButton = document.getElementById('auth-button');
-      const manageProfileLink = document.getElementById('manage-profile-link');
       
-      if (token && userRole === 'homeowner') {
+      // Update navbar based on role
+      if (token) {
         authButton.textContent = 'Logout';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'block';
-        }
+        setupRoleBasedNavbar(userRole);
+      } else {
+        authButton.textContent = 'Login';
+        setupRoleBasedNavbar(null);
+      }
+      
+      function setupRoleBasedNavbar(userRole) {
+        // Hide all role-specific nav items first
+        const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+        const tradesmanNavItems = ['tradesman-nav-projects'];
+        const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+        
+        // Hide all
+        [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'none';
+        });
         
+        if (!userRole) return; // Not logged in
+        
+        // Show common items for all logged-in users
+        commonNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+        
+        // Show role-specific items
+        if (userRole === 'homeowner' || userRole === 'contractor') {
+          homeownerNavItems.forEach(id => {
+            const el = document.getElementById(id);
+            if (el) el.style.display = 'block';
+          });
+        } else if (userRole === 'tradesman') {
+          tradesmanNavItems.forEach(id => {
+            const el = document.getElementById(id);
+            if (el) el.style.display = 'block';
+          });
+        } else if (userRole === 'admin') {
+          // Admin navbar - can add admin-specific items here if needed
+        }
+      }
+      
+      if (token && userRole === 'homeowner') {
         document.getElementById('content').style.display = 'block';
         loadProjects(userId);
       } else if (token && userRole !== 'homeowner') {
         document.getElementById('auth-required').innerHTML = `
           <h2>Access Restricted</h2>
           <p>Only homeowners can view and create projects. You are logged in as a ${userRole}.</p>
-          <button onclick="window.location.href='/tradesmen-listing'">Browse Tradesmen</button>
+          <button onclick="window.location.href='/projects-listing'">Browse Projects</button>
         `;
         document.getElementById('auth-required').style.display = 'block';
-        
-        authButton.textContent = 'Logout';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'block';
-        }
       } else {
-        authButton.textContent = 'Login';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'none';
-        }
         document.getElementById('auth-required').style.display = 'block';
       }
     }
diff --git a/app/backend/app/views/projects/new.html.erb b/app/backend/app/views/projects/new.html.erb
index 429ea15..70434ec 100644
--- a/app/backend/app/views/projects/new.html.erb
+++ b/app/backend/app/views/projects/new.html.erb
@@ -209,8 +209,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" data-turbo="false">Connect with Servicemen</a></li>
-        <li><a href="/messages-page" data-turbo="false">Messages</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="start-project-link" style="display: none;"><a href="/start-project" class="active" data-turbo="false">Start a Project</a></li>
         <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
         <li id="auth-button-container">
@@ -291,6 +301,42 @@
     let isAuthenticated = false;
     let userRole = null;
     
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+      }
+    }
+    
     // Check authentication status
     function checkAuthStatus() {
       const token = localStorage.getItem('access_token');
@@ -303,18 +349,19 @@
         isAuthenticated = true;
         authButton.textContent = 'Logout';
         authButton.onclick = handleAuthButtonClick;
-        manageProfileLink.style.display = 'block';
         
-        // Show Start a Project link only for homeowners
-        if (userRole === 'homeowner') {
-          startProjectLink.style.display = 'block';
+        // Setup role-based navbar
+        setupRoleBasedNavbar(userRole);
+        
+        // Show Start a Project form only for homeowners and contractors
+        if (userRole === 'homeowner' || userRole === 'contractor') {
           document.getElementById('project-form-container').style.display = 'block';
         } else {
-          // Not a homeowner
+          // Not a homeowner or contractor
           document.getElementById('auth-required').style.display = 'block';
           document.getElementById('auth-required').innerHTML = `
             <h2>Access Restricted</h2>
-            <p>Only homeowners can start projects. You are logged in as a ${userRole}.</p>
+            <p>Only homeowners and contractors can start projects. You are logged in as a ${userRole}.</p>
             <button onclick="window.location.href='/tradesmen-listing'">Browse Tradesmen</button>
           `;
         }
@@ -322,8 +369,7 @@
         // Not authenticated
         authButton.textContent = 'Login';
         authButton.onclick = function() { window.location.href = '/'; };
-        manageProfileLink.style.display = 'none';
-        startProjectLink.style.display = 'none';
+        setupRoleBasedNavbar(null);
         document.getElementById('auth-required').style.display = 'block';
       }
     }
diff --git a/app/backend/app/views/projects/show.html.erb b/app/backend/app/views/projects/show.html.erb
index 1544920..1ab4c48 100644
--- a/app/backend/app/views/projects/show.html.erb
+++ b/app/backend/app/views/projects/show.html.erb
@@ -275,10 +275,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" data-turbo="false">Connect with Servicemen</a></li>
-        <li><a href="/messages-page" data-turbo="false">Messages</a></li>
-        <li><a href="/my-projects" data-turbo="false">My Projects</a></li>
-        <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="auth-button-container">
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -356,18 +364,51 @@
   </div>
   
   <script>
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+      }
+    }
+    
     function checkAuthAndLoadProject() {
       const token = localStorage.getItem('access_token');
       const userRole = localStorage.getItem('user_role');
       
       const authButton = document.getElementById('auth-button');
-      const manageProfileLink = document.getElementById('manage-profile-link');
       
       if (token) {
         authButton.textContent = 'Logout';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'block';
-        }
+        setupRoleBasedNavbar(userRole);
         
         // Get project ID from URL
         const pathParts = window.location.pathname.split('/');
@@ -376,6 +417,7 @@
         loadProject(projectId);
       } else {
         authButton.textContent = 'Login';
+        setupRoleBasedNavbar(null);
         window.location.href = '/';
       }
     }
diff --git a/app/backend/app/views/tradesman_profiles/show.html.erb b/app/backend/app/views/tradesman_profiles/show.html.erb
index 32129d7..c943231 100644
--- a/app/backend/app/views/tradesman_profiles/show.html.erb
+++ b/app/backend/app/views/tradesman_profiles/show.html.erb
@@ -234,11 +234,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" data-turbo="false">Connect with Servicemen</a></li>
-        <li><a href="/messages-page" data-turbo="false">Messages</a></li>
-        <li id="start-project-link" style="display: none;"><a href="/start-project" data-turbo="false">Start a Project</a></li>
-        <li id="my-projects-link" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
-        <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="auth-button-container">
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -726,40 +733,53 @@
     });
     
     // Check authentication status on page load
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+      }
+    }
+    
     function checkAuthStatus() {
       const token = localStorage.getItem('access_token');
       const userRole = localStorage.getItem('user_role');
       const authButton = document.getElementById('auth-button');
-      const manageProfileLink = document.getElementById('manage-profile-link');
-      const startProjectLink = document.getElementById('start-project-link');
-      const myProjectsLink = document.getElementById('my-projects-link');
       
       if (token) {
         authButton.textContent = 'Logout';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'block';
-        }
-        
-        // Show Start a Project and My Projects only for homeowners
-        if (userRole === 'homeowner') {
-          if (startProjectLink) {
-            startProjectLink.style.display = 'block';
-          }
-          if (myProjectsLink) {
-            myProjectsLink.style.display = 'block';
-          }
-        }
+        setupRoleBasedNavbar(userRole);
       } else {
         authButton.textContent = 'Login';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'none';
-        }
-        if (startProjectLink) {
-          startProjectLink.style.display = 'none';
-        }
-        if (myProjectsLink) {
-          myProjectsLink.style.display = 'none';
-        }
+        setupRoleBasedNavbar(null);
       }
     }
     
diff --git a/app/backend/app/views/tradesmen_listing/index.html.erb b/app/backend/app/views/tradesmen_listing/index.html.erb
index 26331f3..31cff4b 100644
--- a/app/backend/app/views/tradesmen_listing/index.html.erb
+++ b/app/backend/app/views/tradesmen_listing/index.html.erb
@@ -319,11 +319,18 @@
     <nav>
       <a href="/" class="logo" style="text-decoration: none; color: #2c3e50;">Workfinder</a>
       <ul class="nav-links">
-        <li><a href="/tradesmen-listing" class="active" data-turbo="false">Connect with Servicemen</a></li>
-        <li><a href="/messages-page" id="messages-nav-link" style="display: none;" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
-        <li id="start-project-link" style="display: none;"><a href="/start-project" data-turbo="false">Start a Project</a></li>
-        <li id="my-projects-link" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
-        <li><a href="/manage-profile" id="manage-profile-link" style="display: none;" data-turbo="false">Manage Profile</a></li>
+        <!-- Homeowner/Contractor Navbar -->
+        <li id="homeowner-nav-find-tradesmen" style="display: none;"><a href="/tradesmen-listing" class="active" data-turbo="false">Find Tradesmen</a></li>
+        <li id="homeowner-nav-my-projects" style="display: none;"><a href="/my-projects" data-turbo="false">My Projects</a></li>
+        
+        <!-- Tradesman Navbar -->
+        <li id="tradesman-nav-projects" style="display: none;"><a href="/projects-listing" data-turbo="false">Projects</a></li>
+        
+        <!-- Common for all roles -->
+        <li id="nav-messages" style="display: none;"><a href="/messages-page" data-turbo="false">Messages <span id="nav-unread-badge" style="display: none; background-color: #2c3e50; color: white; border-radius: 12px; padding: 2px 8px; font-size: 0.75em; margin-left: 5px;">0</span></a></li>
+        <li id="nav-manage-profile" style="display: none;"><a href="/manage-profile" data-turbo="false">Manage Profile</a></li>
+        
+        <!-- Logout button -->
         <li id="auth-button-container">
           <button class="nav-button" onclick="handleAuthButtonClick()" id="auth-button">Login</button>
         </li>
@@ -660,41 +667,54 @@
     // Initial load
     checkAuthAndLoad();
     
+    function setupRoleBasedNavbar(userRole) {
+      // Hide all role-specific nav items first
+      const homeownerNavItems = ['homeowner-nav-find-tradesmen', 'homeowner-nav-my-projects'];
+      const tradesmanNavItems = ['tradesman-nav-projects'];
+      const commonNavItems = ['nav-messages', 'nav-manage-profile'];
+      
+      // Hide all
+      [...homeownerNavItems, ...tradesmanNavItems, ...commonNavItems].forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'none';
+      });
+      
+      if (!userRole) return; // Not logged in
+      
+      // Show common items for all logged-in users
+      commonNavItems.forEach(id => {
+        const el = document.getElementById(id);
+        if (el) el.style.display = 'block';
+      });
+      
+      // Show role-specific items
+      if (userRole === 'homeowner' || userRole === 'contractor') {
+        homeownerNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'tradesman') {
+        tradesmanNavItems.forEach(id => {
+          const el = document.getElementById(id);
+          if (el) el.style.display = 'block';
+        });
+      } else if (userRole === 'admin') {
+        // Admin navbar - can add admin-specific items here if needed
+      }
+    }
+    
     // Check authentication status on page load
     function checkAuthStatus() {
       const token = localStorage.getItem('access_token');
       const userRole = localStorage.getItem('user_role');
       const authButton = document.getElementById('auth-button');
-      const manageProfileLink = document.getElementById('manage-profile-link');
-      const startProjectLink = document.getElementById('start-project-link');
-      const myProjectsLink = document.getElementById('my-projects-link');
       
       if (token) {
         authButton.textContent = 'Logout';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'block';
-        }
-        
-        // Show Start a Project and My Projects only for homeowners
-        if (userRole === 'homeowner') {
-          if (startProjectLink) {
-            startProjectLink.style.display = 'block';
-          }
-          if (myProjectsLink) {
-            myProjectsLink.style.display = 'block';
-          }
-        }
+        setupRoleBasedNavbar(userRole);
       } else {
         authButton.textContent = 'Login';
-        if (manageProfileLink) {
-          manageProfileLink.style.display = 'none';
-        }
-        if (startProjectLink) {
-          startProjectLink.style.display = 'none';
-        }
-        if (myProjectsLink) {
-          myProjectsLink.style.display = 'none';
-        }
+        setupRoleBasedNavbar(null);
       }
     }
     
diff --git a/app/backend/config/database.yml b/app/backend/config/database.yml
index 693252b..5c16fe6 100644
--- a/app/backend/config/database.yml
+++ b/app/backend/config/database.yml
@@ -4,11 +4,21 @@
 #   Ensure the SQLite 3 gem is defined in your Gemfile
 #   gem "sqlite3"
 #
+# Environment-based database selection:
+# - Development: storage/development.sqlite3 (default)
+# - Production: storage/production.sqlite3 (when RAILS_ENV=production or APP_ENV=production in .env)
+#
 default: &default
   adapter: sqlite3
   max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
   timeout: 5000
 
+# Check for production environment from .env file or RAILS_ENV
+<% 
+  is_production = ENV['RAILS_ENV'] == 'production' || ENV['APP_ENV'] == 'production'
+  db_env = is_production ? 'production' : 'development'
+%>
+
 development:
   <<: *default
   database: storage/development.sqlite3
@@ -20,22 +30,9 @@ test:
   <<: *default
   database: storage/test.sqlite3
 
-
 # Store production database in the storage/ directory, which by default
 # is mounted as a persistent Docker volume in config/deploy.yml.
+# Production database is used when RAILS_ENV=production or APP_ENV=production in .env
 production:
-  primary:
-    <<: *default
-    database: storage/production.sqlite3
-  cache:
-    <<: *default
-    database: storage/production_cache.sqlite3
-    migrations_paths: db/cache_migrate
-  queue:
-    <<: *default
-    database: storage/production_queue.sqlite3
-    migrations_paths: db/queue_migrate
-  cable:
-    <<: *default
-    database: storage/production_cable.sqlite3
-    migrations_paths: db/cable_migrate
+  <<: *default
+  database: storage/production.sqlite3
diff --git a/app/backend/config/recurring.yml b/app/backend/config/recurring.yml
index b4207f9..32b28a0 100644
--- a/app/backend/config/recurring.yml
+++ b/app/backend/config/recurring.yml
@@ -13,3 +13,13 @@ production:
   clear_solid_queue_finished_jobs:
     command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
     schedule: every hour at minute 12
+  
+  appointment_reminders:
+    class: DailyAppointmentRemindersJob
+    queue: default
+    schedule: every day at 9am
+
+development:
+  clear_solid_queue_finished_jobs:
+    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
+    schedule: every hour at minute 12
\ No newline at end of file
diff --git a/app/backend/config/routes.rb b/app/backend/config/routes.rb
index c348e90..5373373 100644
--- a/app/backend/config/routes.rb
+++ b/app/backend/config/routes.rb
@@ -16,8 +16,15 @@ Rails.application.routes.draw do
   # Tradesman Availability & Scheduling
   get "tradesmen" => "tradesmen#index"
   get "tradesmen/:id" => "tradesmen#show", as: :tradesman_api
+  get "api/tradesmen/compare" => "tradesmen#compare", as: :api_compare_tradesmen
   get "tradesman/:id/schedule" => "schedules#show", as: :tradesman_schedule
+  post "tradesman/:id/schedule" => "schedules#create", as: :create_schedule
+  post "tradesman/:id/schedule/bulk" => "schedules#bulk_create", as: :bulk_create_schedules
+  put "schedules/:id" => "schedules#update", as: :update_schedule
+  delete "schedules/:id" => "schedules#destroy", as: :delete_schedule
   post "appointments" => "appointments#create"
+  put "appointments/:id/accept" => "appointments#accept", as: :accept_appointment
+  put "appointments/:id/reject" => "appointments#reject", as: :reject_appointment
   put "appointments/:id/cancel" => "appointments#cancel", as: :cancel_appointment
   
   # Messaging
@@ -40,14 +47,72 @@ Rails.application.routes.draw do
   get "tradesman/:id/profile" => "tradesman_profiles#show", as: :tradesman_profile
   get "start-project" => "projects#new", as: :new_project
   get "my-projects" => "projects#index", as: :my_projects
+  get "projects-listing" => "projects#listing", as: :projects_listing
   get "projects/:id" => "projects#show", as: :project_details_page
   post "projects" => "projects#create", as: :create_project
   get "manage-profile" => "manage_profile#index", as: :manage_profile
   
   # API Routes for projects
+  # IMPORTANT: More specific routes must come before parameterized routes
+  get "api/projects/search" => "api/projects#search", as: :api_projects_search
   get "api/projects/user/:user_id" => "projects#user_projects", as: :api_user_projects
   get "api/projects/:id" => "projects#project_details", as: :api_project_details
   
+  # Bids API
+  post "api/projects/:project_id/bids" => "api/bids#create", as: :api_create_bid
+  get "api/projects/:project_id/bids" => "api/bids#index", as: :api_project_bids
+  get "api/tradesmen/:tradesman_id/bids" => "api/bids#index", as: :api_tradesman_bids
+  get "api/bids/:id" => "api/bids#show", as: :api_bid
+  put "api/bids/:id" => "api/bids#update", as: :api_update_bid
+  post "api/projects/:project_id/bids/:bid_id/accept" => "api/bids#accept", as: :api_accept_bid
+  post "api/projects/:project_id/bids/:bid_id/reject" => "api/bids#reject", as: :api_reject_bid
+  
+  # Estimates API
+  post "api/appointments/:appointment_id/estimates" => "api/estimates#create", as: :api_create_appointment_estimate
+  post "api/projects/:project_id/estimates" => "api/estimates#create", as: :api_create_project_estimate
+  get "api/estimates" => "api/estimates#index", as: :api_estimates
+  get "api/estimates/:id" => "api/estimates#show", as: :api_estimate
+  get "api/estimates/:id/history" => "api/estimates#history", as: :api_estimate_history
+  put "api/estimates/:id" => "api/estimates#update", as: :api_update_estimate
+  post "api/estimates/:id/accept" => "api/estimates#accept", as: :api_accept_estimate
+  post "api/estimates/:id/reject" => "api/estimates#reject", as: :api_reject_estimate
+  
+  # Notifications API
+  get "api/notifications" => "api/notifications#index", as: :api_notifications
+  get "api/notifications/:id" => "api/notifications#show", as: :api_notification
+  put "api/notifications/:id/read" => "api/notifications#mark_read", as: :mark_notification_read
+  put "api/notifications/mark-all-read" => "api/notifications#mark_all_read", as: :mark_all_notifications_read
+  get "api/notifications/unread-count" => "api/notifications#unread_count", as: :api_notifications_unread_count
+  
+  # Admin API
+  get "api/admin/dashboard" => "api/admin#dashboard", as: :api_admin_dashboard
+  get "api/admin/users" => "api/admin/users#index", as: :api_admin_users
+  get "api/admin/users/search" => "api/admin/users#search", as: :api_admin_users_search
+  get "api/admin/users/:id" => "api/admin/users#show", as: :api_admin_user
+  put "api/admin/users/:id/suspend" => "api/admin/users#suspend", as: :api_admin_suspend_user
+  put "api/admin/users/:id/activate" => "api/admin/users#activate", as: :api_admin_activate_user
+  get "api/admin/tradesman-verifications" => "api/admin/tradesman_verifications#index", as: :api_admin_tradesman_verifications
+  get "api/admin/tradesman-verifications/:id" => "api/admin/tradesman_verifications#show", as: :api_admin_tradesman_verification
+  post "api/admin/tradesman-verifications/:id/approve" => "api/admin/tradesman_verifications#approve", as: :api_admin_approve_verification
+  post "api/admin/tradesman-verifications/:id/reject" => "api/admin/tradesman_verifications#reject", as: :api_admin_reject_verification
+  
+  # 2FA Setup
+  post "auth/setup-2fa" => "auth#setup_2fa", as: :setup_2fa
+  post "auth/verify-2fa" => "auth#verify_2fa", as: :verify_2fa
+  
+  # Tradesman Profile Updates
+  put "api/tradesman/profile" => "api/tradesman_profiles#update", as: :update_tradesman_profile
+  
+  # Project Management
+  put "api/projects/:id" => "projects#update", as: :api_update_project
+  post "api/projects/:id/publish" => "projects#publish", as: :api_publish_project
+  
+  # Contractor Dashboard
+  get "api/contractors/:id/dashboard" => "api/contractors#dashboard", as: :api_contractor_dashboard
+  
+  # Account Deletion
+  delete "api/accounts/:id" => "api/accounts#destroy", as: :api_delete_account
+  
   # Defines the root path route ("/")
   root "home#index"
 end
diff --git a/app/backend/db/seeds.rb b/app/backend/db/seeds.rb
index 4fbd6ed..f7b9cd7 100644
--- a/app/backend/db/seeds.rb
+++ b/app/backend/db/seeds.rb
@@ -7,3 +7,529 @@
 #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
 #     MovieGenre.find_or_create_by!(name: genre_name)
 #   end
+
+# Clear existing data (optional - comment out if you want to preserve existing data)
+puts "Clearing existing data..."
+# Destroy in order to respect foreign key constraints
+[Notification, Message, Conversation, Estimate, Bid, Appointment, Schedule, Review, Project, TradesmanVerification, Tradesman, Contractor, Homeowner, Admin, User].each do |model|
+  begin
+    model.destroy_all
+  rescue => e
+    puts "  Warning: Could not destroy #{model.name}: #{e.message}"
+  end
+end
+
+puts "Creating sample data..."
+
+# ============================================
+# USERS
+# ============================================
+
+# Homeowners
+homeowner_users = [
+  { email: "john.doe@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
+  { email: "jane.smith@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
+  { email: "bob.wilson@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
+  { email: "alice.brown@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
+  { email: "charlie.davis@example.com", password_hash: "password123", role: "homeowner", status: "activated" }
+]
+
+# Tradesmen
+tradesman_users = [
+  { email: "mike.plumber@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
+  { email: "sarah.electrician@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
+  { email: "tom.hvac@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
+  { email: "lisa.plumber@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
+  { email: "david.electrician@example.com", password_hash: "password123", role: "tradesman", status: "activated" }
+]
+
+# Contractors
+contractor_users = [
+  { email: "contractor1@example.com", password_hash: "password123", role: "contractor", status: "activated" },
+  { email: "contractor2@example.com", password_hash: "password123", role: "contractor", status: "activated" }
+]
+
+# Admin
+admin_users = [
+  { email: "admin@example.com", password_hash: "admin123", role: "admin", status: "activated" }
+]
+
+# Suspended user (for testing)
+suspended_user = { email: "suspended@example.com", password_hash: "password123", role: "homeowner", status: "suspended" }
+
+all_users = []
+puts "Creating users..."
+
+# Create homeowners
+homeowner_profiles = [
+  { fname: "John", lname: "Doe", street: "123 Main St", city: "Boston", state: "MA", number: "555-0101" },
+  { fname: "Jane", lname: "Smith", street: "456 Oak Ave", city: "Cambridge", state: "MA", number: "555-0102" },
+  { fname: "Bob", lname: "Wilson", street: "789 Pine Rd", city: "Somerville", state: "MA", number: "555-0103" },
+  { fname: "Alice", lname: "Brown", street: "321 Elm St", city: "Boston", state: "MA", number: "555-0104" },
+  { fname: "Charlie", lname: "Davis", street: "654 Maple Dr", city: "Cambridge", state: "MA", number: "555-0105" }
+]
+
+homeowner_users.each_with_index do |user_data, index|
+  user = User.create!(user_data)
+  all_users << user
+  Homeowner.create!(
+    user: user,
+    fname: homeowner_profiles[index][:fname],
+    lname: homeowner_profiles[index][:lname],
+    street: homeowner_profiles[index][:street],
+    city: homeowner_profiles[index][:city],
+    state: homeowner_profiles[index][:state],
+    number: homeowner_profiles[index][:number],
+    latitude: 42.3601 + (rand - 0.5) * 0.1, # Boston area coordinates
+    longitude: -71.0589 + (rand - 0.5) * 0.1
+  )
+end
+
+# Create tradesmen
+tradesman_profiles = [
+  { fname: "Mike", lname: "Johnson", trade_specialty: "plumber", business_name: "Mike's Plumbing", license_number: "PL-12345", years_of_experience: 10, hourly_rate: 75.0, service_radius: 25.0, city: "Boston", state: "MA", street: "100 Trade St", number: "555-0201", verification_status: "approved" },
+  { fname: "Sarah", lname: "Williams", trade_specialty: "electrician", business_name: "Sarah's Electrical", license_number: "EL-23456", years_of_experience: 8, hourly_rate: 85.0, service_radius: 30.0, city: "Cambridge", state: "MA", street: "200 Wire Ave", number: "555-0202", verification_status: "approved" },
+  { fname: "Tom", lname: "Anderson", trade_specialty: "hvac worker", business_name: "Tom's HVAC Services", license_number: "HV-34567", years_of_experience: 12, hourly_rate: 80.0, service_radius: 35.0, city: "Somerville", state: "MA", street: "300 Air Way", number: "555-0203", verification_status: "approved" },
+  { fname: "Lisa", lname: "Martinez", trade_specialty: "plumber", business_name: "Lisa's Plumbing Co", license_number: "PL-45678", years_of_experience: 6, hourly_rate: 70.0, service_radius: 20.0, city: "Boston", state: "MA", street: "400 Pipe Ln", number: "555-0204", verification_status: "approved" },
+  { fname: "David", lname: "Taylor", trade_specialty: "electrician", business_name: "David's Electric", license_number: "EL-56789", years_of_experience: 5, hourly_rate: 75.0, service_radius: 25.0, city: "Cambridge", state: "MA", street: "500 Circuit Blvd", number: "555-0205", verification_status: "pending" }
+]
+
+tradesman_users.each_with_index do |user_data, index|
+  user = User.create!(user_data)
+  all_users << user
+  tradesman = Tradesman.create!(
+    user: user,
+    fname: tradesman_profiles[index][:fname],
+    lname: tradesman_profiles[index][:lname],
+    trade_specialty: tradesman_profiles[index][:trade_specialty],
+    business_name: tradesman_profiles[index][:business_name],
+    license_number: tradesman_profiles[index][:license_number],
+    years_of_experience: tradesman_profiles[index][:years_of_experience],
+    hourly_rate: tradesman_profiles[index][:hourly_rate],
+    service_radius: tradesman_profiles[index][:service_radius],
+    city: tradesman_profiles[index][:city],
+    state: tradesman_profiles[index][:state],
+    street: tradesman_profiles[index][:street],
+    number: tradesman_profiles[index][:number],
+    verification_status: tradesman_profiles[index][:verification_status],
+    latitude: 42.3601 + (rand - 0.5) * 0.1,
+    longitude: -71.0589 + (rand - 0.5) * 0.1
+  )
+end
+
+# Create contractors
+contractor_profiles = [
+  { fname: "Robert", lname: "Builder", street: "700 Construction Ave", city: "Boston", state: "MA", number: "555-0301" },
+  { fname: "Emily", lname: "Contractor", street: "800 Build St", city: "Cambridge", state: "MA", number: "555-0302" }
+]
+
+contractor_users.each_with_index do |user_data, index|
+  user = User.create!(user_data)
+  all_users << user
+  Contractor.create!(
+    user: user,
+    fname: contractor_profiles[index][:fname],
+    lname: contractor_profiles[index][:lname],
+    street: contractor_profiles[index][:street],
+    city: contractor_profiles[index][:city],
+    state: contractor_profiles[index][:state],
+    number: contractor_profiles[index][:number],
+    latitude: 42.3601 + (rand - 0.5) * 0.1,
+    longitude: -71.0589 + (rand - 0.5) * 0.1
+  )
+end
+
+# Create admin
+admin_user = User.create!(admin_users.first)
+all_users << admin_user
+Admin.create!(
+  user: admin_user,
+  fname: "Admin",
+  lname: "User",
+  street: "900 Admin Blvd",
+  city: "Boston",
+  state: "MA",
+  number: "555-0001"
+)
+
+# Create suspended user
+suspended = User.create!(suspended_user)
+all_users << suspended
+Homeowner.create!(
+  user: suspended,
+  fname: "Suspended",
+  lname: "User",
+  street: "999 Suspended St",
+  city: "Boston",
+  state: "MA",
+  number: "555-9999"
+)
+
+puts "Created #{User.count} users"
+
+# ============================================
+# TRADESMAN VERIFICATIONS
+# ============================================
+puts "Creating tradesman verifications..."
+
+Tradesman.all.each do |tradesman|
+  status = tradesman.verification_status
+  admin_id = status == "approved" ? admin_user.id : nil
+  reviewed_at = status == "approved" ? 2.days.ago : nil
+  
+  TradesmanVerification.create!(
+    tradesman: tradesman,
+    admin_id: admin_id,
+    status: status,
+    license_number: tradesman.license_number,
+    certification_documents: "Certification document for #{tradesman.business_name}",
+    identification_documents: "ID document for #{tradesman.fname} #{tradesman.lname}",
+    reviewed_at: reviewed_at
+  )
+end
+
+puts "Created #{TradesmanVerification.count} verifications"
+
+# ============================================
+# SCHEDULES
+# ============================================
+puts "Creating schedules..."
+
+Tradesman.where(verification_status: "approved").each do |tradesman|
+  # Create schedules for the next 2 weeks
+  (0..13).each do |day_offset|
+    date = Date.today + day_offset.days
+    
+    # Create 3 time slots per day (morning, afternoon, evening)
+    [
+      { start: "09:00", end: "12:00", status: day_offset % 3 == 0 ? "booked" : "available" },
+      { start: "13:00", end: "17:00", status: day_offset % 4 == 0 ? "booked" : "available" },
+      { start: "18:00", end: "20:00", status: day_offset % 5 == 0 ? "unavailable" : "available" }
+    ].each do |slot|
+      Schedule.create!(
+        tradesman: tradesman,
+        date: date,
+        start_time: slot[:start],
+        end_time: slot[:end],
+        status: slot[:status]
+      )
+    end
+  end
+end
+
+puts "Created #{Schedule.count} schedule slots"
+
+# ============================================
+# PROJECTS
+# ============================================
+puts "Creating projects..."
+
+contractors = User.where(role: "contractor").includes(:contractor)
+homeowners = User.where(role: "homeowner").includes(:homeowner).limit(3)
+
+project_data = [
+  { title: "Kitchen Renovation", description: "Complete kitchen remodel including plumbing and electrical work", trade_type: "plumber", budget: 15000.0, location: "Boston, MA", preferred_date: 1.month.from_now, status: "open", bidding_increments: 100.0, timespan: "4-6 weeks", requirements: "Licensed plumber and electrician required" },
+  { title: "Office Building HVAC Upgrade", description: "Upgrade HVAC system for 5000 sq ft office building", trade_type: "hvac worker", budget: 50000.0, location: "Cambridge, MA", preferred_date: 2.months.from_now, status: "open", bidding_increments: 500.0, timespan: "8-10 weeks", requirements: "Commercial HVAC license required" },
+  { title: "Bathroom Remodel", description: "Full bathroom renovation with new fixtures", trade_type: "plumber", budget: 12000.0, location: "Somerville, MA", preferred_date: 3.weeks.from_now, status: "open", bidding_increments: 200.0, timespan: "3-4 weeks", requirements: "Experience with bathroom renovations" },
+  { title: "Electrical Panel Upgrade", description: "Upgrade main electrical panel to 200A service", trade_type: "electrician", budget: 8000.0, location: "Boston, MA", preferred_date: 1.week.from_now, status: "in_progress", bidding_increments: 100.0, timespan: "1-2 weeks", requirements: "Master electrician license required" },
+  { title: "Whole House Rewiring", description: "Complete electrical rewiring for 1920s home", trade_type: "electrician", budget: 25000.0, location: "Cambridge, MA", preferred_date: 2.months.from_now, status: "open", bidding_increments: 250.0, timespan: "6-8 weeks", requirements: "Experience with old homes" }
+]
+
+project_data.each_with_index do |proj_data, index|
+  owner = index < 2 ? contractors[index % contractors.count] : homeowners[index % homeowners.count]
+  
+  Project.create!(
+    contractor_id: owner.role == "contractor" ? owner.id : nil,
+    homeowner_id: owner.role == "homeowner" ? owner.homeowner&.id : nil,
+    title: proj_data[:title],
+    description: proj_data[:description],
+    trade_type: proj_data[:trade_type],
+    budget: proj_data[:budget],
+    location: proj_data[:location],
+    latitude: 42.3601 + (rand - 0.5) * 0.1,
+    longitude: -71.0589 + (rand - 0.5) * 0.1,
+    preferred_date: proj_data[:preferred_date],
+    status: proj_data[:status],
+    bidding_increments: proj_data[:bidding_increments],
+    timespan: proj_data[:timespan],
+    requirements: proj_data[:requirements]
+  )
+end
+
+puts "Created #{Project.count} projects"
+
+# ============================================
+# APPOINTMENTS
+# ============================================
+puts "Creating appointments..."
+
+homeowners_with_profiles = Homeowner.includes(:user).limit(3)
+tradesmen_with_profiles = Tradesman.where(verification_status: "approved").limit(3)
+projects = Project.limit(2)
+
+appointment_data = [
+  { scheduled_start: 3.days.from_now.change(hour: 9, min: 0), scheduled_end: 3.days.from_now.change(hour: 12, min: 0), job_description: "Fix leaking kitchen sink", status: "confirmed", accepted_at: 1.day.ago },
+  { scheduled_start: 5.days.from_now.change(hour: 13, min: 0), scheduled_end: 5.days.from_now.change(hour: 17, min: 0), job_description: "Install new electrical outlets", status: "pending" },
+  { scheduled_start: 1.week.from_now.change(hour: 10, min: 0), scheduled_end: 1.week.from_now.change(hour: 14, min: 0), job_description: "HVAC system inspection", status: "confirmed", accepted_at: 2.days.ago },
+  { scheduled_start: 2.weeks.from_now.change(hour: 9, min: 0), scheduled_end: 2.weeks.from_now.change(hour: 11, min: 0), job_description: "Bathroom plumbing repair", status: "rejected", rejected_at: 1.day.ago, rejection_reason: "Not available at that time" },
+  { scheduled_start: 1.week.ago.change(hour: 14, min: 0), scheduled_end: 1.week.ago.change(hour: 16, min: 0), job_description: "Completed plumbing work", status: "completed" }
+]
+
+appointment_data.each_with_index do |appt_data, index|
+  homeowner = homeowners_with_profiles[index % homeowners_with_profiles.count]
+  tradesman = tradesmen_with_profiles[index % tradesmen_with_profiles.count]
+  project = index < 2 ? projects[index] : nil
+  
+  Appointment.create!(
+    homeowner: homeowner,
+    tradesman: tradesman,
+    project: project,
+    scheduled_start: appt_data[:scheduled_start],
+    scheduled_end: appt_data[:scheduled_end],
+    job_description: appt_data[:job_description],
+    status: appt_data[:status],
+    accepted_at: appt_data[:accepted_at],
+    rejected_at: appt_data[:rejected_at],
+    rejection_reason: appt_data[:rejection_reason]
+  )
+end
+
+puts "Created #{Appointment.count} appointments"
+
+# ============================================
+# BIDS
+# ============================================
+puts "Creating bids..."
+
+open_projects = Project.where(status: "open")
+tradesmen_for_bids = Tradesman.where(verification_status: "approved")
+
+open_projects.each do |project|
+  # Create 2-3 bids per project
+  matching_tradesmen = tradesmen_for_bids.where(trade_specialty: project.trade_type).limit(3)
+  
+  matching_tradesmen.each_with_index do |tradesman, bid_index|
+    base_rate = tradesman.hourly_rate
+    bid_amount = project.budget - (bid_index * project.bidding_increments)
+    hourly_rate = base_rate - (bid_index * 5)
+    
+    Bid.create!(
+      project: project,
+      tradesman: tradesman,
+      amount: bid_amount,
+      hourly_rate: hourly_rate,
+      bidding_increment: project.bidding_increments,
+      status: bid_index == 0 ? "accepted" : "pending"
+    )
+  end
+end
+
+puts "Created #{Bid.count} bids"
+
+# ============================================
+# ESTIMATES
+# ============================================
+puts "Creating estimates..."
+
+confirmed_appointments = Appointment.where(status: ["confirmed", "completed"]).limit(3)
+
+confirmed_appointments.each_with_index do |appointment, index|
+  Estimate.create!(
+    tradesman: appointment.tradesman,
+    homeowner: appointment.homeowner,
+    appointment: appointment,
+    amount: 500.0 + (index * 200),
+    notes: "Estimate for #{appointment.job_description}",
+    status: index == 0 ? "accepted" : (index == 1 ? "rejected" : "pending"),
+    version: 1
+  )
+  
+  # Create an updated estimate for one appointment
+  if index == 1
+    Estimate.create!(
+      tradesman: appointment.tradesman,
+      homeowner: appointment.homeowner,
+      appointment: appointment,
+      amount: 450.0,
+      notes: "Revised estimate - found additional work needed",
+      status: "pending",
+      version: 2
+    )
+  end
+end
+
+# Create estimates for projects (only for homeowner-owned projects)
+homeowner_projects = Project.where.not(homeowner_id: nil).limit(1)
+if homeowner_projects.any?
+  project_with_estimate = homeowner_projects.first
+  homeowner = project_with_estimate.homeowner
+  Estimate.create!(
+    tradesman: tradesmen_for_bids.first,
+    homeowner: homeowner,
+    project: project_with_estimate,
+    amount: project_with_estimate.budget * 0.9,
+    notes: "Initial estimate for #{project_with_estimate.title}",
+    status: "pending",
+    version: 1
+  )
+end
+
+puts "Created #{Estimate.count} estimates"
+
+# ============================================
+# CONVERSATIONS AND MESSAGES
+# ============================================
+puts "Creating conversations and messages..."
+
+# Create conversations between homeowners and tradesmen
+appointments_with_messages = Appointment.limit(4)
+
+appointments_with_messages.each do |appointment|
+  homeowner_user = appointment.homeowner.user
+  tradesman_user = appointment.tradesman.user
+  
+  conversation = Conversation.find_or_create_between(homeowner_user.id, tradesman_user.id)
+  
+  # Create initial message from homeowner
+  Message.create!(
+    conversation: conversation,
+    sender: homeowner_user,
+    content: "Hi, I'm interested in your services for: #{appointment.job_description}",
+    read_at: nil
+  )
+  
+  # Create response from tradesman
+  Message.create!(
+    conversation: conversation,
+    sender: tradesman_user,
+    content: "Thank you for reaching out! I'd be happy to help with that. When would be a good time for you?",
+    read_at: 1.hour.ago
+  )
+  
+  # Create follow-up message
+  if appointment.status == "confirmed"
+    Message.create!(
+      conversation: conversation,
+      sender: homeowner_user,
+      content: "Great! Looking forward to the appointment on #{appointment.scheduled_start.strftime('%B %d')}.",
+      read_at: nil
+    )
+  end
+end
+
+# Create a conversation without appointment
+homeowner_user = User.where(role: "homeowner").first
+tradesman_user = Tradesman.where(verification_status: "approved").first.user
+
+conversation = Conversation.find_or_create_between(homeowner_user.id, tradesman_user.id)
+Message.create!(
+  conversation: conversation,
+  sender: homeowner_user,
+  content: "Do you provide emergency services?",
+  read_at: nil
+)
+
+puts "Created #{Conversation.count} conversations"
+puts "Created #{Message.count} messages"
+
+# ============================================
+# REVIEWS
+# ============================================
+puts "Creating reviews..."
+
+completed_appointments = Appointment.where(status: "completed")
+
+completed_appointments.each_with_index do |appointment, index|
+  Review.create!(
+    homeowner: appointment.homeowner,
+    tradesman: appointment.tradesman,
+    appointment: appointment,
+    rating: [4, 5, 5, 4, 5][index % 5],
+    comment: [
+      "Excellent work! Very professional and completed on time.",
+      "Great service, would definitely hire again.",
+      "Fixed the issue quickly and efficiently.",
+      "Good work, but took a bit longer than expected.",
+      "Outstanding quality and professionalism!"
+    ][index % 5]
+  )
+end
+
+# Create some additional reviews for tradesmen
+tradesmen_with_reviews = Tradesman.where(verification_status: "approved").limit(2)
+homeowners_for_reviews = Homeowner.limit(2)
+
+tradesmen_with_reviews.each do |tradesman|
+  homeowners_for_reviews.each do |homeowner|
+    Review.create!(
+      homeowner: homeowner,
+      tradesman: tradesman,
+      rating: rand(4..5),
+      comment: "Great service from #{tradesman.business_name}!"
+    )
+  end
+end
+
+puts "Created #{Review.count} reviews"
+
+# ============================================
+# NOTIFICATIONS
+# ============================================
+puts "Creating notifications..."
+
+# Create notifications for various users
+all_users.each do |user|
+  notification_types = [
+    { type: "appointment_confirmed", title: "Appointment Confirmed", message: "Your appointment has been confirmed for tomorrow at 9:00 AM" },
+    { type: "new_message", title: "New Message", message: "You have a new message from a tradesman" },
+    { type: "new_bid", title: "New Bid Received", message: "A new bid has been placed on your project" },
+    { type: "estimate_updated", title: "Estimate Updated", message: "Your estimate has been updated by the tradesman" },
+    { type: "review_received", title: "New Review", message: "You received a new review from a homeowner" }
+  ]
+  
+  # Create 1-3 notifications per user
+  rand(1..3).times do
+    notification = notification_types.sample
+    Notification.create!(
+      user: user,
+      notification_type: notification[:type],
+      title: notification[:title],
+      message: notification[:message],
+      read: rand < 0.3, # 30% chance of being read
+      read_at: rand < 0.3 ? rand(1..7).days.ago : nil,
+      related_type: ["Appointment", "Message", "Bid", "Estimate", "Review"].sample,
+      related_id: rand(1..100)
+    )
+  end
+end
+
+puts "Created #{Notification.count} notifications"
+
+# ============================================
+# SUMMARY
+# ============================================
+puts "\n" + "="*50
+puts "SEED DATA SUMMARY"
+puts "="*50
+puts "Users: #{User.count}"
+puts "  - Homeowners: #{User.where(role: 'homeowner').count}"
+puts "  - Tradesmen: #{User.where(role: 'tradesman').count}"
+puts "  - Contractors: #{User.where(role: 'contractor').count}"
+puts "  - Admins: #{User.where(role: 'admin').count}"
+puts "Homeowners: #{Homeowner.count}"
+puts "Contractors: #{Contractor.count}"
+puts "Tradesmen: #{Tradesman.count}"
+puts "Admins: #{Admin.count}"
+puts "Schedules: #{Schedule.count}"
+puts "Projects: #{Project.count}"
+puts "Appointments: #{Appointment.count}"
+puts "Bids: #{Bid.count}"
+puts "Estimates: #{Estimate.count}"
+puts "Conversations: #{Conversation.count}"
+puts "Messages: #{Message.count}"
+puts "Reviews: #{Review.count}"
+puts "Notifications: #{Notification.count}"
+puts "Tradesman Verifications: #{TradesmanVerification.count}"
+puts "="*50
+puts "Seed data created successfully!"
+puts "="*50
