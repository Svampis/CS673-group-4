class MessagesController < ApplicationController
  def index
    @message = Message.new
    @sender = current_user
    if params[:receiver_id].present?
      @receiver = User.find(params[:receiver_id])
      @messages = Message.where("(sender_id = ? and receiver_id = ?) or (sender_id = ? and receiver_id = ?)", @sender.id, params[:receiver_id], params[:receiver_id], @sender.id).order(:created_at)
    else
      @messages = []
    end
  end

  def create
    @message = Message.new(message_params)
    @message.save
  end

  def message_params
    params.require(:message).permit(:body, :sender_id, :receiver_id)
  end
end
