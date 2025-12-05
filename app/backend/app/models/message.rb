class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'

  validates :content, presence: true

  # Mark message as read
  def mark_as_read!
    update(read_at: Time.current)
  end

  # Class methods for backward compatibility during migration
  def self.find_by_conversation_id(conversation_id)
    # Try to find by conversation ID (integer)
    if conversation_id.to_s.match?(/^\d+$/)
      conversation = Conversation.find_by(id: conversation_id)
      return conversation&.messages&.order(:created_at) || []
    end
    
    # Legacy: Try to find by appointment_id or user IDs
    # This is for backward compatibility during migration
    []
  end

  def self.find_conversations_for_user(user_id)
    # Find all conversations where user is a participant
    conversations = Conversation.where(
      'participant1_id = ? OR participant2_id = ?', user_id, user_id
    ).includes(:messages).order('messages.created_at DESC')
    
    conversations.map do |conv|
      other_user_id = conv.participant1_id == user_id.to_i ? conv.participant2_id : conv.participant1_id
      last_message = conv.messages.order(:created_at).last
      
      {
        conversation_id: conv.id,
        appointment_id: nil, # Will be handled separately if needed
        other_user_id: other_user_id,
        last_message: last_message,
        unread_count: conv.messages.where('sender_id != ? AND read_at IS NULL', user_id).count
      }
    end
  end

  def self.unread_count(user_id, conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return 0 unless conversation
    
    conversation.messages.where('sender_id != ? AND read_at IS NULL', user_id).count
  end
end
