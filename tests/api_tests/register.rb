require 'net/http'
require 'json'

BASE_URL = "#{ARGV[0]}"

positive_test_case_request_bodies = [
  {
    "name" => "John Doe",
    "email" => "john@example.com",
    "password" => "sdoipfgjhsoipdfgjhsdoipfg3422##j",
    "role" => "homeowner",
    "address" => "123 Main St, City, 04455"
  },
  {
    "name" => "John Doe",
    "email" => "john@example.com",
    "password" => "securePassword123",
    "role" => "tradesman",
    "address" => "123 Main St, City, 04455"
  },
  {
    "name" => "John Doe",
    "email" => "john@example.com",
    "password" => "securePassword123",
    "role" => "tradesman",
    "address" => "123 Main St, City, 04455"
  }
]

passed = true
positive_test_case_request_bodies.each do |test_case_request_body|
  uri = URI(BASE_URL + '/register') 
  response = Net::HTTP.post_form(uri, test_case_request_body)
  data = JSON.parse(response.body)
  all_good = true
  if response.code != "200"
    all_good = false
  end
  if data["email"] != test_case_request_body["email"]
    all_good = false
  end
  if data["role"] != test_case_request_body["role"]
    all_good = false
  end
  if data["name"] != test_case_request_body["name"]
    all_good = false
  end
  if data["status"] != "active"
    all_good = false
  end
  if not data.has_key?("user_id")
    all_good = false
  end
  if not all_good
    print("register.rb: Failed test case\nRequest:\n")
    p test_case_request_body
    print("register.rb: Response\n")
    p data
    passed = false
  end
end

negative_test_case_request_bodies = [
  {
    "email" => "john@example.com",
    "password" => "securePassword123",
    "role" => "tradesman",
    "address" => "123 Main St, City, 04455"
  },
  {
    "name" => "John Doe",
    "email" => "john@example.com",
    "password" => "securePassword123",
    "role" => "admin",
    "address" => "123 Main St, City, 04455"
  }
]


negative_test_case_request_bodies.each do |test_case_request_body|
  uri = URI(BASE_URL + '/register') 
  response = Net::HTTP.post_form(uri, test_case_request_body)
  data = JSON.parse(response.body)
  all_good = true
  if response.code == "200"
    all_good = false
  end
  if not all_good
    print("register.rb: Failed test case\nRequest:\n")
    p test_case_request_body
    print("register.rb: Response\n")
    p data
    passed = false
  end
end

if passed
  exit 0
else
  exit 1
end
