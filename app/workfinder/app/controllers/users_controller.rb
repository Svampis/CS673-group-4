class UsersController < ApplicationController
  def index
    if params[:city].present?
      @users = User.where("city LIKE ?", "%" + params[:city] + "%")
    else
      @users = User.all
    end
  end

  def show
    @visitor = current_user
    @user = User.find(params[:id])
    @appointments = Appointment.where(worker_id: @user.id, customer_id: nil)
  end
end
