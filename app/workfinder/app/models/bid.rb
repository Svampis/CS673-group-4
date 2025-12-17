class Bid < ApplicationRecord
  belongs_to :project_id, class_name: "Project"
  belongs_to :bidder_id, class_name: "User"
end
