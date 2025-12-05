class Homeowner < ApplicationRecord
  belongs_to :user

  has_many :appointments, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :estimates, dependent: :destroy
end

