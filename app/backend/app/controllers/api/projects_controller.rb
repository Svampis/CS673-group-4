class Api::ProjectsController < ApiController
  def search
    projects = Project.where(status: 'open')
    
    # Get trade type from params or try to get from logged-in tradesman
    trade_type_filter = params[:trade_type]
    
    # If trade_type is explicitly set to 'all', don't filter by trade type
    if trade_type_filter.present? && trade_type_filter.to_s.downcase.strip == 'all'
      trade_type_filter = nil
    # If no trade_type filter provided in params, try to get from logged-in tradesman
    # This allows tradesmen to see projects matching their specialty by default
    elsif trade_type_filter.blank?
      user_id = params[:user_id]
      if user_id.present?
        user = User.find_by(id: user_id)
        if user&.role == 'tradesman' && user.tradesman&.trade_specialty.present?
          trade_type_filter = user.tradesman.trade_specialty
        end
      end
    end
    
    # Filter by trade type (case-insensitive and handle variations)
    # Only filter if a trade_type was explicitly provided or auto-detected (not 'all')
    if trade_type_filter.present?
      trade_type = trade_type_filter.to_s.downcase.strip
      # Normalize trade type to match database values
      normalized_trade = case trade_type
      when 'plumber', 'plumbing'
        'plumber'
      when 'electrician', 'electrical'
        'electrician'
      when 'hvac', 'hvac worker', 'hvacworker'
        'hvac worker'
      else
        trade_type
      end
      # Use case-insensitive comparison
      projects = projects.where("LOWER(trade_type) = ?", normalized_trade)
    end
    # If no trade_type filter, show all open projects
    
    # Filter by location (basic - can be enhanced with distance calculation)
    if params[:location].present?
      location_term = "%#{params[:location]}%"
      projects = projects.where("location LIKE ?", location_term)
    end
    
    # Filter by date range
    if params[:start_date].present?
      projects = projects.where("preferred_date >= ?", params[:start_date])
    end
    
    if params[:end_date].present?
      projects = projects.where("preferred_date <= ?", params[:end_date])
    end
    
    # Filter by budget range
    if params[:min_budget].present?
      projects = projects.where("budget >= ?", params[:min_budget])
    end
    
    if params[:max_budget].present?
      projects = projects.where("budget <= ?", params[:max_budget])
    end
    
    projects = projects.order(created_at: :desc)
    limit = params[:limit]&.to_i || 50
    projects = projects.limit(limit)
    
    render json: projects.map { |p|
      {
        project_id: p.id,
        title: p.title,
        description: p.description,
        trade_type: p.trade_type,
        budget: p.budget,
        location: p.location,
        preferred_date: p.preferred_date,
        status: p.status,
        created_at: p.created_at,
        bid_count: p.bids.count
      }
    }
  end
  
  private
  
  def extract_user_id_from_request
    # Try to extract user_id from Authorization token or request headers
    # This is a simple implementation - in production, you'd decode JWT token
    auth_header = request.headers['Authorization']
    if auth_header.present?
      # For now, we'll rely on params or let the frontend send user_id
      # In a real implementation, decode the JWT token here
    end
    nil
  end
end

