class Api::NotificationsController < ApiController
  def index
    user_id = params[:user_id]
    return render_error("User ID required", :bad_request) unless user_id
    
    notifications = Notification.where(user_id: user_id)
                                .order(created_at: :desc)
    
    # Optional filters
    notifications = notifications.unread if params[:unread] == 'true'
    notifications = notifications.by_type(params[:type]) if params[:type].present?
    
    # Limit results if needed
    limit = params[:limit]&.to_i || 50
    notifications = notifications.limit(limit)
    
    render json: notifications.map { |n|
      {
        notification_id: n.id,
        notification_type: n.notification_type,
        title: n.title,
        message: n.message,
        read: n.read,
        read_at: n.read_at,
        related_id: n.related_id,
        related_type: n.related_type,
        created_at: n.created_at
      }
    }
  end
  
  def show
    notification = Notification.find_by(id: params[:id])
    
    if notification.nil?
      render_error("Notification not found", :not_found)
    else
      render json: {
        notification_id: notification.id,
        notification_type: notification.notification_type,
        title: notification.title,
        message: notification.message,
        read: notification.read,
        read_at: notification.read_at,
        related_id: notification.related_id,
        related_type: notification.related_type,
        created_at: notification.created_at,
        updated_at: notification.updated_at
      }
    end
  end
  
  def mark_read
    notification = Notification.find_by(id: params[:id])
    
    if notification.nil?
      render_error("Notification not found", :not_found)
    else
      notification.mark_as_read!
      render json: { message: 'Notification marked as read', notification_id: notification.id }
    end
  end
  
  def mark_all_read
    user_id = params[:user_id]
    return render_error("User ID required", :bad_request) unless user_id
    
    updated_count = Notification.where(user_id: user_id, read: false)
                               .update_all(read: true, read_at: Time.current)
    
    render json: { message: 'All notifications marked as read', updated_count: updated_count }
  end
  
  def unread_count
    user_id = params[:user_id]
    return render_error("User ID required", :bad_request) unless user_id
    
    count = Notification.where(user_id: user_id, read: false).count
    
    render json: { unread_count: count }
  end
end

