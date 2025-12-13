require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def create_user!(email)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "is valid with reviewer and reviewee" do
    reviewer = create_user!("reviewer@test.com")
    reviewee = create_user!("reviewee@test.com")

    review = Review.new(
      reviewer: reviewer,
      reviewee: reviewee
    )

    assert review.valid?
  end

  test "invalid without reviewer" do
    reviewee = create_user!("reviewee@test.com")

    review = Review.new(reviewee: reviewee)

    assert_not review.valid?
    assert_includes review.errors[:reviewer], "must exist"
  end

  test "invalid without reviewee" do
    reviewer = create_user!("reviewer@test.com")

    review = Review.new(reviewer: reviewer)

    assert_not review.valid?
    assert_includes review.errors[:reviewee], "must exist"
  end

  test "reviewer and reviewee are users" do
    reviewer = create_user!("reviewer@test.com")
    reviewee = create_user!("reviewee@test.com")

    review = Review.create!(
      reviewer: reviewer,
      reviewee: reviewee
    )

    assert_instance_of User, review.reviewer
    assert_instance_of User, review.reviewee
  end
end
