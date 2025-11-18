class MessagesController < ApiController
  def show
    conversation_id = params[:conversation_id]
    messages = Message.find_by_conversation_id(conversation_id)
    
    render json: messages.map { |m|
      {
        message_id: m.message_id,
        sender_id: m.sender_id,
        receiver_id: m.receiver_id,
        content: m.content,
        timestamp: m.timestamp,
        attachment_url: m.attachment_url
      }
    }
  end
  
  def create
    message_params = params.permit(:sender_id, :receiver_id, :appointment_id, :content, :attachment_url).to_h.symbolize_keys
    message = Message.new(message_params)
    
    if message.save
      render json: {
        message_id: message.message_id,
        timestamp: message.timestamp
      }, status: :created
    else
      render_error("Failed to send message")
    end
  end
end

