class Api::Admin::UsersController < ApiController
  before_action :ensure_admin
  
  def index
    users = User.all
    
    # Filter by role
    users = users.where(role: params[:role]) if params[:role].present?
    
    # Filter by status
    users = users.where(status: params[:status]) if params[:status].present?
    
    # Search by name or email
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      users = users.where("email LIKE ?", search_term)
      
      # Also search in profile names (homeowner, tradesman, admin)
      homeowner_ids = Homeowner.where("fname LIKE ? OR lname LIKE ?", search_term, search_term).pluck(:user_id)
      tradesman_ids = Tradesman.where("fname LIKE ? OR lname LIKE ?", search_term, search_term).pluck(:user_id)
      admin_ids = Admin.where("fname LIKE ? OR lname LIKE ?", search_term, search_term).pluck(:user_id)
      
      all_ids = homeowner_ids + tradesman_ids + admin_ids
      users = users.or(User.where(id: all_ids)) if all_ids.any?
    end
    
    # Pagination
    limit = params[:limit]&.to_i || 50
    offset = params[:offset]&.to_i || 0
    users = users.limit(limit).offset(offset).order(created_at: :desc)
    
    render json: users.map { |u|
      {
        user_id: u.id,
        email: u.email,
        role: u.role,
        status: u.status,
        name: get_user_name(u),
        created_at: u.created_at,
        updated_at: u.updated_at
      }
    }
  end
  
  def show
    user = User.find_by(id: params[:id])
    
    if user.nil?
      render_error("User not found", :not_found)
    else
      render json: {
        user_id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
        name: get_user_name(user),
        created_at: user.created_at,
        updated_at: user.updated_at,
        profile: get_user_profile(user)
      }
    end
  end
  
  def suspend
    user = User.find_by(id: params[:id])
    
    if user.nil?
      render_error("User not found", :not_found)
    elsif user.role == 'admin'
      render_error("Cannot suspend admin accounts", :forbidden)
    else
      suspension_reason = params[:reason] || "Account suspended by administrator"
      user.update(status: 'suspended')
      
      # Create notification for user
      NotificationService.create_notification(
        user.id,
        'account_suspended',
        'Account Suspended',
        suspension_reason
      )
      
      render json: {
        message: "User suspended successfully",
        user_id: user.id,
        status: user.status
      }
    end
  end
  
  def activate
    user = User.find_by(id: params[:id])
    
    if user.nil?
      render_error("User not found", :not_found)
    else
      user.update(status: 'activated')
      
      # Create notification for user
      NotificationService.create_notification(
        user.id,
        'account_activated',
        'Account Activated',
        'Your account has been activated'
      )
      
      render json: {
        message: "User activated successfully",
        user_id: user.id,
        status: user.status
      }
    end
  end
  
  def search
    q = params[:q]
    return render_error("Search query required", :bad_request) unless q.present?
    
    search_term = "%#{q}%"
    users = User.where("email LIKE ?", search_term)
    
    # Search in profile names
    homeowner_ids = Homeowner.where("fname LIKE ? OR lname LIKE ?", search_term, search_term).pluck(:user_id)
    tradesman_ids = Tradesman.where("fname LIKE ? OR lname LIKE ?", search_term, search_term).pluck(:user_id)
    admin_ids = Admin.where("fname LIKE ? OR lname LIKE ?", search_term, search_term).pluck(:user_id)
    
    all_ids = homeowner_ids + tradesman_ids + admin_ids
    users = users.or(User.where(id: all_ids)) if all_ids.any?
    
    users = users.limit(20).order(created_at: :desc)
    
    render json: users.map { |u|
      {
        user_id: u.id,
        email: u.email,
        role: u.role,
        status: u.status,
        name: get_user_name(u)
      }
    }
  end
  
  private
  
  def ensure_admin
    # In a real app, check authentication token and verify user is admin
    # For now, we'll skip this check or implement basic token validation
    # admin_user_id = extract_user_id_from_token
    # user = User.find_by(id: admin_user_id)
    # return render_error("Unauthorized", :unauthorized) unless user&.role == 'admin'
  end
  
  def get_user_name(user)
    case user.role
    when 'homeowner'
      homeowner = user.homeowner
      homeowner ? "#{homeowner.fname} #{homeowner.lname}".strip : user.email
    when 'contractor'
      contractor = user.contractor
      contractor ? "#{contractor.fname} #{contractor.lname}".strip : user.email
    when 'tradesman'
      tradesman = user.tradesman
      tradesman ? "#{tradesman.fname} #{tradesman.lname}".strip : user.email
    when 'admin'
      admin = user.admin
      admin ? "#{admin.fname} #{admin.lname}".strip : user.email
    else
      user.email
    end
  end
  
  def get_user_profile(user)
    case user.role
    when 'homeowner'
      h = user.homeowner
      h ? {
        fname: h.fname,
        lname: h.lname,
        street: h.street,
        city: h.city,
        state: h.state,
        number: h.number
      } : {}
    when 'contractor'
      c = user.contractor
      c ? {
        fname: c.fname,
        lname: c.lname,
        street: c.street,
        city: c.city,
        state: c.state,
        number: c.number
      } : {}
    when 'tradesman'
      t = user.tradesman
      t ? {
        fname: t.fname,
        lname: t.lname,
        trade_specialty: t.trade_specialty,
        business_name: t.business_name,
        license_number: t.license_number,
        years_of_experience: t.years_of_experience,
        hourly_rate: t.hourly_rate,
        service_radius: t.service_radius,
        verification_status: t.verification_status,
        street: t.street,
        city: t.city,
        state: t.state,
        number: t.number
      } : nil
    when 'admin'
      a = user.admin
      a ? {
        fname: a.fname,
        lname: a.lname,
        street: a.street,
        city: a.city,
        state: a.state,
        number: a.number
      } : nil
    else
      nil
    end
  end
end

