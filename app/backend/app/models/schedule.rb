class Schedule
  attr_accessor :schedule_id, :tradesman_id, :date, :start_time, :end_time, :status
  
  def initialize(attributes = {})
    @schedule_id = attributes[:schedule_id] || JsonStorage.generate_id
    @tradesman_id = attributes[:tradesman_id]
    @date = attributes[:date]
    @start_time = attributes[:start_time]
    @end_time = attributes[:end_time]
    @status = attributes[:status] || 'available'
  end
  
  def self.find_by_tradesman_id(tradesman_id)
    all.select { |s| s.tradesman_id == tradesman_id }
  end
  
  def self.all
    data = JsonStorage.read('schedules')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def save
    schedules = self.class.all
    existing_index = schedules.find_index { |s| s.schedule_id == @schedule_id }
    
    if existing_index
      schedules[existing_index] = self
    else
      schedules << self
    end
    
    JsonStorage.write('schedules', schedules.map(&:to_hash))
    self
  end
  
  def to_hash
    {
      schedule_id: @schedule_id,
      tradesman_id: @tradesman_id,
      date: @date,
      start_time: @start_time,
      end_time: @end_time,
      status: @status
    }
  end
  
  def as_json(options = {})
    to_hash.as_json(options)
  end
end

