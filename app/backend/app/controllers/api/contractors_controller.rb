class Api::ContractorsController < ApiController
  def dashboard
    contractor_id = params[:id]
    contractor = User.find_by(id: contractor_id)
    
    return render_error("Contractor not found", :not_found) unless contractor
    return render_error("User is not a contractor", :forbidden) unless contractor.role == 'contractor'
    
    projects = Project.where(contractor_id: contractor_id)
    
    # Get open projects with bids
    open_projects = projects.where(status: 'open').includes(:bids => :tradesman)
    
    projects_data = open_projects.map do |project|
      bids_with_ratings = project.bids.map do |bid|
        tradesman = bid.tradesman
        {
          bid_id: bid.id,
          tradesman_id: tradesman.id,
          tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
          tradesman_rating: tradesman.rating,
          amount: bid.amount,
          hourly_rate: bid.hourly_rate,
          status: bid.status,
          created_at: bid.created_at
        }
      end
      
      {
        project_id: project.id,
        title: project.title,
        trade_type: project.trade_type,
        budget: project.budget,
        status: project.status,
        bid_count: project.bids.count,
        bids: bids_with_ratings.sort_by { |b| b[:amount] }
      }
    end
    
    render json: {
      contractor_id: contractor_id,
      total_projects: projects.count,
      open_projects: projects.where(status: 'open').count,
      in_progress_projects: projects.where(status: 'in_progress').count,
      completed_projects: projects.where(status: 'completed').count,
      projects: projects_data
    }
  end
end

