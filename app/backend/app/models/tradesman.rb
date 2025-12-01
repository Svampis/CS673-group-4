class Tradesman
  attr_accessor :user_id, :name, :email, :trade, :rating, :license_number, 
                :business_name, :experience, :location, :address, :profile
  
  def initialize(attributes = {})
    @user_id = attributes[:user_id] || JsonStorage.generate_id
    @name = attributes[:name]
    @email = attributes[:email]
    @trade = attributes[:trade]
    @rating = attributes[:rating] || 0.0
    @license_number = attributes[:license_number]
    @business_name = attributes[:business_name]
    @experience = attributes[:experience] || 0
    @location = attributes[:location]
    @address = attributes[:address]
    @profile = attributes[:profile] || {}
  end
  
  def self.all
    data = JsonStorage.read('tradesmen')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.find_by_id(id)
    all.find { |t| t.user_id == id }
  end
  
  def self.find_by_trade_and_location(trade, location, name = nil)
    all.select do |t|
      matches_trade = trade.nil? || trade.empty? || t.trade&.downcase&.include?(trade.downcase)
      matches_location = location.nil? || location.empty? || t.location&.downcase == location.downcase || 
                         t.address&.downcase&.include?(location.downcase)
      matches_name = name.nil? || name.empty? || t.name&.downcase&.include?(name.downcase)
      matches_trade && matches_location && matches_name
    end
  end
  
  def save
    tradesmen = self.class.all
    existing_index = tradesmen.find_index { |t| t.user_id == @user_id }
    
    if existing_index
      tradesmen[existing_index] = self
    else
      tradesmen << self
    end
    
    JsonStorage.write('tradesmen', tradesmen.map(&:to_hash))
    self
  end
  
  def to_hash
    {
      user_id: @user_id,
      name: @name,
      email: @email,
      trade: @trade,
      rating: @rating,
      license_number: @license_number,
      business_name: @business_name,
      experience: @experience,
      location: @location,
      address: @address,
      profile: @profile
    }
  end
  
  def as_json(options = {})
    to_hash.as_json(options)
  end
end

