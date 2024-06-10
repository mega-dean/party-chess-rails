# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

game = Game.create!(boards_tall: 10, boards_wide: 10)

black_player = game.players.create!(is_black: true)
white_player = game.players.create!(is_black: false)

black_player.pieces.create!(kind: 'rook', square: 3)
black_player.pieces.create!(kind: 'knight', square: 6400 - 4)
white_player.pieces.create!(kind: 'queen', square: 5)
white_player.pieces.create!(kind: 'bishop', square: 6400 - 6)
