class Api::TradesmanProfilesController < ApiController
  def create
    profile_params = params.permit(:user_id, :name, :email, :trade, :license_number, :business_name, :experience, :location, :address).to_h.symbolize_keys
    tradesman = Tradesman.find_by_id(profile_params[:user_id])
    
    if tradesman.nil?
      # Create new tradesman if doesn't exist
      tradesman = Tradesman.new(profile_params)
    else
      # Update existing tradesman
      tradesman.name = profile_params[:name] if profile_params[:name]
      tradesman.email = profile_params[:email] if profile_params[:email]
      tradesman.trade = profile_params[:trade] if profile_params[:trade]
      tradesman.license_number = profile_params[:license_number] if profile_params[:license_number]
      tradesman.business_name = profile_params[:business_name] if profile_params[:business_name]
      tradesman.experience = profile_params[:experience] if profile_params[:experience]
      tradesman.location = profile_params[:location] if profile_params[:location]
      tradesman.address = profile_params[:address] if profile_params[:address]
    end
    
    if tradesman.save
      render json: { message: "Tradesman profile saved successfully" }, status: :created
    else
      render_error("Failed to save tradesman profile")
    end
  end
end

