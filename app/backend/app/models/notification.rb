class Notification < ApplicationRecord
  belongs_to :user

  validates :notification_type, presence: true
  validates :title, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :by_type, ->(type) { where(notification_type: type) }

  def mark_as_read!
    update(read: true, read_at: Time.current)
  end
end

