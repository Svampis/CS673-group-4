class ReviewsController < ApplicationController
  def show
    @review = Review.new
    @reviewer = current_user
    if params[:id].present?
      @reviewee = User.find(params[:id])
      @reviews = Review.includes(:reviewee).where("reviewee_id = ?", params[:id])
    else
      @reviews = []
    end
  end
  def create
    @review = Review.new(review_params)
    @review.save
  end

  def review_params
    params.require(:review).permit(:body, :reviewer_id, :reviewee_id, :rating)
  end
end
