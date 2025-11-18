class ProfilesController < ApiController
  def show
    user_id = params[:user_id]
    user = User.find_by_id(user_id)
    
    if user.nil?
      return render_error("User not found", :not_found)
    end
    
    # Build profile response
    response_data = {
      user_id: user.user_id,
      name: user.name,
      email: user.email,
      role: user.role,
      address: user.address,
      profile: user.profile || {}
    }
    
    # If tradesman, include tradesman-specific profile data
    if user.role == 'tradesman'
      tradesman = Tradesman.find_by_id(user_id)
      if tradesman
        response_data[:profile] = {
          license_number: tradesman.license_number,
          trade: tradesman.trade,
          experience: tradesman.experience,
          rating: tradesman.rating,
          business_name: tradesman.business_name,
          location: tradesman.location
        }.merge(response_data[:profile])
      end
    end
    
    render json: response_data
  end
  
  def update
    user_id = params[:user_id]
    user = User.find_by_id(user_id)
    
    if user.nil?
      return render_error("User not found", :not_found)
    end
    
    update_params = params.permit(:name, :address, profile: {}).to_h.symbolize_keys
    
    # Update user fields
    user.name = update_params[:name] if update_params[:name]
    user.address = update_params[:address] if update_params[:address]
    
    # Update profile if provided
    if update_params[:profile]
      user.profile = (user.profile || {}).merge(update_params[:profile])
    end
    
    # If tradesman, also update tradesman profile
    if user.role == 'tradesman' && update_params[:profile]
      tradesman = Tradesman.find_by_id(user_id)
      if tradesman
        tradesman.experience = update_params[:profile][:experience] if update_params[:profile][:experience]
        tradesman.save
      end
    end
    
    if user.save
      render json: { message: "Profile updated successfully" }
    else
      render_error("Failed to update profile")
    end
  end
end

