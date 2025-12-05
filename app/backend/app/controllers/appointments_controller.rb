class AppointmentsController < ApiController
  def create
    appointment_params = params.permit(:homeowner_id, :tradesman_id, :scheduled_start, :scheduled_end, :job_description).to_h.symbolize_keys
    appointment = Appointment.new(appointment_params.merge(status: 'pending'))
    
    if appointment.save
      # Notify tradesman of new appointment request
      NotificationService.notify_appointment_created(appointment)
      
      render json: {
        appointment_id: appointment.id,
        status: appointment.status
      }, status: :created
    else
      render_error("Failed to create appointment")
    end
  end
  
  def accept
    appointment = Appointment.find_by(id: params[:id])
    
    if appointment.nil?
      render_error("Appointment not found", :not_found)
    elsif appointment.status != 'pending'
      render_error("Appointment is not pending", :unprocessable_entity)
    else
      reason = params[:reason]
      appointment.accept(reason)
      
      # Notify homeowner
      NotificationService.notify_appointment_accepted(appointment)
      
      # Schedule auto-confirmation job (5 minutes after acceptance)
      AppointmentConfirmationJob.set(wait: 5.minutes).perform_later(appointment.id)
      
      render json: {
        message: "Appointment accepted",
        appointment_id: appointment.id,
        status: appointment.status,
        accepted_at: appointment.accepted_at
      }
    end
  end
  
  def reject
    appointment = Appointment.find_by(id: params[:id])
    
    if appointment.nil?
      render_error("Appointment not found", :not_found)
    elsif appointment.status != 'pending'
      render_error("Appointment is not pending", :unprocessable_entity)
    else
      reason = params[:reason]
      appointment.reject(reason)
      
      # Notify homeowner
      NotificationService.notify_appointment_rejected(appointment, reason)
      
      # Reopen schedule slot if needed
      reopen_schedule_slot(appointment)
      
      render json: {
        message: "Appointment rejected",
        appointment_id: appointment.id,
        status: appointment.status,
        rejected_at: appointment.rejected_at,
        rejection_reason: appointment.rejection_reason
      }
    end
  end
  
  def cancel
    appointment = Appointment.find_by(id: params[:id])
    
    if appointment.nil?
      render_error("Appointment not found", :not_found)
    else
      cancelled_by_user_id = params[:user_id] || appointment.homeowner.user.id
      appointment.cancel
      
      # Notify the other party
      NotificationService.notify_appointment_cancelled(appointment, cancelled_by_user_id)
      
      # Reopen schedule slot
      reopen_schedule_slot(appointment)
      
      render json: { message: "Appointment canceled" }
    end
  end
  
  private
  
  def reopen_schedule_slot(appointment)
    # Find and update the schedule slot to available
    schedule = Schedule.where(
      tradesman_id: appointment.tradesman_id,
      date: appointment.scheduled_start.to_date,
      start_time: appointment.scheduled_start.strftime('%H:%M:%S'),
      end_time: appointment.scheduled_end.strftime('%H:%M:%S')
    ).first
    
    schedule&.update(status: 'available')
  end
end

