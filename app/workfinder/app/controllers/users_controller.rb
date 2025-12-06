class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @appointments = Appointment.where(worker_id: @user.id, customer_id: nil)
  end
end
