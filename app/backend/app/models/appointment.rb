class Appointment
  attr_accessor :appointment_id, :homeowner_id, :tradesman_id, :scheduled_start, 
                :scheduled_end, :job_description, :status
  
  def initialize(attributes = {})
    @appointment_id = attributes[:appointment_id] || JsonStorage.generate_id
    @homeowner_id = attributes[:homeowner_id]
    @tradesman_id = attributes[:tradesman_id]
    @scheduled_start = attributes[:scheduled_start]
    @scheduled_end = attributes[:scheduled_end]
    @job_description = attributes[:job_description]
    @status = attributes[:status] || 'pending'
  end
  
  def self.all
    data = JsonStorage.read('appointments')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.find_by_id(id)
    all.find { |a| a.appointment_id == id }
  end
  
  def save
    appointments = self.class.all
    existing_index = appointments.find_index { |a| a.appointment_id == @appointment_id }
    
    if existing_index
      appointments[existing_index] = self
    else
      appointments << self
    end
    
    JsonStorage.write('appointments', appointments.map(&:to_hash))
    self
  end
  
  def cancel
    @status = 'canceled'
    save
  end
  
  def to_hash
    {
      appointment_id: @appointment_id,
      homeowner_id: @homeowner_id,
      tradesman_id: @tradesman_id,
      scheduled_start: @scheduled_start,
      scheduled_end: @scheduled_end,
      job_description: @job_description,
      status: @status
    }
  end
  
  def as_json(options = {})
    to_hash.as_json(options)
  end
end

