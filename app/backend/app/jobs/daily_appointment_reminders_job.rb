class DailyAppointmentRemindersJob < ApplicationJob
  queue_as :default
  
  def perform
    # Find all confirmed appointments scheduled for tomorrow
    tomorrow = Date.tomorrow
    appointments = Appointment.where(status: 'confirmed')
                             .where('DATE(scheduled_start) = ?', tomorrow)
    
    appointments.each do |appointment|
      AppointmentReminderJob.perform_now(appointment.id)
    end
  end
end

