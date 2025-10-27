require 'net/http'
require 'json'

BASE_URL = "#{ARGV[0]}"

profile_names = ["john_doe", "steve_sherman"]
test_case_response_bodies = [
  {
    "user_id" => "uuid", 
    "name" => "John Doe", 
    "email" => "john@example.com",
    "role" => "tradesman",
    "address" => "123 Main St, City, ZIP", 
    "profile" => 
      {
        "license_number" => "ABC123", 
        "trade" => "plumber", 
        "experience" => 5,
        "rating" => 4.8
      }
  },
  {
    "user_id" => "uuid", 
    "name" => "Steve Sherman", 
    "email" => "steve@example.com",
    "role" => "tradesman",
    "address" => "123 Main St, City 03334", 
    "profile" => 
      {
        "license_number" => "XYZ123", 
        "trade" => "plumber", 
        "experience" => 5,
        "rating" => 4.8
      }
  }
]

passed = true
i = 0
while i < profile_names.length()
  uri = URI(BASE_URL + '/profile/' + profile_names[i]) 
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)
  all_good = true
  if data != test_case_response_bodies[i]
    all_good = false
  end
  if not all_good
    print("get_profile.rb: Failed test case\n")
    print("get_profile.rb: user profile\n")
    p profile_names[i]
    print("get_profile.rb: Response\n")
    p data
    passed = false
  end
  i += 1
end

if passed
  exit 0
else
  exit 1
end
