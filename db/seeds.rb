# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

game = Game.create!(boards_tall: 2, boards_wide: 2, last_turn_completed_at: Time.now.utc)
second_game = Game.create!(boards_tall: 3, boards_wide: 3, last_turn_completed_at: Time.now.utc)
puts "created #{Game.count} games"

black_player = game.players.create!(is_black: true)
white_player = game.players.create!(is_black: false)
puts "created #{Player.count} players"

black_player.pieces.create!(kind: ROOK, square: 3)
black_player.pieces.create!(kind: KNIGHT, square: (64 * 4) - 4)
white_player.pieces.create!(kind: QUEEN, square: 5)
white_player.pieces.create!(kind: BISHOP, square: (64 * 4) - 6)
puts "created #{Piece.count} pieces"
