class Admin < ApplicationRecord
  belongs_to :user

  has_many :tradesman_verifications, dependent: :destroy
end

