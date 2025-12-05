class Estimate < ApplicationRecord
  belongs_to :tradesman
  belongs_to :homeowner
  belongs_to :appointment, optional: true
  belongs_to :project, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  validates :version, presence: true, numericality: { greater_than: 0 }
  
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :by_homeowner, ->(homeowner_id) { where(homeowner_id: homeowner_id) }
  scope :by_tradesman, ->(tradesman_id) { where(tradesman_id: tradesman_id) }
end

