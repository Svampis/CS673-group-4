class MessagesController < ApplicationController
  def show
    @message = Message.new
    @sender = current_user
    if params[:id].present?
      @receiver = User.find(params[:id])
      @messages = Message.where("(sender_id = ? and receiver_id = ?) or (sender_id = ? and receiver_id = ?)", @sender.id, params[:id], params[:id], @sender.id).order(:created_at)
    else
      @messages = []
    end
  end
  def index
    @current_user = current_user
    @users = User.where(
      id: Message.select(:receiver_id).where("(sender_id = ?)", @current_user.id)
    ).or(
      User.where(
        id: Message.select(:sender_id).where("(receiver_id = ?)", @current_user.id)
      )
    )
  end
  def create
    @message = Message.new(message_params)
    @message.save
  end

  def message_params
    params.require(:message).permit(:body, :sender_id, :receiver_id)
  end
end
