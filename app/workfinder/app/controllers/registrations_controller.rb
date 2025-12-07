class RegistrationsController < ApplicationController
  layout false, only: [ :new ]
  allow_unauthenticated_access only: [ :new, :create ]
  def user_params
    params.require(:user).permit(
      :name,
      :username,
      :email,
      :password,
      :password_confirmation,
      :role,
      :city,
      :state,
      :description
    )
  end
  def new
    @user = User.new
  end
  def create
    @user = User.new(user_params)
    if @user.save
      # Optional: log the user in immediately
      cookies.signed.permanent[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome, #{@user.name}!"
    else
      # Re-render the form with errors
      render :new
    end
  end
end
