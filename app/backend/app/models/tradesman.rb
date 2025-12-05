class Tradesman < ApplicationRecord
  belongs_to :user

  has_many :schedules, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :bids, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :estimates, dependent: :destroy
  has_one :tradesman_verification, dependent: :destroy

  validates :trade_specialty, inclusion: { in: %w[plumber electrician hvac\ worker] }, allow_nil: true
  validates :verification_status, inclusion: { in: %w[pending approved rejected] }, allow_nil: true

  # Scopes for filtering
  scope :by_trade, ->(trade) { where(trade_specialty: trade) }
  scope :by_location, ->(city) { where(city: city) }
  # Note: by_rating scope would need a subquery since rating is calculated
  # scope :by_rating, ->(min_rating) { joins(:reviews).group('tradesmen.id').having('AVG(reviews.rating) >= ?', min_rating) }
  scope :verified, -> { where(verification_status: 'approved') }
  scope :pending_verification, -> { where(verification_status: 'pending') }

  # Calculate rating from reviews (virtual attribute)
  def rating
    reviews.average(:rating)&.round(1) || 0.0
  end
end
