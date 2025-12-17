class Appointment < ApplicationRecord
  belongs_to :worker, class_name: "User", optional: true
  belongs_to :customer, class_name: "User", optional: true
end
