class TradesmenListingController < ApplicationController
  before_action :require_authentication
  
  def index
  end
  
  private
  
  def require_authentication
    # Check if user is authenticated via localStorage (handled in frontend)
    # This is a basic check - in production, use proper session/token validation
    # For now, we'll let the frontend handle the redirect
  end
end

