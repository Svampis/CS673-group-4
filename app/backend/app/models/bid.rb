class Bid < ApplicationRecord
  belongs_to :project
  belongs_to :tradesman
  belongs_to :appointment, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_tradesman, ->(tradesman_id) { where(tradesman_id: tradesman_id) }
end

