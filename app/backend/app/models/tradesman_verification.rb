class TradesmanVerification < ApplicationRecord
  belongs_to :tradesman
  belongs_to :admin, optional: true

  validates :status, inclusion: { in: %w[pending approved rejected] }
end

