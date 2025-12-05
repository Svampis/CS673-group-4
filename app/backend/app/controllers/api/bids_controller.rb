class Api::BidsController < ApiController
  def create
    project_id = params[:project_id]
    project = Project.find_by(id: project_id)
    
    return render_error("Project not found", :not_found) unless project
    return render_error("Project is not open for bidding", :unprocessable_entity) unless project.status == 'open'
    
    bid_params = params.permit(:tradesman_id, :amount, :hourly_rate, :notes).to_h.symbolize_keys
    
    # Validate required fields
    if bid_params[:tradesman_id].blank? || bid_params[:amount].blank? || bid_params[:hourly_rate].blank?
      return render_error("tradesman_id, amount, and hourly_rate are required", :bad_request)
    end
    
    # Check if tradesman already has a bid on this project
    existing_bid = Bid.where(project_id: project_id, tradesman_id: bid_params[:tradesman_id]).first
    if existing_bid
      return render_error("You have already placed a bid on this project", :conflict)
    end
    
    bid = Bid.new(
      project_id: project_id,
      tradesman_id: bid_params[:tradesman_id],
      amount: bid_params[:amount],
      hourly_rate: bid_params[:hourly_rate],
      status: 'pending'
    )
    
    if bid.save
      # Notify contractor of new bid
      NotificationService.notify_new_bid(bid)
      
      render json: {
        bid_id: bid.id,
        project_id: bid.project_id,
        tradesman_id: bid.tradesman_id,
        amount: bid.amount,
        hourly_rate: bid.hourly_rate,
        status: bid.status,
        created_at: bid.created_at
      }, status: :created
    else
      render_error("Failed to create bid: #{bid.errors.full_messages.join(', ')}")
    end
  end
  
  def index
    if params[:project_id].present?
      # Get all bids for a project (for contractors)
      project_id = params[:project_id]
      bids = Bid.where(project_id: project_id).includes(:tradesman).order(amount: :asc)
      
      render json: bids.map { |b|
        tradesman = b.tradesman
        {
          bid_id: b.id,
          project_id: b.project_id,
          tradesman_id: b.tradesman_id,
          tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
          tradesman_rating: tradesman.rating,
          amount: b.amount,
          hourly_rate: b.hourly_rate,
          status: b.status,
          created_at: b.created_at
        }
      }
    elsif params[:tradesman_id].present?
      # Get all bids for a tradesman
      tradesman_id = params[:tradesman_id]
      bids = Bid.where(tradesman_id: tradesman_id).includes(:project).order(created_at: :desc)
      
      render json: bids.map { |b|
        project = b.project
        {
          bid_id: b.id,
          project_id: b.project_id,
          project_title: project.title,
          project_status: project.status,
          amount: b.amount,
          hourly_rate: b.hourly_rate,
          status: b.status,
          created_at: b.created_at
        }
      }
    else
      render_error("project_id or tradesman_id is required", :bad_request)
    end
  end
  
  def show
    bid = Bid.find_by(id: params[:id])
    
    if bid.nil?
      render_error("Bid not found", :not_found)
    else
      tradesman = bid.tradesman
      project = bid.project
      
      render json: {
        bid_id: bid.id,
        project_id: bid.project_id,
        project_title: project.title,
        tradesman_id: bid.tradesman_id,
        tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
        tradesman_rating: tradesman.rating,
        amount: bid.amount,
        hourly_rate: bid.hourly_rate,
        status: bid.status,
        created_at: bid.created_at,
        updated_at: bid.updated_at
      }
    end
  end
  
  def update
    bid = Bid.find_by(id: params[:id])
    
    if bid.nil?
      render_error("Bid not found", :not_found)
    elsif bid.status != 'pending'
      render_error("Only pending bids can be updated", :unprocessable_entity)
    else
      bid_params = params.permit(:amount, :hourly_rate).to_h.symbolize_keys
      
      if bid.update(bid_params)
        render json: {
          bid_id: bid.id,
          amount: bid.amount,
          hourly_rate: bid.hourly_rate,
          status: bid.status
        }
      else
        render_error("Failed to update bid: #{bid.errors.full_messages.join(', ')}")
      end
    end
  end
  
  def accept
    project_id = params[:project_id]
    bid_id = params[:bid_id]
    
    project = Project.find_by(id: project_id)
    bid = Bid.find_by(id: bid_id, project_id: project_id)
    
    return render_error("Project not found", :not_found) unless project
    return render_error("Bid not found", :not_found) unless bid
    return render_error("Only pending bids can be accepted", :unprocessable_entity) unless bid.status == 'pending'
    
    # Accept the bid
    bid.update(status: 'accepted')
    
    # Reject all other bids on this project
    Bid.where(project_id: project_id).where.not(id: bid_id).update_all(status: 'rejected')
    
    # Assign tradesman to project
    project.update(
      status: 'in_progress',
      assigned_id: bid.tradesman_id
    )
    
    # Notify tradesman
    NotificationService.notify_bid_accepted(bid)
    
    # Notify other tradesmen whose bids were rejected
    Bid.where(project_id: project_id, status: 'rejected').each do |rejected_bid|
      NotificationService.notify_bid_rejected(rejected_bid)
    end
    
    render json: {
      message: "Bid accepted and project assigned",
      bid_id: bid.id,
      project_id: project.id,
      tradesman_id: bid.tradesman_id,
      status: bid.status
    }
  end
  
  def reject
    project_id = params[:project_id]
    bid_id = params[:bid_id]
    
    project = Project.find_by(id: project_id)
    bid = Bid.find_by(id: bid_id, project_id: project_id)
    
    return render_error("Project not found", :not_found) unless project
    return render_error("Bid not found", :not_found) unless bid
    return render_error("Only pending bids can be rejected", :unprocessable_entity) unless bid.status == 'pending'
    
    bid.update(status: 'rejected')
    
    # Notify tradesman
    NotificationService.notify_bid_rejected(bid)
    
    render json: {
      message: "Bid rejected",
      bid_id: bid.id,
      status: bid.status
    }
  end
end

