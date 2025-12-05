class Api::TradesmanProfilesController < ApiController
  def create
    profile_params = params.permit(:user_id, :trade_specialty, :license_number, :business_name, 
                                    :years_of_experience, :service_radius, :hourly_rate,
                                    :street, :city, :state, :number, :description).to_h.symbolize_keys
    
    user_id = profile_params[:user_id]
    return render_error("user_id is required", :bad_request) unless user_id
    
    user = User.find_by(id: user_id)
    return render_error("User not found", :not_found) unless user
    return render_error("User is not a tradesman", :forbidden) unless user.role == 'tradesman'
    
    tradesman = user.tradesman || Tradesman.new(user: user)
    
    # Update tradesman profile
    tradesman.trade_specialty = profile_params[:trade_specialty] if profile_params[:trade_specialty].present?
    tradesman.license_number = profile_params[:license_number] if profile_params[:license_number].present?
    tradesman.business_name = profile_params[:business_name] if profile_params[:business_name].present?
    tradesman.years_of_experience = profile_params[:years_of_experience] if profile_params[:years_of_experience].present?
    tradesman.service_radius = profile_params[:service_radius] if profile_params[:service_radius].present?
    tradesman.hourly_rate = profile_params[:hourly_rate] if profile_params[:hourly_rate].present?
    tradesman.street = profile_params[:street] if profile_params[:street].present?
    tradesman.city = profile_params[:city] if profile_params[:city].present?
    tradesman.state = profile_params[:state] if profile_params[:state].present?
    tradesman.number = profile_params[:number] if profile_params[:number].present?
    tradesman.description = profile_params[:description] if profile_params[:description].present?
    
    if tradesman.save
      render json: {
        message: "Tradesman profile saved successfully",
        tradesman_id: tradesman.id,
        service_radius: tradesman.service_radius,
        hourly_rate: tradesman.hourly_rate
      }, status: :created
    else
      render_error("Failed to save tradesman profile: #{tradesman.errors.full_messages.join(', ')}")
    end
  end
  
  def update
    user_id = params[:user_id]
    return render_error("user_id is required", :bad_request) unless user_id
    
    user = User.find_by(id: user_id)
    return render_error("User not found", :not_found) unless user
    
    tradesman = user.tradesman
    return render_error("Tradesman profile not found", :not_found) unless tradesman
    
    profile_params = params.permit(:trade_specialty, :license_number, :business_name,
                                    :years_of_experience, :service_radius, :hourly_rate,
                                    :street, :city, :state, :number, :description).to_h.symbolize_keys
    
    if tradesman.update(profile_params)
      render json: {
        message: "Tradesman profile updated successfully",
        tradesman_id: tradesman.id,
        service_radius: tradesman.service_radius,
        hourly_rate: tradesman.hourly_rate
      }
    else
      render_error("Failed to update tradesman profile: #{tradesman.errors.full_messages.join(', ')}")
    end
  end
end

