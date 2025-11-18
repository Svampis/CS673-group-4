class User
  attr_accessor :user_id, :name, :email, :password_hash, :role, :address, :status, :profile
  
  def initialize(attributes = {})
    @user_id = attributes[:user_id] || JsonStorage.generate_id
    @name = attributes[:name]
    @email = attributes[:email]
    @password_hash = attributes[:password_hash]
    @role = attributes[:role] # "homeowner" or "tradesman"
    @address = attributes[:address]
    @status = attributes[:status] || 'active'
    @profile = attributes[:profile] || {}
  end
  
  def self.all
    data = JsonStorage.read('users')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.find_by_id(id)
    all.find { |u| u.user_id == id }
  end
  
  def self.find_by_email(email)
    all.find { |u| u.email&.downcase == email&.downcase }
  end
  
  def self.authenticate(email, password)
    user = find_by_email(email)
    return nil unless user
    return nil unless user.password_hash == password # Simple hash comparison - in production use bcrypt
    user
  end
  
  def save
    users = self.class.all
    existing_index = users.find_index { |u| u.user_id == @user_id }
    
    if existing_index
      users[existing_index] = self
    else
      users << self
    end
    
    JsonStorage.write('users', users.map(&:to_hash))
    self
  end
  
  def to_hash
    {
      user_id: @user_id,
      name: @name,
      email: @email,
      password_hash: @password_hash,
      role: @role,
      address: @address,
      status: @status,
      profile: @profile
    }
  end
  
  def as_json(options = {})
    hash = {
      user_id: @user_id,
      name: @name,
      email: @email,
      role: @role,
      address: @address,
      status: @status,
      profile: @profile
    }
    hash.as_json(options)
  end
end

