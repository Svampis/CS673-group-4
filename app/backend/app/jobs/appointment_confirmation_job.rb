class AppointmentConfirmationJob < ApplicationJob
  queue_as :default
  
  def perform(appointment_id)
    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment
    
    # Only send confirmation if appointment is still confirmed
    return unless appointment.status == 'confirmed'
    return if appointment.accepted_at.nil?
    
    # Check if 5 minutes have passed since acceptance
    return if appointment.accepted_at > 5.minutes.ago
    
    # Send confirmation notification (if not already sent)
    # In a real app, you'd check if notification was already sent
    NotificationService.create_notification(
      appointment.homeowner.user.id,
      'appointment_confirmed_reminder',
      'Appointment Confirmed',
      "Your appointment with #{appointment.tradesman.user.name} has been confirmed for #{appointment.scheduled_start.strftime('%B %d, %Y at %I:%M %p')}",
      related: { id: appointment.id, type: 'Appointment' }
    )
  end
end

