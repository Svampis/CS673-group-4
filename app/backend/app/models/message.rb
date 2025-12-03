class Message
  attr_accessor :message_id, :sender_id, :receiver_id, :appointment_id, 
                :content, :timestamp, :attachment_url, :read, :read_at
  
  def initialize(attributes = {})
    @message_id = attributes[:message_id] || JsonStorage.generate_id
    @sender_id = attributes[:sender_id]
    @receiver_id = attributes[:receiver_id]
    @appointment_id = attributes[:appointment_id]
    @content = attributes[:content]
    @timestamp = attributes[:timestamp] || Time.now.utc.iso8601
    @attachment_url = attributes[:attachment_url]
    @read = attributes[:read] || false
    @read_at = attributes[:read_at]
  end
  
  def self.all
    data = JsonStorage.read('messages')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.conversation_id(user1_id, user2_id, appointment_id = nil)
    return appointment_id if appointment_id.present?
    # Generate consistent conversation ID by sorting user IDs
    [user1_id, user2_id].sort.join('_')
  end
  
  def self.find_by_conversation_id(conversation_id)
    # conversation_id can be appointment_id or a combination of sender_id and receiver_id
    all.select do |m|
      if m.appointment_id.present?
        m.appointment_id == conversation_id
      else
        # For user-to-user conversations, check if conversation_id matches the sorted user IDs
        sorted_ids = [m.sender_id, m.receiver_id].sort.join('_')
        sorted_ids == conversation_id
      end
    end.sort_by { |m| m.timestamp || '' }
  end
  
  def self.find_conversations_for_user(user_id)
    # Get all unique conversations for a user
    user_messages = all.select do |m|
      m.sender_id == user_id || m.receiver_id == user_id
    end
    
    # Group by conversation
    conversations = {}
    user_messages.each do |message|
      conv_id = if message.appointment_id.present?
        message.appointment_id
      else
        [message.sender_id, message.receiver_id].sort.join('_')
      end
      
      conversations[conv_id] ||= {
        conversation_id: conv_id,
        appointment_id: message.appointment_id,
        other_user_id: message.sender_id == user_id ? message.receiver_id : message.sender_id,
        last_message: message,
        unread_count: 0
      }
      
      # Update last message if this one is newer
      if conversations[conv_id][:last_message].timestamp.nil? || 
         (message.timestamp && message.timestamp > conversations[conv_id][:last_message].timestamp)
        conversations[conv_id][:last_message] = message
      end
    end
    
    # Calculate unread counts
    conversations.each do |conv_id, conv_data|
      conv_data[:unread_count] = unread_count(user_id, conv_id)
    end
    
    conversations.values.sort_by { |c| c[:last_message].timestamp || '' }.reverse
  end
  
  def self.unread_count(user_id, conversation_id)
    find_by_conversation_id(conversation_id).count do |m|
      m.receiver_id == user_id && !m.read
    end
  end
  
  def mark_as_read!
    @read = true
    @read_at = Time.now.utc.iso8601
    save
  end
  
  def save
    messages = self.class.all
    existing_index = messages.find_index { |m| m.message_id == @message_id }
    
    if existing_index
      messages[existing_index] = self
    else
      messages << self
    end
    
    JsonStorage.write('messages', messages.map(&:to_hash))
    self
  end
  
  def to_hash
    {
      message_id: @message_id,
      sender_id: @sender_id,
      receiver_id: @receiver_id,
      appointment_id: @appointment_id,
      content: @content,
      timestamp: @timestamp,
      attachment_url: @attachment_url,
      read: @read,
      read_at: @read_at
    }
  end
  
  def as_json(options = {})
    to_hash.as_json(options)
  end
end

