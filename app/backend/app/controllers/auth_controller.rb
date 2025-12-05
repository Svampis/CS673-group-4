class AuthController < ApiController
  def register
    user_params = params.permit(:name, :email, :password, :role, :address,
                                 :street, :city, :state, :number,
                                 :trade_specialty, :license_number, :business_name,
                                 :years_of_experience, :hourly_rate, :service_radius).to_h.symbolize_keys
    
    # Validate required fields
    if user_params[:name].blank? || user_params[:email].blank? || user_params[:password].blank? || user_params[:role].blank?
      return render_error("Missing required fields: name, email, password, and role are required")
    end
    
    # Check if user already exists
    existing_user = User.find_by_email(user_params[:email])
    if existing_user
      return render_error("User with this email already exists", :conflict)
    end
    
    # Normalize role
    role = user_params[:role].downcase
    role = 'homeowner' if role == 'homeowner'
    role = 'tradesman' if ['tradesman', 'plumber', 'electrician', 'hvac worker'].include?(role)
    role = 'contractor' if role == 'contractor'
    role = 'admin' if role == 'admin'
    
    # Parse name into fname and lname
    name_parts = parse_name(user_params[:name])
    
    # Create new user and profile in a transaction
    ActiveRecord::Base.transaction do
      user = User.create!(
        email: user_params[:email],
        password_hash: user_params[:password], # In production, hash this with bcrypt
        role: role,
        status: 'activated'
      )
      
      # Create role-specific profile
      case role
      when 'homeowner'
        Homeowner.create!(
          user: user,
          fname: name_parts[:fname],
          lname: name_parts[:lname],
          street: user_params[:street],
          city: user_params[:city],
          state: user_params[:state],
          number: user_params[:number]
        )
      when 'contractor'
        Contractor.create!(
          user: user,
          fname: name_parts[:fname],
          lname: name_parts[:lname],
          street: user_params[:street],
          city: user_params[:city],
          state: user_params[:state],
          number: user_params[:number]
        )
      when 'tradesman'
        tradesman = Tradesman.create!(
          user: user,
          fname: name_parts[:fname],
          lname: name_parts[:lname],
          trade_specialty: user_params[:trade_specialty],
          license_number: user_params[:license_number],
          business_name: user_params[:business_name],
          years_of_experience: user_params[:years_of_experience]&.to_i,
          street: user_params[:street],
          city: user_params[:city],
          state: user_params[:state],
          number: user_params[:number],
          hourly_rate: user_params[:hourly_rate]&.to_f || 50.0,
          service_radius: user_params[:service_radius]&.to_f || 25.0,
          verification_status: 'pending'
        )
        
        # Auto-create tradesman verification record
        TradesmanVerification.create!(
          tradesman: tradesman,
          status: 'pending'
        )
      when 'admin'
        Admin.create!(
          user: user,
          fname: name_parts[:fname],
          lname: name_parts[:lname]
        )
      end
      
      render json: {
        user_id: user.id,
        name: user_params[:name],
        email: user.email,
        role: user.role,
        status: user.status
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Failed to create user: #{e.record.errors.full_messages.join(', ')}")
  rescue => e
    render_error("Failed to create user: #{e.message}")
  end
  
  def login
    login_params = params.permit(:email, :password, :two_factor_code).to_h.symbolize_keys
    
    if login_params[:email].blank? || login_params[:password].blank?
      return render_error("Email and password are required", :bad_request)
    end
    
    user = User.authenticate(login_params[:email], login_params[:password])
    
    if user.nil?
      return render_error("Invalid email or password", :unauthorized)
    end
    
    if user.status != 'activated'
      suspension_message = "Account is not active"
      if user.status == 'suspended'
        suspension_message = "Account has been suspended. Please contact support."
      end
      return render_error(suspension_message, :forbidden)
    end
    
    # Check 2FA for admin users
    if user.role == 'admin' && user.two_factor_enabled
      if login_params[:two_factor_code].blank?
        return render_error("Two-factor authentication code required", :unauthorized)
      end
      
      require 'rotp'
      totp = ROTP::TOTP.new(user.two_factor_secret)
      
      unless totp.verify(login_params[:two_factor_code], drift_behind: 15, drift_ahead: 15)
        return render_error("Invalid two-factor authentication code", :unauthorized)
      end
    end
    
    # Get user's name from profile
    user_name = get_user_name(user)
    
    # Generate a simple token (in production, use JWT)
    token = JsonStorage.generate_id
    
    render json: {
      access_token: token,
      token_type: "Bearer",
      user_id: user.id,
      name: user_name,
      email: user.email,
      role: user.role
    }
  end
  
  def setup_2fa
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    
    return render_error("User not found", :not_found) unless user
    return render_error("Only admin users can enable 2FA", :forbidden) unless user.role == 'admin'
    
    require 'rotp'
    require 'rqrcode'
    
    # Generate secret if not exists
    secret = user.two_factor_secret || ROTP::Base32.random
    
    # Generate provisioning URI
    totp = ROTP::TOTP.new(secret, issuer: "RoofConnect")
    provisioning_uri = totp.provisioning_uri(user.email)
    
    # Generate QR code
    qr = RQRCode::QRCode.new(provisioning_uri)
    qr_code_svg = qr.as_svg(module_size: 4)
    
    # Save secret (but don't enable yet - user needs to verify first)
    user.update(two_factor_secret: secret)
    
    render json: {
      secret: secret,
      qr_code: qr_code_svg,
      provisioning_uri: provisioning_uri
    }
  end
  
  def verify_2fa
    user_id = params[:user_id]
    code = params[:code]
    
    return render_error("User ID and code required", :bad_request) unless user_id && code
    
    user = User.find_by(id: user_id)
    return render_error("User not found", :not_found) unless user
    return render_error("Two-factor secret not set", :unprocessable_entity) unless user.two_factor_secret
    
    require 'rotp'
    totp = ROTP::TOTP.new(user.two_factor_secret)
    
    if totp.verify(code, drift_behind: 15, drift_ahead: 15)
      user.update(two_factor_enabled: true)
      render json: { message: "Two-factor authentication enabled successfully" }
    else
      render_error("Invalid verification code", :unauthorized)
    end
  end
  
  private
  
  def parse_name(name)
    return { fname: '', lname: '' } if name.blank?
    
    parts = name.split(' ')
    if parts.length == 1
      { fname: parts[0], lname: '' }
    else
      { fname: parts[0], lname: parts[1..-1].join(' ') }
    end
  end
  
  def get_user_name(user)
    case user.role
    when 'homeowner'
      homeowner = user.homeowner
      homeowner ? "#{homeowner.fname} #{homeowner.lname}".strip : user.email
    when 'contractor'
      contractor = user.contractor
      contractor ? "#{contractor.fname} #{contractor.lname}".strip : user.email
    when 'tradesman'
      tradesman = user.tradesman
      tradesman ? "#{tradesman.fname} #{tradesman.lname}".strip : user.email
    when 'admin'
      admin = user.admin
      admin ? "#{admin.fname} #{admin.lname}".strip : user.email
    else
      user.email
    end
  end
end

