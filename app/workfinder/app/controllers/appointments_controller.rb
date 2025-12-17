class AppointmentsController < ApplicationController
  def index
    @appointment = Appointment.new
    @current_user=current_user
    @users = User.all
    if current_user.role == 1
      @scheduled_appointments = Appointment.where(worker_id: current_user.id).where.not(customer_id: nil)
      @appointment_slots = Appointment.where(worker_id: current_user.id).where(customer_id: nil)
    else
      @scheduled_appointments = Appointment.where(customer_id: current_user.id)
    end
  end

  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.save
  end

  def appointment_params
    params.require(:appointment).permit(:worker_id, :start_time, :end_time, :customer_id)
  end

  def schedule
    appointment_id=params[:id]
    user_id=current_user.id
    Appointment.find(appointment_id).update(customer_id: user_id)
  end
  def cancel
    appointment_id=params[:id]
    Appointment.find(appointment_id).update(customer_id: nil)
  end
end
