class Review
  attr_accessor :review_id, :homeowner_id, :tradesman_id, :appointment_id, 
                :rating, :comment, :timestamp
  
  def initialize(attributes = {})
    @review_id = attributes[:review_id] || JsonStorage.generate_id
    @homeowner_id = attributes[:homeowner_id]
    @tradesman_id = attributes[:tradesman_id]
    @appointment_id = attributes[:appointment_id]
    @rating = attributes[:rating]
    @comment = attributes[:comment]
    @timestamp = attributes[:timestamp] || Time.now.utc.iso8601
  end
  
  def self.all
    data = JsonStorage.read('reviews')
    data.map { |attrs| 
      hash = attrs.is_a?(Hash) ? attrs : {}
      new(hash.symbolize_keys)
    }
  end
  
  def self.find_by_tradesman_id(tradesman_id)
    all.select { |r| r.tradesman_id == tradesman_id }
  end
  
  def save
    reviews = self.class.all
    existing_index = reviews.find_index { |r| r.review_id == @review_id }
    
    if existing_index
      reviews[existing_index] = self
    else
      reviews << self
    end
    
    # Update tradesman rating
    update_tradesman_rating
    
    JsonStorage.write('reviews', reviews.map(&:to_hash))
    self
  end
  
  def update_tradesman_rating
    tradesman_reviews = self.class.find_by_tradesman_id(@tradesman_id)
    return if tradesman_reviews.empty?
    
    average_rating = tradesman_reviews.sum(&:rating).to_f / tradesman_reviews.size
    tradesman = Tradesman.find_by_id(@tradesman_id)
    if tradesman
      tradesman.rating = average_rating.round(1)
      tradesman.save
    end
  end
  
  def to_hash
    {
      review_id: @review_id,
      homeowner_id: @homeowner_id,
      tradesman_id: @tradesman_id,
      appointment_id: @appointment_id,
      rating: @rating,
      comment: @comment,
      timestamp: @timestamp
    }
  end
  
  def as_json(options = {})
    to_hash.as_json(options)
  end
end

