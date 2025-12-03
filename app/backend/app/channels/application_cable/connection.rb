module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user_id

    def connect
      # For ActionCable, user_id will be passed when subscribing
      # We'll accept the connection and verify in the channel
      # This allows the connection to be established
      self.current_user_id = nil
    end

    private
  end
end

