require 'net/http'
require 'json'

BASE_URL = "#{ARGV[0]}"

positive_test_case_request_bodies = 
[
  {
    "name" => "John Doe",
    "address" => "123 Main St, City, 04455"
  },
  {
    "name" => "John Doe",
    "address" => "123 Main St, City, 04455",
    "profile" =>
    {
      "experience": 6
    }
  }
]

passed = true
positive_test_case_request_bodies.each do |test_case_request_body|
  uri = URI(BASE_URL + '/profile/john_doe') 
  response = Net::HTTP.put(uri, test_case_request_body.to_json)
  all_good = true
  if response.code != "200"
    all_good = false
  end
  if not all_good
    print("update_profile.rb: Failed test case\nResponse:\n")
    p response
    passed = false
  end
end

if passed
  exit 0
else
  exit 1
end
