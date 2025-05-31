# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create all UNO cards in the database
puts "Creating UNO cards..."

Card.create_deck.each do |card_data|
  Card.find_or_create_by(card_data)
end

puts "Created #{Card.count} UNO cards"

# Create a sample user for testing
sample_user = User.find_or_create_by(username: 'player1')
puts "Created sample user: #{sample_user.username}"
