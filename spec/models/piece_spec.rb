require "rails_helper"

RSpec.describe Piece do
  before do
    @game = Game.create!(boards_wide: 2, boards_tall: 2)
    @player = @game.players.create!(is_black: true)
  end

  def has_move(piece, x, y)
    !!piece.get_target_squares[[0, 0]].find do |location|
      location[:x] == x && location[:y] == y
    end
  end

  def expect_target_squares(piece, expected_moves)
    target_squares = piece.get_target_squares[[0, 0]]
    expect(expected_moves.length).to eq(target_squares.length)

    expected_moves.each do |x, y|
      target_square = !!target_squares.find do |target_square|
        target_square_location = @game.square_to_location(target_square)
        target_square_location[:x] == x && target_square_location[:y] == y
      end
      expect(target_square).not_to be(nil)
    end
  end

  describe "try_move" do
    it "creates a move when target location is valid" do
      knight = @player.pieces.create!(kind: 'knight', square: 27)

      expect {
        knight.try_move(10)
      }.to change { knight.moves.count }.by(1)
    end

    it "does nothing when target location is invalid" do
      knight = @player.pieces.create!(kind: 'knight', square: 27)

      expect {
        knight.try_move(11)
      }.not_to change { knight.moves.count }
    end
  end

  describe "get_target_squares" do
    describe "knight" do
      it "includes all 8 moves when in the center of the board" do
        knight = @player.pieces.create!(kind: 'knight', square: 27)

        expect_target_squares(knight, [
          [2, 1],
          [4, 1],
          [1, 2],
          [5, 2],
          [1, 4],
          [5, 4],
          [2, 5],
          [4, 5],
        ])
      end

      it "trims moves when near the edge of the board" do
        knight = @player.pieces.create!(kind: 'knight', square: 48)

        expect_target_squares(knight, [
          [1, 4],
          [2, 5],
          [2, 7],
        ])

        knight.update!(square: 14)

        expect_target_squares(knight, [
          [4, 0],
          [4, 2],
          [5, 3],
          [7, 3],
        ])
      end
    end

    specify "bishop" do
      bishop = @player.pieces.create!(kind: 'bishop', square: 11)

      expect_target_squares(bishop, [
        # up left
        [2, 0],
        # up right
        [4, 0],
        # down left
        [2, 2],
        [1, 3],
        [0, 4],
        # down right
        [4, 2],
        [5, 3],
        [6, 4],
        [7, 5],
      ])
    end


    specify "rook" do
      rook = @player.pieces.create!(kind: 'rook', square: 11)

      expect_target_squares(rook, [
        # up
        [3, 0],
        # left
        [2, 1],
        [1, 1],
        [0, 1],
        # right
        [4, 1],
        [5, 1],
        [6, 1],
        [7, 1],
        # down
        [3, 2],
        [3, 3],
        [3, 4],
        [3, 5],
        [3, 6],
        [3, 7],
      ])
    end

    specify "queen" do
      queen = @player.pieces.create!(kind: 'queen', square: 11)

      expect_target_squares(queen, [
        # up
        [3, 0],
        # left
        [2, 1],
        [1, 1],
        [0, 1],
        # right
        [4, 1],
        [5, 1],
        [6, 1],
        [7, 1],
        # down
        [3, 2],
        [3, 3],
        [3, 4],
        [3, 5],
        [3, 6],
        [3, 7],
        # up left
        [2, 0],
        # up right
        [4, 0],
        # down left
        [2, 2],
        [1, 3],
        [0, 4],
        # down right
        [4, 2],
        [5, 3],
        [6, 4],
        [7, 5],
      ])
    end
  end
end
