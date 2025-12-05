class User < ApplicationRecord
  # Validations
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_hash, presence: true
  validates :role, presence: true, inclusion: { in: %w[homeowner tradesman contractor admin] }
  validates :status, presence: true, inclusion: { in: %w[activated deactivated suspended] }

  # Associations
  has_one :homeowner, dependent: :destroy
  has_one :contractor, dependent: :destroy
  has_one :tradesman, dependent: :destroy
  has_one :admin, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Instance methods
  def name
    case role
    when 'homeowner'
      homeowner ? "#{homeowner.fname} #{homeowner.lname}".strip : email
    when 'contractor'
      contractor ? "#{contractor.fname} #{contractor.lname}".strip : email
    when 'tradesman'
      tradesman ? "#{tradesman.fname} #{tradesman.lname}".strip : email
    when 'admin'
      admin ? "#{admin.fname} #{admin.lname}".strip : email
    else
      email
    end
  end

  # Class methods
  def self.find_by_email(email)
    where('LOWER(email) = ?', email&.downcase).first
  end

  def self.authenticate(email, password)
    user = find_by_email(email)
    return nil unless user
    return nil unless user.password_hash == password # Simple hash comparison - in production use bcrypt
    user
  end
end
