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

  def expect_target_squares(piece, expected_moves, board: [0, 0])
    target_squares = piece.get_target_squares[board]
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

      it "includes moves to adjacent boards" do
        knight = @player.pieces.create!(kind: 'knight', square: 48)

        expect_target_squares(knight, [
          [0, 1],
        ], board: [0, 1])

        knight.update!(square: 63)

        expect_target_squares(knight, [
          [0, 5],
          [1, 6],
        ], board: [1, 0])

        expect_target_squares(knight, [
          [0, 1],
          [1, 0],
        ], board: [1, 1])

        expect_target_squares(knight, [
          [6, 0],
          [1, 7],
        ], board: [0, 1])
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

      expect_target_squares(bishop, [
        [0, 6],
      ], board: [1, 0])
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

      expect_target_squares(rook, [
        [0, 1],
      ], board: [1, 0])

      expect_target_squares(rook, [
        [3, 0],
      ], board: [0, 1])
    end

    specify "queen" do
      queen = @player.pieces.create!(kind: 'queen', square: 45)

      expect_target_squares(queen, [
        # up
        [5, 4],
        [5, 3],
        [5, 2],
        [5, 1],
        [5, 0],
        # left
        [4, 5],
        [3, 5],
        [2, 5],
        [1, 5],
        [0, 5],
        # right
        [6, 5],
        [7, 5],
        # down
        [5, 6],
        [5, 7],
        # up left
        [4, 4],
        [3, 3],
        [2, 2],
        [1, 1],
        [0, 0],
        # up right
        [6, 4],
        [7, 3],
        # down left
        [4, 6],
        [3, 7],
        # down right
        [6, 6],
        [7, 7],
      ])

      expect_target_squares(queen, [
        [0, 2],
        [0, 5],
      ], board: [1, 0])

      expect_target_squares(queen, [
        [0, 0],
      ], board: [1, 1])

      expect_target_squares(queen, [
        [2, 0],
        [5, 0],
      ], board: [0, 1])
    end
  end
end
