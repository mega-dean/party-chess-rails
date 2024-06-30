require "rails_helper"

RSpec.describe Piece do
  before do
    @game = Game.create!(boards_wide: 2, boards_tall: 2, last_turn_completed_at: Time.now.utc)
    @player = @game.players.create!(is_black: true)
  end

  def has_move(piece, x, y)
    !!piece.get_target_squares[[0, 0]].find do |location|
      location[:x] == x && location[:y] == y
    end
  end

  def expect_target_squares(piece, expected_targets, board: [0, 0])
    target_squares = piece.get_target_squares[board]

    expected_targets.each do |direction, coords|
      target_squares_in_direction = target_squares[direction]
      expect(target_squares_in_direction.length).to eq(coords.length)

      coords.each do |x, y|
        if target_squares_in_direction = target_squares[direction]
          target_square = target_squares_in_direction.find do |target_square|
            target_square_location = @game.square_to_location(target_square)
            target_square_location[:x] == x && target_square_location[:y] == y
          end

          expect(target_square).not_to be(nil), "could not find target at #{x}, #{y} on board #{board}"
        else
          raise("no target_squares in direction #{direction}")
        end
      end
    end
  end

  describe "try_move" do
    before do
      @knight = @player.pieces.create!(kind: 'knight', square: 27)
    end

    it "creates a move when target location is valid" do
      expect {
        @knight.try_move(10, :left1up2)
      }.to change { @knight.moves.count }.by(1)
    end

    it "does nothing when target location is invalid" do
      expect {
        @knight.try_move(11, :invalid)
      }.not_to change { @knight.moves.count }
    end

    it "does nothing when the game is currently processing moves" do
      @game.update!(processing_moves: true)

      expect {
        @knight.try_move(10, :left1up2)
      }.not_to change { @knight.moves.count }
    end
  end

  describe "get_target_squares" do
    describe "knight" do
      it "includes all 8 moves when in the center of the board" do
        knight = @player.pieces.create!(kind: 'knight', square: 27)

        expect_target_squares(knight, {
          left1up2: [[2, 1]],
          right1up2: [[4, 1]],
          left2up1: [[1, 2]],
          right2up1: [[5, 2]],
          left2down1: [[1, 4]],
          right2down1: [[5, 4]],
          left1down2: [[2, 5]],
          right1down2: [[4, 5]],
        })
      end

      it "trims moves when near the edge of the board" do
        knight = @player.pieces.create!(kind: 'knight', square: 48)

        expect_target_squares(knight, {
          right1up2: [[1, 4]],
          right2up1: [[2, 5]],
          right2down1: [[2, 7]],
        })

        knight.update!(square: 14)

        expect_target_squares(knight, {
          left2up1: [[4, 0]],
          left2down1: [[4, 2]],
          left1down2: [[5, 3]],
          right1down2: [[7, 3]],
        })
      end

      it "includes moves to adjacent boards" do
        knight = @player.pieces.create!(kind: 'knight', square: 48)

        expect_target_squares(knight, {
          right1down2: [[1, 0]],
        }, board: [0, 1])

        knight.update!(square: 63)

        expect_target_squares(knight, {
          left2down1: [[5, 0]],
          left1down2: [[6, 1]],
        }, board: [0, 1])

        expect_target_squares(knight, {
          right2down1: [[1, 0]],
          right1down2: [[0, 1]],
        }, board: [1, 1])

        expect_target_squares(knight, {
          right2up1: [[1, 6]],
          right1up2: [[0, 5]],
        }, board: [1, 0])
      end
    end

    specify "bishop" do
      bishop = @player.pieces.create!(kind: 'bishop', square: 11)

      expect_target_squares(bishop, {
        up_left: [[2, 0]],
        up_right: [[4, 0]],
        down_left: [
          [2, 2],
          [1, 3],
          [0, 4],
        ],
        down_right: [
          [4, 2],
          [5, 3],
          [6, 4],
          [7, 5],
        ]
      })

      expect_target_squares(bishop, {
        down_right: [[0, 6]],
      }, board: [1, 0])
    end

    specify "rook" do
      rook = @player.pieces.create!(kind: 'rook', square: 11)

      expect_target_squares(rook, {
        up: [
          [3, 0],
        ],
        left: [
          [2, 1],
          [1, 1],
          [0, 1],
        ],
        right: [
          [4, 1],
          [5, 1],
          [6, 1],
          [7, 1],
        ],
        down: [
          [3, 2],
          [3, 3],
          [3, 4],
          [3, 5],
          [3, 6],
          [3, 7],
        ]
      })

      expect_target_squares(rook, {
        right: [[0, 1]],
      }, board: [1, 0])

      expect_target_squares(rook, {
        down: [[3, 0]],
      }, board: [0, 1])
    end

    specify "queen" do
      queen = @player.pieces.create!(kind: 'queen', square: 45)

      expect_target_squares(queen, {
        up: [
          [5, 4],
          [5, 3],
          [5, 2],
          [5, 1],
          [5, 0],
        ],
        left: [
          [4, 5],
          [3, 5],
          [2, 5],
          [1, 5],
          [0, 5],
        ],
        right: [
          [6, 5],
          [7, 5],
        ],
        down: [
          [5, 6],
          [5, 7],
        ],
        up_left: [
          [4, 4],
          [3, 3],
          [2, 2],
          [1, 1],
          [0, 0],
        ],
        up_right: [
          [6, 4],
          [7, 3],
        ],
        down_left: [
          [4, 6],
          [3, 7],
        ],
        down_right: [
          [6, 6],
          [7, 7],
        ],
      })

      expect_target_squares(queen, {
        up_right: [[0, 2]],
        right: [[0, 5]],
      }, board: [1, 0])

      expect_target_squares(queen, {
        down_right: [[0, 0]],
      }, board: [1, 1])

      expect_target_squares(queen, {
        down_left: [[2, 0]],
        down: [[5, 0]],
      }, board: [0, 1])
    end
  end
end
