class Project
  attr_accessor :project_id, :user_id, :title, :description, :trade_type, :budget, :location, 
                :preferred_date, :status, :created_at, :updated_at, :bids
  
  def initialize(attributes = {})
    @project_id = attributes[:project_id] || JsonStorage.generate_id
    @user_id = attributes[:user_id]
    @title = attributes[:title]
    @description = attributes[:description]
    @trade_type = attributes[:trade_type]
    @budget = attributes[:budget]
    @location = attributes[:location]
    @preferred_date = attributes[:preferred_date]
    @status = attributes[:status] || 'open'
    @created_at = attributes[:created_at] || Time.now.iso8601
    @updated_at = attributes[:updated_at] || Time.now.iso8601
    @bids = attributes[:bids] || []
  end
  
  def self.all
    data = JsonStorage.read('projects')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.find_by_id(id)
    all.find { |p| p.project_id == id }
  end
  
  def self.find_by_user_id(user_id)
    all.select { |p| p.user_id == user_id }
  end
  
  def save
    projects = self.class.all
    existing_index = projects.find_index { |p| p.project_id == @project_id }
    
    @updated_at = Time.now.iso8601
    
    if existing_index
      projects[existing_index] = self
    else
      projects << self
    end
    
    JsonStorage.write('projects', projects.map(&:to_hash))
    self
  end
  
  def to_hash
    {
      project_id: @project_id,
      user_id: @user_id,
      title: @title,
      description: @description,
      trade_type: @trade_type,
      budget: @budget,
      location: @location,
      preferred_date: @preferred_date,
      status: @status,
      created_at: @created_at,
      updated_at: @updated_at,
      bids: @bids
    }
  end
end
