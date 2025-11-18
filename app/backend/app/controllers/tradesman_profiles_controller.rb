class TradesmanProfilesController < ApplicationController
  def show
    @tradesman_id = params[:id]
  end
end
