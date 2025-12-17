require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(attrs = {})
    User.new({
      email: "user_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      password_confirmation: "password123"
    }.merge(attrs))
  end

  test "valid user with password" do
    user = build_user
    assert user.valid?
  end

  test "invalid without password" do
    user = build_user(password: nil)
    assert_not user.valid?
  end

  test "invalid when password confirmation does not match" do
    user = build_user(password_confirmation: "wrong")
    assert_not user.valid?
  end

  test "authenticates with correct password" do
    user = build_user
    user.save!

    assert user.authenticate("password123")
    assert_not user.authenticate("wrongpass")
  end

  test "destroys sessions when user is destroyed" do
    user = build_user
    user.save!
  
    session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
  
    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end