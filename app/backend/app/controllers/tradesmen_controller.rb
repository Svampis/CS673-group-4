class TradesmenController < ApiController
  def index
    trade = params[:trade]
    location = params[:location]
    name = params[:name]
    
    tradesmen = if trade.present? || location.present? || name.present?
      Tradesman.find_by_trade_and_location(trade, location, name)
    else
      Tradesman.all
    end
    
    render json: tradesmen.map { |t| 
      {
        user_id: t.user_id,
        name: t.name,
        email: t.email,
        trade: t.trade,
        rating: t.rating,
        address: t.address,
        location: t.location,
        experience: t.experience,
        business_name: t.business_name,
        profile: t.profile,
        distance: calculate_distance(t.location)
      }
    }
  end
  
  def show
    tradesman = Tradesman.find_by_id(params[:id])
    
    if tradesman.nil?
      render json: { error: "Tradesman not found" }, status: :not_found
    else
      render json: {
        user_id: tradesman.user_id,
        name: tradesman.name,
        email: tradesman.email,
        trade: tradesman.trade,
        rating: tradesman.rating,
        address: tradesman.address,
        location: tradesman.location,
        experience: tradesman.experience,
        business_name: tradesman.business_name,
        license_number: tradesman.license_number,
        profile: tradesman.profile
      }
    end
  end
  
  private
  
  def calculate_distance(location)
    # Placeholder distance calculation
    # In a real app, this would calculate based on user's location and tradesman's location
    return "12.3" if location.present?
    "15.0"
  end
end
