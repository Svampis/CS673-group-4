class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :owned_projects, class_name: "Project", foreign_key: "owner_id"
end
