class AppointmentReminderJob < ApplicationJob
  queue_as :default
  
  def perform(appointment_id)
    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment
    
    # Check if appointment is still confirmed and scheduled for tomorrow
    return unless appointment.status == 'confirmed'
    return unless appointment.scheduled_start.to_date == Date.tomorrow
    
    # Send reminder notification
    NotificationService.create_notification(
      appointment.homeowner.user.id,
      'appointment_reminder',
      'Appointment Reminder',
      "You have an appointment with #{appointment.tradesman.user.name} tomorrow at #{appointment.scheduled_start.strftime('%I:%M %p')}",
      related: { id: appointment.id, type: 'Appointment' }
    )
    
    # Also notify tradesman
    NotificationService.create_notification(
      appointment.tradesman.user.id,
      'appointment_reminder',
      'Appointment Reminder',
      "You have an appointment with #{appointment.homeowner.user.name} tomorrow at #{appointment.scheduled_start.strftime('%I:%M %p')}",
      related: { id: appointment.id, type: 'Appointment' }
    )
  end
end

