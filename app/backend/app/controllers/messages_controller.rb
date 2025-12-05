class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_api_format, only: [:index, :show, :create, :mark_read, :unread_counts]
  before_action :parse_json_body, if: -> { request.post? || request.put? }, only: [:create, :mark_read]
  
  def index_page
    # Render the messaging UI page
    render 'messages/index', layout: false
  end
  
  def index
    # Get user_id from params (sent from frontend)
    user_id = params[:user_id]
    return render_error("User ID required", :bad_request) unless user_id
    
    conversations = Message.find_conversations_for_user(user_id)
    
    # Enrich with user information
    enriched_conversations = conversations.map do |conv|
      other_user = User.find_by_id(conv[:other_user_id])
      last_msg = conv[:last_message]
      
      {
        conversation_id: conv[:conversation_id],
        appointment_id: conv[:appointment_id],
        other_user: {
          user_id: other_user&.user_id,
          name: other_user&.name || 'Unknown User',
          role: other_user&.role,
          email: other_user&.email
        },
        last_message: {
          message_id: last_msg.message_id,
          content: last_msg.content,
          timestamp: last_msg.timestamp,
          sender_id: last_msg.sender_id,
          read: last_msg.read
        },
        unread_count: conv[:unread_count]
      }
    end
    
    render json: enriched_conversations
  end
  
  def show
    conversation_id = params[:conversation_id]
    user_id = params[:user_id] # Current user viewing the messages
    messages = Message.find_by_conversation_id(conversation_id)
    
    # Mark messages as read when viewed by receiver
    if user_id
      messages.each do |m|
        if m.receiver_id == user_id && !m.read
          m.mark_as_read!
        end
      end
      # Reload to get updated read status
      messages = Message.find_by_conversation_id(conversation_id)
    end
    
    # Get sender/receiver names
    enriched_messages = messages.map do |m|
      sender = User.find_by_id(m.sender_id)
      receiver = User.find_by_id(m.receiver_id)
      
      {
        message_id: m.message_id,
        sender_id: m.sender_id,
        sender_name: sender&.name || 'Unknown',
        receiver_id: m.receiver_id,
        receiver_name: receiver&.name || 'Unknown',
        content: m.content,
        timestamp: m.timestamp,
        attachment_url: m.attachment_url,
        read: m.read,
        read_at: m.read_at
      }
    end
    
    render json: enriched_messages
  end
  
  def create
    message_params = params.permit(:sender_id, :receiver_id, :appointment_id, :content, :attachment_url, :conversation_id).to_h.symbolize_keys
    
    # Handle conversation-based messaging
    if message_params[:conversation_id].present?
      conversation = Conversation.find_by(id: message_params[:conversation_id])
      return render_error("Conversation not found", :not_found) unless conversation
      
      message = Message.new(
        conversation: conversation,
        sender_id: message_params[:sender_id],
        content: message_params[:content],
        attachment: message_params[:attachment_url]
      )
    else
      # Legacy support - create or find conversation
      if message_params[:sender_id] && message_params[:receiver_id]
        conversation = Conversation.find_or_create_between(
          message_params[:sender_id],
          message_params[:receiver_id]
        )
        message = Message.new(
          conversation: conversation,
          sender_id: message_params[:sender_id],
          content: message_params[:content],
          attachment: message_params[:attachment_url]
        )
      else
        return render_error("Sender ID and receiver ID or conversation ID required", :bad_request)
      end
    end
    
    if message.save
      # Notify receiver of new message
      NotificationService.notify_new_message(message)
      
      # Determine conversation_id for broadcasting
      conversation_id = message.conversation.id
      
      # Get sender name for broadcast
      sender = User.find_by(id: message.sender_id)
      
      # Broadcast via ActionCable
      message_data = {
        message_id: message.id,
        sender_id: message.sender_id,
        sender_name: sender&.name || 'Unknown',
        content: message.content,
        timestamp: message.created_at,
        attachment_url: message.attachment,
        read: message.read_at.present?,
        conversation_id: conversation_id
      }
      
      ActionCable.server.broadcast("conversation_#{conversation_id}", {
        type: 'new_message',
        message: message_data
      })
      
      render json: message_data, status: :created
    else
      render_error("Failed to send message")
    end
  end
  
  def mark_read
    message_id = params[:id]
    message = Message.all.find { |m| m.message_id == message_id }
    
    if message
      message.mark_as_read!
      render json: { message: 'Message marked as read', message_id: message_id }
    else
      render_error("Message not found", :not_found)
    end
  end
  
  def unread_counts
    user_id = params[:user_id]
    return render_error("User ID required", :bad_request) unless user_id
    
    conversations = Message.find_conversations_for_user(user_id)
    counts = {}
    
    conversations.each do |conv|
      counts[conv[:conversation_id]] = conv[:unread_count]
    end
    
    render json: counts
  end
  
  private
  
  def set_api_format
    request.format = :json
  end
  
  def parse_json_body
    return unless request.content_type&.include?('application/json')
    
    begin
      body = request.body.read
      request.body.rewind
      @parsed_body = JSON.parse(body) if body.present?
      params.merge!(@parsed_body) if @parsed_body.is_a?(Hash)
    rescue JSON::ParserError
      # Ignore JSON parse errors
    end
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end

