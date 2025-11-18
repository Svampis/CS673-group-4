class AuthController < ApiController
  def register
    user_params = params.permit(:name, :email, :password, :role, :address).to_h.symbolize_keys
    
    # Validate required fields
    if user_params[:name].blank? || user_params[:email].blank? || user_params[:password].blank? || user_params[:role].blank?
      return render_error("Missing required fields: name, email, password, and role are required")
    end
    
    # Check if user already exists
    existing_user = User.find_by_email(user_params[:email])
    if existing_user
      return render_error("User with this email already exists", :conflict)
    end
    
    # Create new user
    user = User.new(
      name: user_params[:name],
      email: user_params[:email],
      password_hash: user_params[:password], # In production, hash this with bcrypt
      role: user_params[:role],
      address: user_params[:address],
      status: 'active'
    )
    
    if user.save
      render json: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status
      }, status: :created
    else
      render_error("Failed to create user")
    end
  end
  
  def login
    login_params = params.permit(:email, :password).to_h.symbolize_keys
    
    if login_params[:email].blank? || login_params[:password].blank?
      return render_error("Email and password are required", :bad_request)
    end
    
    user = User.authenticate(login_params[:email], login_params[:password])
    
    if user.nil?
      return render_error("Invalid email or password", :unauthorized)
    end
    
    if user.status != 'active'
      return render_error("Account is not active", :forbidden)
    end
    
    # Generate a simple token (in production, use JWT)
    token = JsonStorage.generate_id
    
    render json: {
      access_token: token,
      token_type: "Bearer",
      user_id: user.user_id,
      name: user.name,
      email: user.email,
      role: user.role
    }
  end
end

