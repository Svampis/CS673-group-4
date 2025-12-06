class Appointment < ApplicationRecord
  belongs_to :worker, class_name: "User"
  belongs_to :customer, class_name: "User"
end
