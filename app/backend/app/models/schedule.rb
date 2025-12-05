class Schedule < ApplicationRecord
  belongs_to :tradesman

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, inclusion: { in: %w[available booked unavailable] }
end
