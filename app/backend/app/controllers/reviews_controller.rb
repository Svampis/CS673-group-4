class ReviewsController < ApiController
  def create
    review_params = params.permit(:homeowner_id, :tradesman_id, :appointment_id, :rating, :comment).to_h.symbolize_keys
    review = Review.new(review_params)
    
    if review.save
      render json: { message: "Review submitted successfully" }, status: :created
    else
      render_error("Failed to submit review")
    end
  end
  
  def show
    tradesman_id = params[:tradesman_id]
    reviews = Review.find_by_tradesman_id(tradesman_id)
    
    render json: reviews.map { |r|
      {
        review_id: r.review_id,
        homeowner_id: r.homeowner_id,
        rating: r.rating,
        comment: r.comment,
        timestamp: r.timestamp
      }
    }
  end
end

