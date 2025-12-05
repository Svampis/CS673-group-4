namespace :db do
  desc "Migrate data from JSON files to database"
  task migrate_json_to_db: :environment do
    puts "Starting JSON to Database migration..."
    
    # UUID to integer ID mapping
    uuid_to_user_id = {}
    uuid_to_tradesman_id = {}
    uuid_to_homeowner_id = {}
    
    # Step 1: Migrate Users
    puts "\n1. Migrating Users..."
    users_data = JsonStorage.read('users')
    users_data.each do |user_data|
      # Normalize role (some have "Electrician" instead of "tradesman")
      role = user_data['role']&.downcase
      role = 'tradesman' if role == 'electrician' || role == 'plumber' || role == 'hvac worker'
      role = 'homeowner' if role == 'homeowner'
      role = 'admin' if role == 'admin'
      role = 'contractor' if role == 'contractor'
      role ||= 'homeowner' # default
      
      # Normalize status
      status = user_data['status']&.downcase || 'activated'
      status = 'activated' if status == 'active'
      
      user = User.create!(
        email: user_data['email'],
        password_hash: user_data['password_hash'],
        role: role,
        status: status
      )
      
      uuid_to_user_id[user_data['user_id']] = user.id
      puts "  Created user: #{user.email} (ID: #{user.id})"
    rescue => e
      puts "  Error creating user #{user_data['email']}: #{e.message}"
    end
    
    # Step 2: Migrate Tradesmen
    puts "\n2. Migrating Tradesmen..."
    tradesmen_data = JsonStorage.read('tradesmen')
    tradesmen_data.each do |tradesman_data|
      # Find user by email (since tradesmen.json has email)
      user = User.find_by_email(tradesman_data['email'])
      next unless user
      
      # Map trade to trade_specialty
      trade = tradesman_data['trade']&.downcase
      trade_specialty = case trade
      when 'plumber', 'plumbing'
        'plumber'
      when 'electrician', 'electrical'
        'electrician'
      when 'hvac', 'hvac worker', 'heating', 'cooling'
        'hvac worker'
      else
        nil
      end
      
      # Parse address components (basic parsing)
      address = tradesman_data['address'] || tradesman_data['location'] || ''
      city, state, street = parse_address(address)
      
      name_parts = parse_name(tradesman_data['name'])
      tradesman = Tradesman.create!(
        user_id: user.id,
        fname: name_parts[:fname],
        lname: name_parts[:lname],
        number: nil, # Not in JSON
        city: city,
        street: street,
        state: state,
        description: tradesman_data['profile']&.dig('specialties')&.join(', ') || '',
        trade_specialty: trade_specialty,
        service_radius: 25.0, # Default
        hourly_rate: 50.0, # Default
        license_number: tradesman_data['license_number'],
        business_name: tradesman_data['business_name'],
        years_of_experience: tradesman_data['experience'] || 0,
        certification_documents: nil,
        photos: nil,
        verification_status: 'pending',
        latitude: nil,
        longitude: nil
      )
      
      uuid_to_tradesman_id[tradesman_data['user_id']] = tradesman.id
      puts "  Created tradesman: #{tradesman_data['name']} (ID: #{tradesman.id})"
    rescue => e
      puts "  Error creating tradesman #{tradesman_data['name']}: #{e.message}"
    end
    
    # Step 3: Migrate Homeowners
    puts "\n3. Migrating Homeowners and Contractors..."
    User.where(role: 'homeowner').each do |user|
      next if Homeowner.exists?(user_id: user.id)
      
      # Parse name from user data (if available)
      name = user.email.split('@').first # Fallback
      name_parts = parse_name(name)
      fname, lname = name_parts[:fname], name_parts[:lname]
      
      homeowner = Homeowner.create!(
        user_id: user.id,
        fname: fname,
        lname: lname,
        number: nil,
        city: nil,
        street: nil,
        state: nil,
        latitude: nil,
        longitude: nil
      )
      
      uuid_to_homeowner_id[user.id] = homeowner.id
      puts "  Created homeowner for user: #{user.email} (ID: #{homeowner.id})"
    rescue => e
      puts "  Error creating homeowner for user #{user.email}: #{e.message}"
    end
    
    # Migrate Contractors
    User.where(role: 'contractor').each do |user|
      next if Contractor.exists?(user_id: user.id)
      
      # Parse name from user data (if available)
      name = user.email.split('@').first # Fallback
      name_parts = parse_name(name)
      fname, lname = name_parts[:fname], name_parts[:lname]
      
      contractor = Contractor.create!(
        user_id: user.id,
        fname: fname,
        lname: lname,
        number: nil,
        city: nil,
        street: nil,
        state: nil,
        latitude: nil,
        longitude: nil
      )
      
      puts "  Created contractor for user: #{user.email} (ID: #{contractor.id})"
    rescue => e
      puts "  Error creating contractor for user #{user.email}: #{e.message}"
    end
    
    # Step 4: Migrate Projects
    puts "\n4. Migrating Projects..."
    projects_data = JsonStorage.read('projects')
    projects_data.each do |project_data|
      user_id = uuid_to_user_id[project_data['user_id']]
      next unless user_id
      
      user = User.find_by(id: user_id)
      next unless user
      
      # Determine if contractor or homeowner
      contractor_id = user.role == 'contractor' ? user.id : nil
      homeowner_id = user.role == 'homeowner' ? Homeowner.find_by(user_id: user.id)&.id : nil
      
      # For contractors, verify contractor profile exists
      if user.role == 'contractor' && !Contractor.exists?(user_id: user.id)
        puts "  Warning: Contractor profile not found for user #{user.email}, skipping project"
        next
      end
      
      project = Project.create!(
        contractor_id: contractor_id,
        homeowner_id: homeowner_id,
        title: project_data['title'],
        description: project_data['description'],
        trade_type: project_data['trade_type'],
        budget: project_data['budget'],
        location: project_data['location'],
        latitude: nil, # Will need geocoding
        longitude: nil,
        preferred_date: project_data['preferred_date'] ? Date.parse(project_data['preferred_date']) : nil,
        status: project_data['status'] || 'open',
        assigned: nil,
        bidding_increments: nil,
        timespan: nil,
        requirements: nil
      )
      
      # Migrate bids from JSON array
      if project_data['bids'].is_a?(Array)
        project_data['bids'].each do |bid_data|
          tradesman_id = uuid_to_tradesman_id[bid_data['tradesman_id']] || 
                        Tradesman.find_by(user_id: uuid_to_user_id[bid_data['tradesman_id']])&.id
          next unless tradesman_id
          
          Bid.create!(
            project_id: project.id,
            tradesman_id: tradesman_id,
            appointment_id: nil,
            amount: bid_data['amount'] || bid_data['bid_amount'] || 0,
            hourly_rate: bid_data['hourly_rate'] || 0,
            status: bid_data['status'] || 'pending',
            bidding_increment: bid_data['bidding_increment'] || nil
          )
        end
      end
      
      puts "  Created project: #{project.title} (ID: #{project.id})"
    rescue => e
      puts "  Error creating project #{project_data['title']}: #{e.message}"
    end
    
    # Step 5: Migrate Appointments
    puts "\n5. Migrating Appointments..."
    appointments_data = JsonStorage.read('appointments')
    appointments_data.each do |appointment_data|
      homeowner_id = uuid_to_homeowner_id[uuid_to_user_id[appointment_data['homeowner_id']]] ||
                     Homeowner.find_by(user_id: uuid_to_user_id[appointment_data['homeowner_id']])&.id
      tradesman_id = Tradesman.find_by(user_id: uuid_to_user_id[appointment_data['tradesman_id']])&.id
      next unless homeowner_id && tradesman_id
      
      Appointment.create!(
        homeowner_id: homeowner_id,
        project_id: nil, # Will need to map if available
        tradesman_id: tradesman_id,
        scheduled_start: parse_datetime(appointment_data['scheduled_start']),
        scheduled_end: parse_datetime(appointment_data['scheduled_end']),
        job_description: appointment_data['job_description'],
        status: appointment_data['status'] || 'pending',
        accepted_at: nil,
        rejected_at: nil,
        rejection_reason: nil
      )
      
      puts "  Created appointment (ID: #{appointment_data['appointment_id']})"
    rescue => e
      puts "  Error creating appointment: #{e.message}"
    end
    
    # Step 6: Migrate Schedules
    puts "\n6. Migrating Schedules..."
    schedules_data = JsonStorage.read('schedules')
    schedules_data.each do |schedule_data|
      tradesman_id = Tradesman.find_by(user_id: uuid_to_user_id[schedule_data['tradesman_id']])&.id
      next unless tradesman_id
      
      Schedule.create!(
        tradesman_id: tradesman_id,
        date: schedule_data['date'] ? Date.parse(schedule_data['date']) : nil,
        start_time: schedule_data['start_time'] ? Time.parse(schedule_data['start_time']).strftime('%H:%M:%S') : nil,
        end_time: schedule_data['end_time'] ? Time.parse(schedule_data['end_time']).strftime('%H:%M:%S') : nil,
        status: schedule_data['status'] || 'available'
      )
      
      puts "  Created schedule"
    rescue => e
      puts "  Error creating schedule: #{e.message}"
    end
    
    # Step 7: Migrate Reviews
    puts "\n7. Migrating Reviews..."
    reviews_data = JsonStorage.read('reviews')
    reviews_data.each do |review_data|
      homeowner_id = uuid_to_homeowner_id[uuid_to_user_id[review_data['homeowner_id']]] ||
                     Homeowner.find_by(user_id: uuid_to_user_id[review_data['homeowner_id']])&.id
      tradesman_id = Tradesman.find_by(user_id: uuid_to_user_id[review_data['tradesman_id']])&.id
      next unless homeowner_id && tradesman_id
      
      Review.create!(
        homeowner_id: homeowner_id,
        tradesman_id: tradesman_id,
        appointment_id: nil, # Will need to map if available
        rating: review_data['rating'],
        comment: review_data['comment']
      )
      
      puts "  Created review"
    rescue => e
      puts "  Error creating review: #{e.message}"
    end
    
    # Step 8: Migrate Messages and Conversations
    puts "\n8. Migrating Messages and Conversations..."
    messages_data = JsonStorage.read('messages')
    messages_data.each do |message_data|
      sender_id = uuid_to_user_id[message_data['sender_id']]
      receiver_id = uuid_to_user_id[message_data['receiver_id']]
      next unless sender_id && receiver_id
      
      # Find or create conversation
      conversation = Conversation.find_or_create_between(sender_id, receiver_id)
      
      Message.create!(
        conversation_id: conversation.id,
        sender_id: sender_id,
        content: message_data['content'],
        attachment: message_data['attachment_url'],
        read_at: message_data['read_at'] ? parse_datetime(message_data['read_at']) : nil
      )
      
      puts "  Created message"
    rescue => e
      puts "  Error creating message: #{e.message}"
    end
    
    puts "\nMigration completed!"
    puts "Users: #{User.count}"
    puts "Tradesmen: #{Tradesman.count}"
    puts "Homeowners: #{Homeowner.count}"
    puts "Projects: #{Project.count}"
    puts "Appointments: #{Appointment.count}"
    puts "Schedules: #{Schedule.count}"
    puts "Reviews: #{Review.count}"
    puts "Bids: #{Bid.count}"
    puts "Messages: #{Message.count}"
    puts "Conversations: #{Conversation.count}"
  end
end

# Helper methods
def parse_name(name)
  return { fname: '', lname: '' } if name.blank?
  
  parts = name.split(' ')
  if parts.length == 1
    { fname: parts[0], lname: '' }
  else
    { fname: parts[0], lname: parts[1..-1].join(' ') }
  end
end

def parse_address(address)
  return [nil, nil, nil] if address.blank?
  
  # Basic parsing - can be improved
  parts = address.split(',')
  if parts.length >= 2
    city = parts[-2]&.strip
    state = parts[-1]&.strip
    street = parts[0..-3].join(',')&.strip
    [city, state, street]
  else
    [nil, nil, address]
  end
end

def parse_datetime(datetime_str)
  return nil if datetime_str.blank?
  
  begin
    DateTime.parse(datetime_str)
  rescue
    nil
  end
end

