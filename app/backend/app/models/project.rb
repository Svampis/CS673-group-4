class Project < ApplicationRecord
  belongs_to :contractor, class_name: 'User', foreign_key: 'contractor_id', optional: true
  belongs_to :homeowner, optional: true
  belongs_to :assigned, class_name: 'Tradesman', foreign_key: 'assigned_id', optional: true

  has_many :bids, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :estimates, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: %w[open in_progress completed cancelled] }
  
  # Get the contractor profile if contractor_id is set
  def contractor_profile
    return nil unless contractor_id
    User.find_by(id: contractor_id)&.contractor
  end
end
