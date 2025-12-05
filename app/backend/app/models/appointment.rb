class Appointment < ApplicationRecord
  belongs_to :homeowner
  belongs_to :tradesman
  belongs_to :project, optional: true

  validates :scheduled_start, presence: true
  validates :scheduled_end, presence: true
  validates :status, inclusion: { in: %w[pending confirmed rejected completed cancelled] }

  def cancel
    update(status: 'cancelled')
  end
  
  def accept(reason = nil)
    update(
      status: 'confirmed',
      accepted_at: Time.current,
      rejected_at: nil,
      rejection_reason: nil
    )
  end
  
  def reject(reason = nil)
    update(
      status: 'rejected',
      rejected_at: Time.current,
      accepted_at: nil,
      rejection_reason: reason
    )
  end
end
