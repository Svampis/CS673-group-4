class Message
  attr_accessor :message_id, :sender_id, :receiver_id, :appointment_id, 
                :content, :timestamp, :attachment_url
  
  def initialize(attributes = {})
    @message_id = attributes[:message_id] || JsonStorage.generate_id
    @sender_id = attributes[:sender_id]
    @receiver_id = attributes[:receiver_id]
    @appointment_id = attributes[:appointment_id]
    @content = attributes[:content]
    @timestamp = attributes[:timestamp] || Time.now.utc.iso8601
    @attachment_url = attributes[:attachment_url]
  end
  
  def self.all
    data = JsonStorage.read('messages')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.find_by_conversation_id(conversation_id)
    # conversation_id can be appointment_id or a combination of sender_id and receiver_id
    all.select do |m|
      m.appointment_id == conversation_id ||
      (m.sender_id == conversation_id || m.receiver_id == conversation_id)
    end
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
      attachment_url: @attachment_url
    }
  end
  
  def as_json(options = {})
    to_hash.as_json(options)
  end
end

