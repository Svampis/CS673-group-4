class Review < ApplicationRecord
  belongs_to :homeowner
  belongs_to :tradesman
  belongs_to :appointment, optional: true

  validates :rating, presence: true, numericality: { in: 1..5 }
  validates :comment, presence: true

  # Note: Rating is calculated from reviews, not stored in tradesmen table
  # Use tradesman.reviews.average(:rating) to get current rating
end
