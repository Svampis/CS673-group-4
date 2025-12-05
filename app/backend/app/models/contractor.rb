class Contractor < ApplicationRecord
  belongs_to :user

  has_many :projects, dependent: :destroy, foreign_key: 'contractor_id'
  has_many :bids, through: :projects
end

