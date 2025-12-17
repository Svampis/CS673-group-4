class UsersController < ApplicationController
  def index
    @users = User.all
    if params[:city].present?
      @users = @users.where("city LIKE ?", "%" + params[:city] + "%")
    end
    if params[:state].present?
      @users = @users.where("state LIKE ?", "%" + params[:state] + "%")
    end
  end

  def show
    @visitor = current_user
    @user = User.find(params[:id])
    @appointments = Appointment.where(worker_id: @user.id, customer_id: nil)
  end
end
