# Create two user accounts for the household
puts "Creating users..."

User.find_or_create_by!(email_address: "user1@home.local") do |u|
  u.name = "User One"
  u.password = "password123"
end

User.find_or_create_by!(email_address: "user2@home.local") do |u|
  u.name = "User Two"
  u.password = "password123"
end

puts "Created #{User.count} users"
