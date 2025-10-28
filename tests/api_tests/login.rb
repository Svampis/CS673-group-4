require 'net/http'
require 'json'

BASE_URL = "#{ARGV[0]}"

positive_test_case_request_bodies = [
  {
    "email" => "john@example.com",
    "password" => "sdoipfgjhsoipdfgjhsdoipfg3422##j",
  },
  {
    "email" => "john@example.com",
    "password" => "securePassword123",
  },
  {
    "email" => "john@example.com",
    "password" => "securePassword123",
  }
]

passed = true
positive_test_case_request_bodies.each do |test_case_request_body|
  uri = URI(BASE_URL + '/login') 
  response = Net::HTTP.post_form(uri, test_case_request_body)
  data = JSON.parse(response.body)
  all_good = true
  if response.code != "200"
    all_good = false
  end
  if data["token_type"] != "Bearer"
    all_good = false
  end
  if not data.has_key?("access_token")
    all_good = false
  end
  if not all_good
    print("login.rb: Failed test case\nRequest:\n")
    p test_case_request_body
    print("login.rb: Response\n")
    p data
    passed = false
  end
end

negative_test_case_request_bodies = [
  {
    "email" => "jgh8iasdofgs",
    "password" => "securePassword123",
  },
  {
    "password" => "securePassword123",
  }
]


negative_test_case_request_bodies.each do |test_case_request_body|
  uri = URI(BASE_URL + '/login') 
  response = Net::HTTP.post_form(uri, test_case_request_body)
  data = JSON.parse(response.body)
  all_good = true
  if response.code == "200"
    all_good = false
  end
  if not all_good
    print("login.rb: Failed test case\nRequest:\n")
    p test_case_request_body
    print("login.rb: Response\n")
    p data
    passed = false
  end
end

if passed
  exit 0
else
  exit 1
end
