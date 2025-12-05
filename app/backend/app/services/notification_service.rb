class NotificationService
  def self.create_notification(user_id, notification_type, title, message, related: nil)
    notification_params = {
      user_id: user_id,
      notification_type: notification_type,
      title: title,
      message: message,
      read: false
    }
    
    if related
      notification_params[:related_id] = related[:id]
      notification_params[:related_type] = related[:type]
    end
    
    Notification.create(notification_params)
  end
  
  def self.notify_appointment_created(appointment)
    tradesman = appointment.tradesman
    homeowner = appointment.homeowner
    
    # Notify tradesman of new appointment request
    create_notification(
      tradesman.user.id,
      'appointment_request',
      'New Appointment Request',
      "You have received a new appointment request from #{homeowner.user.name}",
      related: { id: appointment.id, type: 'Appointment' }
    )
  end
  
  def self.notify_appointment_accepted(appointment)
    homeowner = appointment.homeowner
    
    create_notification(
      homeowner.user.id,
      'appointment_confirmed',
      'Appointment Confirmed',
      "Your appointment with #{appointment.tradesman.user.name} has been confirmed",
      related: { id: appointment.id, type: 'Appointment' }
    )
  end
  
  def self.notify_appointment_rejected(appointment, reason = nil)
    homeowner = appointment.homeowner
    message = "Your appointment request with #{appointment.tradesman.user.name} has been rejected"
    message += ". Reason: #{reason}" if reason.present?
    
    create_notification(
      homeowner.user.id,
      'appointment_rejected',
      'Appointment Rejected',
      message,
      related: { id: appointment.id, type: 'Appointment' }
    )
  end
  
  def self.notify_appointment_cancelled(appointment, cancelled_by_user_id)
    # Notify the other party
    if cancelled_by_user_id == appointment.homeowner.user.id
      notify_user_id = appointment.tradesman.user.id
      other_party_name = appointment.homeowner.user.name
    else
      notify_user_id = appointment.homeowner.user.id
      other_party_name = appointment.tradesman.user.name
    end
    
    create_notification(
      notify_user_id,
      'appointment_cancelled',
      'Appointment Cancelled',
      "Your appointment with #{other_party_name} has been cancelled",
      related: { id: appointment.id, type: 'Appointment' }
    )
  end
  
  def self.notify_new_bid(bid)
    project = bid.project
    contractor = project.contractor
    
    return unless contractor
    
    create_notification(
      contractor.id,
      'new_bid',
      'New Bid Received',
      "#{bid.tradesman.user.name} has placed a bid of $#{bid.amount} on your project: #{project.title}",
      related: { id: bid.id, type: 'Bid' }
    )
  end
  
  def self.notify_bid_accepted(bid)
    tradesman = bid.tradesman
    
    create_notification(
      tradesman.user.id,
      'bid_accepted',
      'Bid Accepted',
      "Your bid of $#{bid.amount} has been accepted for project: #{bid.project.title}",
      related: { id: bid.id, type: 'Bid' }
    )
  end
  
  def self.notify_bid_rejected(bid)
    tradesman = bid.tradesman
    
    create_notification(
      tradesman.user.id,
      'bid_rejected',
      'Bid Rejected',
      "Your bid of $#{bid.amount} has been rejected for project: #{bid.project.title}",
      related: { id: bid.id, type: 'Bid' }
    )
  end
  
  def self.notify_estimate_created(estimate)
    homeowner = estimate.homeowner
    
    create_notification(
      homeowner.user.id,
      'new_estimate',
      'New Estimate Received',
      "You have received a new estimate of $#{estimate.amount} from #{estimate.tradesman.user.name}",
      related: { id: estimate.id, type: 'Estimate' }
    )
  end
  
  def self.notify_estimate_updated(estimate)
    homeowner = estimate.homeowner
    
    create_notification(
      homeowner.user.id,
      'estimate_updated',
      'Estimate Updated',
      "Your estimate from #{estimate.tradesman.user.name} has been updated to $#{estimate.amount}",
      related: { id: estimate.id, type: 'Estimate' }
    )
  end
  
  def self.notify_estimate_accepted(estimate)
    tradesman = estimate.tradesman
    
    create_notification(
      tradesman.user.id,
      'estimate_accepted',
      'Estimate Accepted',
      "Your estimate of $#{estimate.amount} has been accepted",
      related: { id: estimate.id, type: 'Estimate' }
    )
  end
  
  def self.notify_estimate_rejected(estimate)
    tradesman = estimate.tradesman
    
    create_notification(
      tradesman.user.id,
      'estimate_rejected',
      'Estimate Rejected',
      "Your estimate of $#{estimate.amount} has been rejected",
      related: { id: estimate.id, type: 'Estimate' }
    )
  end
  
  def self.notify_new_message(message)
    # For messages, we need to find the receiver from the conversation
    # Since messages use conversations, we'll need to get the receiver differently
    conversation = message.conversation
    return unless conversation
    
    # Determine receiver based on conversation participants
    receiver_id = conversation.participant1_id == message.sender_id ? conversation.participant2_id : conversation.participant1_id
    receiver = User.find_by(id: receiver_id)
    sender = User.find_by(id: message.sender_id)
    
    return unless receiver && sender
    
    create_notification(
      receiver.id,
      'new_message',
      'New Message',
      "You have a new message from #{sender.name}",
      related: { id: message.id, type: 'Message' }
    )
  end
  
  def self.notify_new_review(review)
    tradesman = review.tradesman
    
    create_notification(
      tradesman.user.id,
      'new_review',
      'New Review Received',
      "You have received a new #{review.rating}-star review",
      related: { id: review.id, type: 'Review' }
    )
  end
  
  def self.notify_tradesman_verification_approved(tradesman_verification)
    tradesman = tradesman_verification.tradesman
    
    create_notification(
      tradesman.user.id,
      'verification_approved',
      'Account Verified',
      'Your tradesman account has been verified and approved',
      related: { id: tradesman_verification.id, type: 'TradesmanVerification' }
    )
  end
  
  def self.notify_tradesman_verification_rejected(tradesman_verification, reason = nil)
    tradesman = tradesman_verification.tradesman
    message = 'Your tradesman account verification has been rejected'
    message += ". Reason: #{reason}" if reason.present?
    
    create_notification(
      tradesman.user.id,
      'verification_rejected',
      'Verification Rejected',
      message,
      related: { id: tradesman_verification.id, type: 'TradesmanVerification' }
    )
  end
end

