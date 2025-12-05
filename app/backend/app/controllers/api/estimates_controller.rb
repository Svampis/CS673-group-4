class Api::EstimatesController < ApiController
  def create
    if params[:appointment_id].present?
      create_for_appointment
    elsif params[:project_id].present?
      create_for_project
    else
      render_error("appointment_id or project_id is required", :bad_request)
    end
  end
  
  def update
    estimate = Estimate.find_by(id: params[:id])
    
    if estimate.nil?
      render_error("Estimate not found", :not_found)
    else
      estimate_params = params.permit(:amount, :notes).to_h.symbolize_keys
      
      # Create new version
      new_version = estimate.version + 1
      
      # Create a new estimate record for versioning
      new_estimate = Estimate.create!(
        tradesman_id: estimate.tradesman_id,
        homeowner_id: estimate.homeowner_id,
        appointment_id: estimate.appointment_id,
        project_id: estimate.project_id,
        amount: estimate_params[:amount] || estimate.amount,
        notes: estimate_params[:notes] || estimate.notes,
        status: 'pending',
        version: new_version
      )
      
      # Notify homeowner of updated estimate
      NotificationService.notify_estimate_updated(new_estimate)
      
      render json: {
        estimate_id: new_estimate.id,
        version: new_estimate.version,
        amount: new_estimate.amount,
        status: new_estimate.status,
        created_at: new_estimate.created_at
      }
    end
  end
  
  def show
    estimate = Estimate.find_by(id: params[:id])
    
    if estimate.nil?
      render_error("Estimate not found", :not_found)
    else
      tradesman = estimate.tradesman
      homeowner = estimate.homeowner
      
      render json: {
        estimate_id: estimate.id,
        tradesman_id: estimate.tradesman_id,
        tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
        homeowner_id: estimate.homeowner_id,
        homeowner_name: "#{homeowner.fname} #{homeowner.lname}",
        appointment_id: estimate.appointment_id,
        project_id: estimate.project_id,
        amount: estimate.amount,
        notes: estimate.notes,
        status: estimate.status,
        version: estimate.version,
        created_at: estimate.created_at,
        updated_at: estimate.updated_at
      }
    end
  end
  
  def history
    estimate_id = params[:id]
    
    # Get the original estimate
    original_estimate = Estimate.find_by(id: estimate_id)
    return render_error("Estimate not found", :not_found) unless original_estimate
    
    # Find all estimates with same tradesman, homeowner, and appointment/project
    if original_estimate.appointment_id.present?
      estimates = Estimate.where(
        tradesman_id: original_estimate.tradesman_id,
        homeowner_id: original_estimate.homeowner_id,
        appointment_id: original_estimate.appointment_id
      ).order(version: :asc)
    else
      estimates = Estimate.where(
        tradesman_id: original_estimate.tradesman_id,
        homeowner_id: original_estimate.homeowner_id,
        project_id: original_estimate.project_id
      ).order(version: :asc)
    end
    
    render json: estimates.map { |e|
      {
        estimate_id: e.id,
        version: e.version,
        amount: e.amount,
        notes: e.notes,
        status: e.status,
        created_at: e.created_at
      }
    }
  end
  
  def accept
    estimate = Estimate.find_by(id: params[:id])
    
    if estimate.nil?
      render_error("Estimate not found", :not_found)
    elsif estimate.status != 'pending'
      render_error("Only pending estimates can be accepted", :unprocessable_entity)
    else
      estimate.update(status: 'accepted')
      
      # Notify tradesman
      NotificationService.notify_estimate_accepted(estimate)
      
      render json: {
        message: "Estimate accepted",
        estimate_id: estimate.id,
        status: estimate.status
      }
    end
  end
  
  def reject
    estimate = Estimate.find_by(id: params[:id])
    
    if estimate.nil?
      render_error("Estimate not found", :not_found)
    elsif estimate.status != 'pending'
      render_error("Only pending estimates can be rejected", :unprocessable_entity)
    else
      estimate.update(status: 'rejected')
      
      # Notify tradesman
      NotificationService.notify_estimate_rejected(estimate)
      
      render json: {
        message: "Estimate rejected",
        estimate_id: estimate.id,
        status: estimate.status
      }
    end
  end
  
  def index
    if params[:homeowner_id].present?
      # Get estimates received by homeowner
      homeowner_id = params[:homeowner_id]
      estimates = Estimate.where(homeowner_id: homeowner_id)
                         .includes(:tradesman)
                         .order(created_at: :desc)
      
      render json: estimates.map { |e|
        tradesman = e.tradesman
        {
          estimate_id: e.id,
          tradesman_id: e.tradesman_id,
          tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
          amount: e.amount,
          status: e.status,
          version: e.version,
          created_at: e.created_at
        }
      }
    elsif params[:tradesman_id].present?
      # Get estimates sent by tradesman
      tradesman_id = params[:tradesman_id]
      estimates = Estimate.where(tradesman_id: tradesman_id)
                        .includes(:homeowner)
                        .order(created_at: :desc)
      
      render json: estimates.map { |e|
        homeowner = e.homeowner
        {
          estimate_id: e.id,
          homeowner_id: e.homeowner_id,
          homeowner_name: "#{homeowner.fname} #{homeowner.lname}",
          amount: e.amount,
          status: e.status,
          version: e.version,
          created_at: e.created_at
        }
      }
    else
      render_error("homeowner_id or tradesman_id is required", :bad_request)
    end
  end
  
  private
  
  def create_for_appointment
    appointment_id = params[:appointment_id]
    appointment = Appointment.find_by(id: appointment_id)
    
    return render_error("Appointment not found", :not_found) unless appointment
    
    estimate_params = params.permit(:amount, :notes).to_h.symbolize_keys
    
    if estimate_params[:amount].blank?
      return render_error("amount is required", :bad_request)
    end
    
    estimate = Estimate.new(
      tradesman_id: appointment.tradesman_id,
      homeowner_id: appointment.homeowner_id,
      appointment_id: appointment_id,
      amount: estimate_params[:amount],
      notes: estimate_params[:notes],
      status: 'pending',
      version: 1
    )
    
    if estimate.save
      NotificationService.notify_estimate_created(estimate)
      
      render json: {
        estimate_id: estimate.id,
        appointment_id: estimate.appointment_id,
        amount: estimate.amount,
        status: estimate.status,
        version: estimate.version,
        created_at: estimate.created_at
      }, status: :created
    else
      render_error("Failed to create estimate: #{estimate.errors.full_messages.join(', ')}")
    end
  end
  
  def create_for_project
    project_id = params[:project_id]
    project = Project.find_by(id: project_id)
    
    return render_error("Project not found", :not_found) unless project
    
    estimate_params = params.permit(:tradesman_id, :homeowner_id, :amount, :notes).to_h.symbolize_keys
    
    if estimate_params[:amount].blank? || estimate_params[:tradesman_id].blank? || estimate_params[:homeowner_id].blank?
      return render_error("tradesman_id, homeowner_id, and amount are required", :bad_request)
    end
    
    estimate = Estimate.new(
      tradesman_id: estimate_params[:tradesman_id],
      homeowner_id: estimate_params[:homeowner_id],
      project_id: project_id,
      amount: estimate_params[:amount],
      notes: estimate_params[:notes],
      status: 'pending',
      version: 1
    )
    
    if estimate.save
      NotificationService.notify_estimate_created(estimate)
      
      render json: {
        estimate_id: estimate.id,
        project_id: estimate.project_id,
        amount: estimate.amount,
        status: estimate.status,
        version: estimate.version,
        created_at: estimate.created_at
      }, status: :created
    else
      render_error("Failed to create estimate: #{estimate.errors.full_messages.join(', ')}")
    end
  end
end

