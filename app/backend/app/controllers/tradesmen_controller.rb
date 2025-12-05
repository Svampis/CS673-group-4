class TradesmenController < ApiController
  def index
    tradesmen = Tradesman.all.includes(:user, :reviews)
    
    # Filter by trade specialty
    tradesmen = tradesmen.by_trade(params[:trade]) if params[:trade].present?
    
    # Filter by location (city)
    tradesmen = tradesmen.by_location(params[:location]) if params[:location].present?
    
    # Filter by verified status (only show verified tradesmen by default)
    if params[:verified_only] != 'false'
      tradesmen = tradesmen.verified
    end
    
    # Filter by rating (backend filtering)
    if params[:min_rating].present?
      min_rating = params[:min_rating].to_f
      tradesmen = tradesmen.select { |t| t.rating >= min_rating }
    end
    
    # Filter by hourly rate range
    if params[:min_hourly_rate].present?
      min_rate = params[:min_hourly_rate].to_f
      tradesmen = tradesmen.select { |t| t.hourly_rate && t.hourly_rate >= min_rate }
    end
    
    if params[:max_hourly_rate].present?
      max_rate = params[:max_hourly_rate].to_f
      tradesmen = tradesmen.select { |t| t.hourly_rate && t.hourly_rate <= max_rate }
    end
    
    # Filter by distance (if user location provided)
    if params[:user_latitude].present? && params[:user_longitude].present?
      user_lat = params[:user_latitude].to_f
      user_lng = params[:user_longitude].to_f
      max_distance = params[:max_distance]&.to_f || 50.0 # Default 50 miles
      
      tradesmen = tradesmen.select do |t|
        if t.latitude && t.longitude && t.service_radius
          distance = calculate_distance_haversine(user_lat, user_lng, t.latitude, t.longitude)
          distance <= max_distance && distance <= t.service_radius
        else
          false
        end
      end
    end
    
    # Sort by rating (if requested)
    if params[:sort] == 'rating'
      tradesmen = tradesmen.sort_by { |t| -t.rating }
    elsif params[:sort] == 'hourly_rate'
      tradesmen = tradesmen.sort_by { |t| t.hourly_rate || Float::INFINITY }
    end
    
    render json: tradesmen.map { |t| 
      distance = nil
      if params[:user_latitude].present? && params[:user_longitude].present? && t.latitude && t.longitude
        distance = calculate_distance_haversine(
          params[:user_latitude].to_f,
          params[:user_longitude].to_f,
          t.latitude,
          t.longitude
        )
      end
      
      {
        tradesman_id: t.id,
        user_id: t.user_id,
        name: "#{t.fname} #{t.lname}".strip,
        email: t.user.email,
        trade_specialty: t.trade_specialty,
        rating: t.rating,
        hourly_rate: t.hourly_rate,
        service_radius: t.service_radius,
        business_name: t.business_name,
        years_of_experience: t.years_of_experience,
        license_number: t.license_number,
        street: t.street,
        city: t.city,
        state: t.state,
        number: t.number,
        verification_status: t.verification_status,
        distance: distance ? distance.round(2) : nil
      }
    }
  end
  
  def show
    tradesman = Tradesman.find_by(id: params[:id])
    
    if tradesman.nil?
      render json: { error: "Tradesman not found" }, status: :not_found
    else
      render json: {
        tradesman_id: tradesman.id,
        user_id: tradesman.user_id,
        name: "#{tradesman.fname} #{tradesman.lname}".strip,
        email: tradesman.user.email,
        trade_specialty: tradesman.trade_specialty,
        rating: tradesman.rating,
        hourly_rate: tradesman.hourly_rate,
        service_radius: tradesman.service_radius,
        business_name: tradesman.business_name,
        years_of_experience: tradesman.years_of_experience,
        license_number: tradesman.license_number,
        description: tradesman.description,
        street: tradesman.street,
        city: tradesman.city,
        state: tradesman.state,
        number: tradesman.number,
        latitude: tradesman.latitude,
        longitude: tradesman.longitude,
        verification_status: tradesman.verification_status
      }
    end
  end
  
  def compare
    ids = params[:ids] || params[:id]
    return render_error("ids parameter required (comma-separated)", :bad_request) unless ids
    
    tradesman_ids = ids.to_s.split(',').map(&:strip).map(&:to_i)
    tradesmen = Tradesman.where(id: tradesman_ids).includes(:user, :reviews)
    
    render json: tradesmen.map { |t|
      {
        tradesman_id: t.id,
        user_id: t.user_id,
        name: "#{t.fname} #{t.lname}".strip,
        email: t.user.email,
        trade_specialty: t.trade_specialty,
        rating: t.rating,
        hourly_rate: t.hourly_rate,
        service_radius: t.service_radius,
        business_name: t.business_name,
        years_of_experience: t.years_of_experience,
        license_number: t.license_number,
        verification_status: t.verification_status,
        review_count: t.reviews.count
      }
    }
  end
  
  private
  
  def calculate_distance_haversine(lat1, lon1, lat2, lon2)
    # Haversine formula to calculate distance between two points in miles
    earth_radius_miles = 3959.0
    
    dlat = (lat2 - lat1) * Math::PI / 180.0
    dlon = (lon2 - lon1) * Math::PI / 180.0
    
    a = Math.sin(dlat / 2) ** 2 +
        Math.cos(lat1 * Math::PI / 180.0) *
        Math.cos(lat2 * Math::PI / 180.0) *
        Math.sin(dlon / 2) ** 2
    
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    earth_radius_miles * c
  end
end
