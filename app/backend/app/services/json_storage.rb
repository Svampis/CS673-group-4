class JsonStorage
  STORAGE_DIR = Rails.root.join('storage', 'json_data')
  
  def self.ensure_storage_dir
    FileUtils.mkdir_p(STORAGE_DIR) unless Dir.exist?(STORAGE_DIR)
  end
  
  def self.read(file_name)
    ensure_storage_dir
    file_path = STORAGE_DIR.join("#{file_name}.json")
    return [] unless File.exist?(file_path)
    
    content = File.read(file_path)
    return [] if content.strip.empty?
    
    JSON.parse(content)
  rescue JSON::ParserError
    []
  end
  
  def self.write(file_name, data)
    ensure_storage_dir
    file_path = STORAGE_DIR.join("#{file_name}.json")
    File.write(file_path, JSON.pretty_generate(data))
  end
  
  def self.generate_id
    SecureRandom.uuid
  end
end

