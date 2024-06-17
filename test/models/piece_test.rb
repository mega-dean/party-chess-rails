require "test_helper"

class PieceTest < ActiveSupport::TestCase
  setup do
    @game = Game.create!(boards_wide: 2, boards_tall: 2)
    @player = @game.players.create!(is_black: true)
  end

  def has_move(piece, x, y)
    !!piece.get_target_moves[[0, 0]].find do |location|
      location[:x] == x && location[:y] == y
    end
  end

  def assert_target_moves(piece, expected_moves)
    target_moves = piece.get_target_moves[[0, 0]]
    assert_equal(target_moves.length, expected_moves.length)

    expected_moves.each do |x, y|
      assert(!!target_moves.find { |location| location[:x] == x && location[:y] == y}, "#{x}, #{y}")
    end
  end

  test "get_target_moves: knight" do
    knight = @player.pieces.create!(kind: 'knight', square: 11)

    assert_target_moves(knight, [
      [1, 0],
      [5, 0],
      [1, 2],
      [5, 2],
      [2, 3],
      [4, 3],
    ])
  end

  test "get_target_moves: bishop" do
    bishop = @player.pieces.create!(kind: 'bishop', square: 11)

    assert_target_moves(bishop, [
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


  test "get_target_moves: rook" do
    rook = @player.pieces.create!(kind: 'rook', square: 11)

    assert_target_moves(rook, [
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

  test "get_target_moves: queen" do
    queen = @player.pieces.create!(kind: 'queen', square: 11)

    assert_target_moves(queen, [
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
