class Api::Admin::TradesmanVerificationsController < ApiController
  before_action :ensure_admin
  
  def index
    status = params[:status] || 'pending'
    verifications = TradesmanVerification.where(status: status)
                                        .includes(:tradesman, :admin)
                                        .order(created_at: :desc)
    
    render json: verifications.map { |v|
      tradesman = v.tradesman
      {
        verification_id: v.id,
        tradesman_id: tradesman.id,
        tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
        tradesman_email: tradesman.user.email,
        trade_specialty: tradesman.trade_specialty,
        license_number: tradesman.license_number,
        business_name: tradesman.business_name,
        years_of_experience: tradesman.years_of_experience,
        status: v.status,
        reviewed_by: v.admin ? "#{v.admin.fname} #{v.admin.lname}" : nil,
        reviewed_at: v.reviewed_at,
        rejection_reason: v.rejection_reason,
        submitted_at: v.created_at
      }
    }
  end
  
  def show
    verification = TradesmanVerification.find_by(id: params[:id])
    
    if verification.nil?
      render_error("Verification not found", :not_found)
    else
      tradesman = verification.tradesman
      render json: {
        verification_id: verification.id,
        tradesman_id: tradesman.id,
        tradesman_name: "#{tradesman.fname} #{tradesman.lname}",
        tradesman_email: tradesman.user.email,
        trade_specialty: tradesman.trade_specialty,
        license_number: tradesman.license_number,
        business_name: tradesman.business_name,
        years_of_experience: tradesman.years_of_experience,
        description: tradesman.description,
        street: tradesman.street,
        city: tradesman.city,
        state: tradesman.state,
        number: tradesman.number,
        status: verification.status,
        reviewed_by: verification.admin ? "#{verification.admin.fname} #{verification.admin.lname}" : nil,
        reviewed_at: verification.reviewed_at,
        rejection_reason: verification.rejection_reason,
        submitted_at: verification.created_at,
        updated_at: verification.updated_at
      }
    end
  end
  
  def approve
    verification = TradesmanVerification.find_by(id: params[:id])
    
    if verification.nil?
      render_error("Verification not found", :not_found)
    elsif verification.status != 'pending'
      render_error("Verification is not pending", :unprocessable_entity)
    else
      # Get admin user (in real app, from auth token)
      # admin_user = current_user
      # admin = admin_user.admin
      
      # For now, we'll just approve without tracking which admin
      verification.update(
        status: 'approved',
        reviewed_at: Time.current
        # admin: admin  # Uncomment when auth is implemented
      )
      
      # Activate tradesman account
      tradesman = verification.tradesman
      tradesman.update(verification_status: 'approved')
      tradesman.user.update(status: 'activated')
      
      # Notify tradesman
      NotificationService.notify_tradesman_verification_approved(verification)
      
      render json: {
        message: "Tradesman verification approved",
        verification_id: verification.id,
        tradesman_id: tradesman.id,
        status: verification.status
      }
    end
  end
  
  def reject
    verification = TradesmanVerification.find_by(id: params[:id])
    reason = params[:reason] || "Verification rejected by administrator"
    
    if verification.nil?
      render_error("Verification not found", :not_found)
    elsif verification.status != 'pending'
      render_error("Verification is not pending", :unprocessable_entity)
    else
      # Get admin user (in real app, from auth token)
      # admin_user = current_user
      # admin = admin_user.admin
      
      # For now, we'll just reject without tracking which admin
      verification.update(
        status: 'rejected',
        rejection_reason: reason,
        reviewed_at: Time.current
        # admin: admin  # Uncomment when auth is implemented
      )
      
      # Update tradesman status
      tradesman = verification.tradesman
      tradesman.update(verification_status: 'rejected')
      
      # Notify tradesman
      NotificationService.notify_tradesman_verification_rejected(verification, reason)
      
      render json: {
        message: "Tradesman verification rejected",
        verification_id: verification.id,
        tradesman_id: tradesman.id,
        status: verification.status,
        reason: reason
      }
    end
  end
  
  private
  
  def ensure_admin
    # In a real app, check authentication token and verify user is admin
    # For now, we'll skip this check or implement basic token validation
    # admin_user_id = extract_user_id_from_token
    # user = User.find_by(id: admin_user_id)
    # return render_error("Unauthorized", :unauthorized) unless user&.role == 'admin'
  end
end

