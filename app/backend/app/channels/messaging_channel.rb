class MessagingChannel < ApplicationCable::Channel
  def subscribed
    conversation_id = params[:conversation_id]
    user_id = params[:user_id]
    
    # Verify user has access to this conversation
    if authorized?(user_id, conversation_id)
      stream_from "conversation_#{conversation_id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def authorized?(user_id, conversation_id)
    return false unless user_id && conversation_id
    
    # Check if user is part of this conversation
    # Allow if user has any messages in this conversation or if it's a new conversation
    messages = Message.find_by_conversation_id(conversation_id)
    return true if messages.empty? # New conversation, allow
    messages.any? { |m| m.sender_id == user_id || m.receiver_id == user_id }
  end
end

