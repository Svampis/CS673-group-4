require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def text_column_for_message
    candidates = %w[content body text message message_text]
    (candidates & Message.column_names).first
  end

  def create_user!(email)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "can create a message with valid foreign keys" do
    sender = create_user!("sender_#{SecureRandom.hex(4)}@test.com")
    receiver = create_user!("receiver_#{SecureRandom.hex(4)}@test.com")

    text_col = text_column_for_message
    assert text_col, "Could not find message text column. Columns: #{Message.column_names.inspect}"

    attrs = {
      sender_id: sender.id,
      receiver_id: receiver.id,
      text_col => "Hello from test"
    }

    message = Message.new(attrs)
    assert message.save
    assert Message.exists?(message.id)
  end

  test "message is stored and retrievable from the database" do
    user = create_user!("lookup_#{SecureRandom.hex(4)}@test.com")

    text_col = text_column_for_message
    assert text_col, "Could not find message text column. Columns: #{Message.column_names.inspect}"

    msg = Message.create!(
      sender_id: user.id,
      receiver_id: user.id,
      text_col => "Persisted message"
    )

    found = Message.find(msg.id)
    assert_equal "Persisted message", found.public_send(text_col)
  end

  test "message cannot reference a non-existent user" do
  text_col = text_column_for_message
  assert text_col, "Could not find message text column. Columns: #{Message.column_names.inspect}"

  sender_fk = (["sender_id", "user_id"] & Message.column_names).first
  receiver_fk = (["receiver_id"] & Message.column_names).first

  assert sender_fk, "Could not find sender FK column. Columns: #{Message.column_names.inspect}"
  assert receiver_fk, "Could not find receiver FK column. Columns: #{Message.column_names.inspect}"

  assert_raises(ActiveRecord::RecordInvalid) do
    Message.create!(
      sender_fk => 999_999,
      receiver_fk => 999_998,
      text_col => "This should fail"
    )
  end
end
end

