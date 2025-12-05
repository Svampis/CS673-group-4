# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data (optional - comment out if you want to preserve existing data)
puts "Clearing existing data..."
# Destroy in order to respect foreign key constraints
[Notification, Message, Conversation, Estimate, Bid, Appointment, Schedule, Review, Project, TradesmanVerification, Tradesman, Contractor, Homeowner, Admin, User].each do |model|
  begin
    model.destroy_all
  rescue => e
    puts "  Warning: Could not destroy #{model.name}: #{e.message}"
  end
end

puts "Creating sample data..."

# ============================================
# USERS
# ============================================

# Homeowners
homeowner_users = [
  { email: "john.doe@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
  { email: "jane.smith@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
  { email: "bob.wilson@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
  { email: "alice.brown@example.com", password_hash: "password123", role: "homeowner", status: "activated" },
  { email: "charlie.davis@example.com", password_hash: "password123", role: "homeowner", status: "activated" }
]

# Tradesmen
tradesman_users = [
  { email: "mike.plumber@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
  { email: "sarah.electrician@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
  { email: "tom.hvac@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
  { email: "lisa.plumber@example.com", password_hash: "password123", role: "tradesman", status: "activated" },
  { email: "david.electrician@example.com", password_hash: "password123", role: "tradesman", status: "activated" }
]

# Contractors
contractor_users = [
  { email: "contractor1@example.com", password_hash: "password123", role: "contractor", status: "activated" },
  { email: "contractor2@example.com", password_hash: "password123", role: "contractor", status: "activated" }
]

# Admin
admin_users = [
  { email: "admin@example.com", password_hash: "admin123", role: "admin", status: "activated" }
]

# Suspended user (for testing)
suspended_user = { email: "suspended@example.com", password_hash: "password123", role: "homeowner", status: "suspended" }

all_users = []
puts "Creating users..."

# Create homeowners
homeowner_profiles = [
  { fname: "John", lname: "Doe", street: "123 Main St", city: "Boston", state: "MA", number: "555-0101" },
  { fname: "Jane", lname: "Smith", street: "456 Oak Ave", city: "Cambridge", state: "MA", number: "555-0102" },
  { fname: "Bob", lname: "Wilson", street: "789 Pine Rd", city: "Somerville", state: "MA", number: "555-0103" },
  { fname: "Alice", lname: "Brown", street: "321 Elm St", city: "Boston", state: "MA", number: "555-0104" },
  { fname: "Charlie", lname: "Davis", street: "654 Maple Dr", city: "Cambridge", state: "MA", number: "555-0105" }
]

homeowner_users.each_with_index do |user_data, index|
  user = User.create!(user_data)
  all_users << user
  Homeowner.create!(
    user: user,
    fname: homeowner_profiles[index][:fname],
    lname: homeowner_profiles[index][:lname],
    street: homeowner_profiles[index][:street],
    city: homeowner_profiles[index][:city],
    state: homeowner_profiles[index][:state],
    number: homeowner_profiles[index][:number],
    latitude: 42.3601 + (rand - 0.5) * 0.1, # Boston area coordinates
    longitude: -71.0589 + (rand - 0.5) * 0.1
  )
end

# Create tradesmen
tradesman_profiles = [
  { fname: "Mike", lname: "Johnson", trade_specialty: "plumber", business_name: "Mike's Plumbing", license_number: "PL-12345", years_of_experience: 10, hourly_rate: 75.0, service_radius: 25.0, city: "Boston", state: "MA", street: "100 Trade St", number: "555-0201", verification_status: "approved" },
  { fname: "Sarah", lname: "Williams", trade_specialty: "electrician", business_name: "Sarah's Electrical", license_number: "EL-23456", years_of_experience: 8, hourly_rate: 85.0, service_radius: 30.0, city: "Cambridge", state: "MA", street: "200 Wire Ave", number: "555-0202", verification_status: "approved" },
  { fname: "Tom", lname: "Anderson", trade_specialty: "hvac worker", business_name: "Tom's HVAC Services", license_number: "HV-34567", years_of_experience: 12, hourly_rate: 80.0, service_radius: 35.0, city: "Somerville", state: "MA", street: "300 Air Way", number: "555-0203", verification_status: "approved" },
  { fname: "Lisa", lname: "Martinez", trade_specialty: "plumber", business_name: "Lisa's Plumbing Co", license_number: "PL-45678", years_of_experience: 6, hourly_rate: 70.0, service_radius: 20.0, city: "Boston", state: "MA", street: "400 Pipe Ln", number: "555-0204", verification_status: "approved" },
  { fname: "David", lname: "Taylor", trade_specialty: "electrician", business_name: "David's Electric", license_number: "EL-56789", years_of_experience: 5, hourly_rate: 75.0, service_radius: 25.0, city: "Cambridge", state: "MA", street: "500 Circuit Blvd", number: "555-0205", verification_status: "pending" }
]

tradesman_users.each_with_index do |user_data, index|
  user = User.create!(user_data)
  all_users << user
  tradesman = Tradesman.create!(
    user: user,
    fname: tradesman_profiles[index][:fname],
    lname: tradesman_profiles[index][:lname],
    trade_specialty: tradesman_profiles[index][:trade_specialty],
    business_name: tradesman_profiles[index][:business_name],
    license_number: tradesman_profiles[index][:license_number],
    years_of_experience: tradesman_profiles[index][:years_of_experience],
    hourly_rate: tradesman_profiles[index][:hourly_rate],
    service_radius: tradesman_profiles[index][:service_radius],
    city: tradesman_profiles[index][:city],
    state: tradesman_profiles[index][:state],
    street: tradesman_profiles[index][:street],
    number: tradesman_profiles[index][:number],
    verification_status: tradesman_profiles[index][:verification_status],
    latitude: 42.3601 + (rand - 0.5) * 0.1,
    longitude: -71.0589 + (rand - 0.5) * 0.1
  )
end

# Create contractors
contractor_profiles = [
  { fname: "Robert", lname: "Builder", street: "700 Construction Ave", city: "Boston", state: "MA", number: "555-0301" },
  { fname: "Emily", lname: "Contractor", street: "800 Build St", city: "Cambridge", state: "MA", number: "555-0302" }
]

contractor_users.each_with_index do |user_data, index|
  user = User.create!(user_data)
  all_users << user
  Contractor.create!(
    user: user,
    fname: contractor_profiles[index][:fname],
    lname: contractor_profiles[index][:lname],
    street: contractor_profiles[index][:street],
    city: contractor_profiles[index][:city],
    state: contractor_profiles[index][:state],
    number: contractor_profiles[index][:number],
    latitude: 42.3601 + (rand - 0.5) * 0.1,
    longitude: -71.0589 + (rand - 0.5) * 0.1
  )
end

# Create admin
admin_user = User.create!(admin_users.first)
all_users << admin_user
Admin.create!(
  user: admin_user,
  fname: "Admin",
  lname: "User",
  street: "900 Admin Blvd",
  city: "Boston",
  state: "MA",
  number: "555-0001"
)

# Create suspended user
suspended = User.create!(suspended_user)
all_users << suspended
Homeowner.create!(
  user: suspended,
  fname: "Suspended",
  lname: "User",
  street: "999 Suspended St",
  city: "Boston",
  state: "MA",
  number: "555-9999"
)

puts "Created #{User.count} users"

# ============================================
# TRADESMAN VERIFICATIONS
# ============================================
puts "Creating tradesman verifications..."

Tradesman.all.each do |tradesman|
  status = tradesman.verification_status
  admin_id = status == "approved" ? admin_user.id : nil
  reviewed_at = status == "approved" ? 2.days.ago : nil
  
  TradesmanVerification.create!(
    tradesman: tradesman,
    admin_id: admin_id,
    status: status,
    license_number: tradesman.license_number,
    certification_documents: "Certification document for #{tradesman.business_name}",
    identification_documents: "ID document for #{tradesman.fname} #{tradesman.lname}",
    reviewed_at: reviewed_at
  )
end

puts "Created #{TradesmanVerification.count} verifications"

# ============================================
# SCHEDULES
# ============================================
puts "Creating schedules..."

Tradesman.where(verification_status: "approved").each do |tradesman|
  # Create schedules for the next 2 weeks
  (0..13).each do |day_offset|
    date = Date.today + day_offset.days
    
    # Create 3 time slots per day (morning, afternoon, evening)
    [
      { start: "09:00", end: "12:00", status: day_offset % 3 == 0 ? "booked" : "available" },
      { start: "13:00", end: "17:00", status: day_offset % 4 == 0 ? "booked" : "available" },
      { start: "18:00", end: "20:00", status: day_offset % 5 == 0 ? "unavailable" : "available" }
    ].each do |slot|
      Schedule.create!(
        tradesman: tradesman,
        date: date,
        start_time: slot[:start],
        end_time: slot[:end],
        status: slot[:status]
      )
    end
  end
end

puts "Created #{Schedule.count} schedule slots"

# ============================================
# PROJECTS
# ============================================
puts "Creating projects..."

contractors = User.where(role: "contractor").includes(:contractor)
homeowners = User.where(role: "homeowner").includes(:homeowner).limit(3)

project_data = [
  { title: "Kitchen Renovation", description: "Complete kitchen remodel including plumbing and electrical work", trade_type: "plumber", budget: 15000.0, location: "Boston, MA", preferred_date: 1.month.from_now, status: "open", bidding_increments: 100.0, timespan: "4-6 weeks", requirements: "Licensed plumber and electrician required" },
  { title: "Office Building HVAC Upgrade", description: "Upgrade HVAC system for 5000 sq ft office building", trade_type: "hvac worker", budget: 50000.0, location: "Cambridge, MA", preferred_date: 2.months.from_now, status: "open", bidding_increments: 500.0, timespan: "8-10 weeks", requirements: "Commercial HVAC license required" },
  { title: "Bathroom Remodel", description: "Full bathroom renovation with new fixtures", trade_type: "plumber", budget: 12000.0, location: "Somerville, MA", preferred_date: 3.weeks.from_now, status: "open", bidding_increments: 200.0, timespan: "3-4 weeks", requirements: "Experience with bathroom renovations" },
  { title: "Electrical Panel Upgrade", description: "Upgrade main electrical panel to 200A service", trade_type: "electrician", budget: 8000.0, location: "Boston, MA", preferred_date: 1.week.from_now, status: "in_progress", bidding_increments: 100.0, timespan: "1-2 weeks", requirements: "Master electrician license required" },
  { title: "Whole House Rewiring", description: "Complete electrical rewiring for 1920s home", trade_type: "electrician", budget: 25000.0, location: "Cambridge, MA", preferred_date: 2.months.from_now, status: "open", bidding_increments: 250.0, timespan: "6-8 weeks", requirements: "Experience with old homes" }
]

project_data.each_with_index do |proj_data, index|
  owner = index < 2 ? contractors[index % contractors.count] : homeowners[index % homeowners.count]
  
  Project.create!(
    contractor_id: owner.role == "contractor" ? owner.id : nil,
    homeowner_id: owner.role == "homeowner" ? owner.homeowner&.id : nil,
    title: proj_data[:title],
    description: proj_data[:description],
    trade_type: proj_data[:trade_type],
    budget: proj_data[:budget],
    location: proj_data[:location],
    latitude: 42.3601 + (rand - 0.5) * 0.1,
    longitude: -71.0589 + (rand - 0.5) * 0.1,
    preferred_date: proj_data[:preferred_date],
    status: proj_data[:status],
    bidding_increments: proj_data[:bidding_increments],
    timespan: proj_data[:timespan],
    requirements: proj_data[:requirements]
  )
end

puts "Created #{Project.count} projects"

# ============================================
# APPOINTMENTS
# ============================================
puts "Creating appointments..."

homeowners_with_profiles = Homeowner.includes(:user).limit(3)
tradesmen_with_profiles = Tradesman.where(verification_status: "approved").limit(3)
projects = Project.limit(2)

appointment_data = [
  { scheduled_start: 3.days.from_now.change(hour: 9, min: 0), scheduled_end: 3.days.from_now.change(hour: 12, min: 0), job_description: "Fix leaking kitchen sink", status: "confirmed", accepted_at: 1.day.ago },
  { scheduled_start: 5.days.from_now.change(hour: 13, min: 0), scheduled_end: 5.days.from_now.change(hour: 17, min: 0), job_description: "Install new electrical outlets", status: "pending" },
  { scheduled_start: 1.week.from_now.change(hour: 10, min: 0), scheduled_end: 1.week.from_now.change(hour: 14, min: 0), job_description: "HVAC system inspection", status: "confirmed", accepted_at: 2.days.ago },
  { scheduled_start: 2.weeks.from_now.change(hour: 9, min: 0), scheduled_end: 2.weeks.from_now.change(hour: 11, min: 0), job_description: "Bathroom plumbing repair", status: "rejected", rejected_at: 1.day.ago, rejection_reason: "Not available at that time" },
  { scheduled_start: 1.week.ago.change(hour: 14, min: 0), scheduled_end: 1.week.ago.change(hour: 16, min: 0), job_description: "Completed plumbing work", status: "completed" }
]

appointment_data.each_with_index do |appt_data, index|
  homeowner = homeowners_with_profiles[index % homeowners_with_profiles.count]
  tradesman = tradesmen_with_profiles[index % tradesmen_with_profiles.count]
  project = index < 2 ? projects[index] : nil
  
  Appointment.create!(
    homeowner: homeowner,
    tradesman: tradesman,
    project: project,
    scheduled_start: appt_data[:scheduled_start],
    scheduled_end: appt_data[:scheduled_end],
    job_description: appt_data[:job_description],
    status: appt_data[:status],
    accepted_at: appt_data[:accepted_at],
    rejected_at: appt_data[:rejected_at],
    rejection_reason: appt_data[:rejection_reason]
  )
end

puts "Created #{Appointment.count} appointments"

# ============================================
# BIDS
# ============================================
puts "Creating bids..."

open_projects = Project.where(status: "open")
tradesmen_for_bids = Tradesman.where(verification_status: "approved")

open_projects.each do |project|
  # Create 2-3 bids per project
  matching_tradesmen = tradesmen_for_bids.where(trade_specialty: project.trade_type).limit(3)
  
  matching_tradesmen.each_with_index do |tradesman, bid_index|
    base_rate = tradesman.hourly_rate
    bid_amount = project.budget - (bid_index * project.bidding_increments)
    hourly_rate = base_rate - (bid_index * 5)
    
    Bid.create!(
      project: project,
      tradesman: tradesman,
      amount: bid_amount,
      hourly_rate: hourly_rate,
      bidding_increment: project.bidding_increments,
      status: bid_index == 0 ? "accepted" : "pending"
    )
  end
end

puts "Created #{Bid.count} bids"

# ============================================
# ESTIMATES
# ============================================
puts "Creating estimates..."

confirmed_appointments = Appointment.where(status: ["confirmed", "completed"]).limit(3)

confirmed_appointments.each_with_index do |appointment, index|
  Estimate.create!(
    tradesman: appointment.tradesman,
    homeowner: appointment.homeowner,
    appointment: appointment,
    amount: 500.0 + (index * 200),
    notes: "Estimate for #{appointment.job_description}",
    status: index == 0 ? "accepted" : (index == 1 ? "rejected" : "pending"),
    version: 1
  )
  
  # Create an updated estimate for one appointment
  if index == 1
    Estimate.create!(
      tradesman: appointment.tradesman,
      homeowner: appointment.homeowner,
      appointment: appointment,
      amount: 450.0,
      notes: "Revised estimate - found additional work needed",
      status: "pending",
      version: 2
    )
  end
end

# Create estimates for projects (only for homeowner-owned projects)
homeowner_projects = Project.where.not(homeowner_id: nil).limit(1)
if homeowner_projects.any?
  project_with_estimate = homeowner_projects.first
  homeowner = project_with_estimate.homeowner
  Estimate.create!(
    tradesman: tradesmen_for_bids.first,
    homeowner: homeowner,
    project: project_with_estimate,
    amount: project_with_estimate.budget * 0.9,
    notes: "Initial estimate for #{project_with_estimate.title}",
    status: "pending",
    version: 1
  )
end

puts "Created #{Estimate.count} estimates"

# ============================================
# CONVERSATIONS AND MESSAGES
# ============================================
puts "Creating conversations and messages..."

# Create conversations between homeowners and tradesmen
appointments_with_messages = Appointment.limit(4)

appointments_with_messages.each do |appointment|
  homeowner_user = appointment.homeowner.user
  tradesman_user = appointment.tradesman.user
  
  conversation = Conversation.find_or_create_between(homeowner_user.id, tradesman_user.id)
  
  # Create initial message from homeowner
  Message.create!(
    conversation: conversation,
    sender: homeowner_user,
    content: "Hi, I'm interested in your services for: #{appointment.job_description}",
    read_at: nil
  )
  
  # Create response from tradesman
  Message.create!(
    conversation: conversation,
    sender: tradesman_user,
    content: "Thank you for reaching out! I'd be happy to help with that. When would be a good time for you?",
    read_at: 1.hour.ago
  )
  
  # Create follow-up message
  if appointment.status == "confirmed"
    Message.create!(
      conversation: conversation,
      sender: homeowner_user,
      content: "Great! Looking forward to the appointment on #{appointment.scheduled_start.strftime('%B %d')}.",
      read_at: nil
    )
  end
end

# Create a conversation without appointment
homeowner_user = User.where(role: "homeowner").first
tradesman_user = Tradesman.where(verification_status: "approved").first.user

conversation = Conversation.find_or_create_between(homeowner_user.id, tradesman_user.id)
Message.create!(
  conversation: conversation,
  sender: homeowner_user,
  content: "Do you provide emergency services?",
  read_at: nil
)

puts "Created #{Conversation.count} conversations"
puts "Created #{Message.count} messages"

# ============================================
# REVIEWS
# ============================================
puts "Creating reviews..."

completed_appointments = Appointment.where(status: "completed")

completed_appointments.each_with_index do |appointment, index|
  Review.create!(
    homeowner: appointment.homeowner,
    tradesman: appointment.tradesman,
    appointment: appointment,
    rating: [4, 5, 5, 4, 5][index % 5],
    comment: [
      "Excellent work! Very professional and completed on time.",
      "Great service, would definitely hire again.",
      "Fixed the issue quickly and efficiently.",
      "Good work, but took a bit longer than expected.",
      "Outstanding quality and professionalism!"
    ][index % 5]
  )
end

# Create some additional reviews for tradesmen
tradesmen_with_reviews = Tradesman.where(verification_status: "approved").limit(2)
homeowners_for_reviews = Homeowner.limit(2)

tradesmen_with_reviews.each do |tradesman|
  homeowners_for_reviews.each do |homeowner|
    Review.create!(
      homeowner: homeowner,
      tradesman: tradesman,
      rating: rand(4..5),
      comment: "Great service from #{tradesman.business_name}!"
    )
  end
end

puts "Created #{Review.count} reviews"

# ============================================
# NOTIFICATIONS
# ============================================
puts "Creating notifications..."

# Create notifications for various users
all_users.each do |user|
  notification_types = [
    { type: "appointment_confirmed", title: "Appointment Confirmed", message: "Your appointment has been confirmed for tomorrow at 9:00 AM" },
    { type: "new_message", title: "New Message", message: "You have a new message from a tradesman" },
    { type: "new_bid", title: "New Bid Received", message: "A new bid has been placed on your project" },
    { type: "estimate_updated", title: "Estimate Updated", message: "Your estimate has been updated by the tradesman" },
    { type: "review_received", title: "New Review", message: "You received a new review from a homeowner" }
  ]
  
  # Create 1-3 notifications per user
  rand(1..3).times do
    notification = notification_types.sample
    Notification.create!(
      user: user,
      notification_type: notification[:type],
      title: notification[:title],
      message: notification[:message],
      read: rand < 0.3, # 30% chance of being read
      read_at: rand < 0.3 ? rand(1..7).days.ago : nil,
      related_type: ["Appointment", "Message", "Bid", "Estimate", "Review"].sample,
      related_id: rand(1..100)
    )
  end
end

puts "Created #{Notification.count} notifications"

# ============================================
# SUMMARY
# ============================================
puts "\n" + "="*50
puts "SEED DATA SUMMARY"
puts "="*50
puts "Users: #{User.count}"
puts "  - Homeowners: #{User.where(role: 'homeowner').count}"
puts "  - Tradesmen: #{User.where(role: 'tradesman').count}"
puts "  - Contractors: #{User.where(role: 'contractor').count}"
puts "  - Admins: #{User.where(role: 'admin').count}"
puts "Homeowners: #{Homeowner.count}"
puts "Contractors: #{Contractor.count}"
puts "Tradesmen: #{Tradesman.count}"
puts "Admins: #{Admin.count}"
puts "Schedules: #{Schedule.count}"
puts "Projects: #{Project.count}"
puts "Appointments: #{Appointment.count}"
puts "Bids: #{Bid.count}"
puts "Estimates: #{Estimate.count}"
puts "Conversations: #{Conversation.count}"
puts "Messages: #{Message.count}"
puts "Reviews: #{Review.count}"
puts "Notifications: #{Notification.count}"
puts "Tradesman Verifications: #{TradesmanVerification.count}"
puts "="*50
puts "Seed data created successfully!"
puts "="*50
