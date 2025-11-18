class AppointmentsController < ApiController
  def create
    appointment_params = params.permit(:homeowner_id, :tradesman_id, :scheduled_start, :scheduled_end, :job_description).to_h.symbolize_keys
    appointment = Appointment.new(appointment_params.merge(status: 'pending'))
    
    if appointment.save
      render json: {
        appointment_id: appointment.appointment_id,
        status: appointment.status
      }, status: :created
    else
      render_error("Failed to create appointment")
    end
  end
  
  def cancel
    appointment = Appointment.find_by_id(params[:id])
    
    if appointment.nil?
      render_error("Appointment not found", :not_found)
    else
      appointment.cancel
      render json: { message: "Appointment canceled" }
    end
  end
end

