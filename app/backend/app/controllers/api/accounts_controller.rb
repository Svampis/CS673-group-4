class Api::AccountsController < ApiController
  def destroy
    user_id = params[:id]
    current_user_id = params[:current_user_id] # In real app, get from auth token
    
    return render_error("User ID required", :bad_request) unless user_id
    
    user = User.find_by(id: user_id)
    return render_error("User not found", :not_found) unless user
    
    # Authorization check: users can only delete their own account, or must be admin
    if current_user_id.present?
      current_user = User.find_by(id: current_user_id)
      unless current_user && (current_user.id == user.id || current_user.role == 'admin')
        return render_error("Unauthorized to delete this account", :forbidden)
      end
    end
    
    # Soft delete: set status to deactivated
    # In production, you might want to actually delete or use a deleted_at timestamp
    user.update(status: 'deactivated')
    
    # Optionally, delete associated records
    # user.homeowner&.destroy
    # user.contractor&.destroy
    # user.tradesman&.destroy
    # user.admin&.destroy
    
    render json: {
      message: "Account deleted successfully",
      user_id: user.id
    }
  end
end

