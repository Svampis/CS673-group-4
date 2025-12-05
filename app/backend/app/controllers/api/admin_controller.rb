class Api::AdminController < ApiController
  before_action :ensure_admin
  
  def dashboard
    stats = {
      total_users: User.count,
      users_by_role: {
        homeowner: User.where(role: 'homeowner').count,
        tradesman: User.where(role: 'tradesman').count,
        contractor: User.where(role: 'contractor').count,
        admin: User.where(role: 'admin').count
      },
      users_by_status: {
        activated: User.where(status: 'activated').count,
        deactivated: User.where(status: 'deactivated').count,
        suspended: User.where(status: 'suspended').count
      },
      pending_verifications: TradesmanVerification.where(status: 'pending').count,
      total_projects: Project.count,
      open_projects: Project.where(status: 'open').count,
      total_appointments: Appointment.count,
      pending_appointments: Appointment.where(status: 'pending').count
    }
    
    render json: stats
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

