class ProfilesController < ApiController
  def show
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    
    if user.nil?
      return render_error("User not found", :not_found)
    end
    
    # Get user name from related model
    user_name = get_user_name(user)
    
    # Build address from related model
    address = get_user_address(user)
    
    # Build base profile response (excluding sensitive data like password_hash)
    response_data = {
      user_id: user.id,
      name: user_name,
      email: user.email,
      role: user.role,
      status: user.status,
      address: address
    }
    
    # If tradesman, include tradesman-specific profile data
    if user.role == 'tradesman'
      tradesman = user.tradesman
      if tradesman
        response_data[:profile] = {
          fname: tradesman.fname,
          lname: tradesman.lname,
          license_number: tradesman.license_number,
          trade_specialty: tradesman.trade_specialty,
          years_of_experience: tradesman.years_of_experience,
          rating: tradesman.rating,
          business_name: tradesman.business_name,
          hourly_rate: tradesman.hourly_rate,
          service_radius: tradesman.service_radius,
          verification_status: tradesman.verification_status,
          street: tradesman.street,
          city: tradesman.city,
          state: tradesman.state,
          number: tradesman.number
        }
      end
    # If contractor, include contractor-specific profile data
    elsif user.role == 'contractor'
      contractor = user.contractor
      if contractor
        response_data[:profile] = {
          fname: contractor.fname,
          lname: contractor.lname,
          street: contractor.street,
          city: contractor.city,
          state: contractor.state,
          number: contractor.number
        }
      end
    # If homeowner, include homeowner-specific profile data
    elsif user.role == 'homeowner'
      homeowner = user.homeowner
      if homeowner
        response_data[:profile] = {
          fname: homeowner.fname,
          lname: homeowner.lname,
          street: homeowner.street,
          city: homeowner.city,
          state: homeowner.state,
          number: homeowner.number
        }
      end
    # If admin, include admin-specific profile data
    elsif user.role == 'admin'
      admin = user.admin
      if admin
        response_data[:profile] = {
          fname: admin.fname,
          lname: admin.lname,
          street: admin.street,
          city: admin.city,
          state: admin.state,
          number: admin.number
        }
      end
    end
    
    render json: response_data
  end
  
  def update
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    
    if user.nil?
      return render_error("User not found", :not_found)
    end
    
    update_params = params.permit(:name, profile: {}).to_h.symbolize_keys
    
    # Update name in role-specific profile
    if update_params[:name]
      name_parts = parse_name(update_params[:name])
      
      case user.role
      when 'tradesman'
        tradesman = user.tradesman
        if tradesman
          tradesman.fname = name_parts[:fname] if name_parts[:fname]
          tradesman.lname = name_parts[:lname] if name_parts[:lname]
          tradesman.save
        end
      when 'contractor'
        contractor = user.contractor
        if contractor
          contractor.fname = name_parts[:fname] if name_parts[:fname]
          contractor.lname = name_parts[:lname] if name_parts[:lname]
          contractor.save
        end
      when 'homeowner'
        homeowner = user.homeowner
        if homeowner
          homeowner.fname = name_parts[:fname] if name_parts[:fname]
          homeowner.lname = name_parts[:lname] if name_parts[:lname]
          homeowner.save
        end
      when 'admin'
        admin = user.admin
        if admin
          admin.fname = name_parts[:fname] if name_parts[:fname]
          admin.lname = name_parts[:lname] if name_parts[:lname]
          admin.save
        end
      end
    end
    
    # Update profile fields if provided
    if update_params[:profile]
      case user.role
      when 'tradesman'
        tradesman = user.tradesman
        if tradesman
          tradesman.update(update_params[:profile].slice(:street, :city, :state, :number, :business_name, :hourly_rate, :service_radius))
        end
      when 'contractor'
        contractor = user.contractor
        if contractor
          contractor.update(update_params[:profile].slice(:street, :city, :state, :number))
        end
      when 'homeowner'
        homeowner = user.homeowner
        if homeowner
          homeowner.update(update_params[:profile].slice(:street, :city, :state, :number))
        end
      end
    end
    
    render json: { message: "Profile updated successfully" }
  end
  
  private
  
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
  
  def get_user_address(user)
    case user.role
    when 'homeowner'
      homeowner = user.homeowner
      if homeowner && (homeowner.street || homeowner.city || homeowner.state)
        parts = [homeowner.street, homeowner.city, homeowner.state].compact
        parts.join(', ') if parts.any?
      end
    when 'contractor'
      contractor = user.contractor
      if contractor && (contractor.street || contractor.city || contractor.state)
        parts = [contractor.street, contractor.city, contractor.state].compact
        parts.join(', ') if parts.any?
      end
    when 'tradesman'
      tradesman = user.tradesman
      if tradesman && (tradesman.street || tradesman.city || tradesman.state)
        parts = [tradesman.street, tradesman.city, tradesman.state].compact
        parts.join(', ') if parts.any?
      end
    end
  end
  
  def parse_name(name)
    return { fname: '', lname: '' } if name.blank?
    
    parts = name.split(' ')
    if parts.length == 1
      { fname: parts[0], lname: '' }
    else
      { fname: parts[0], lname: parts[1..-1].join(' ') }
    end
  end
end

