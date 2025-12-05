class Conversation < ApplicationRecord
  belongs_to :participant1, class_name: 'User', foreign_key: 'participant1_id'
  belongs_to :participant2, class_name: 'User', foreign_key: 'participant2_id'

  has_many :messages, dependent: :destroy

  # Find or create conversation between two users
  def self.find_or_create_between(user1_id, user2_id)
    # Ensure consistent ordering (smaller ID first)
    id1, id2 = [user1_id, user2_id].sort

    find_or_create_by(participant1_id: id1, participant2_id: id2) do |conversation|
      # Conversation created
    end
  end
end

