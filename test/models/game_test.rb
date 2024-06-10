require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "pieces_by_board" do
    game = Game.create!(boards_wide: 2, boards_tall: 2)
    player = game.players.create!(is_black: true)

    player.pieces.create!(square: 0, kind: 'knight')

    assert_equal(
      [[0, 0]],
      game.pieces_by_board.keys,
    )

    player.pieces.create!(square: 1, kind: 'knight')

    assert_equal(
      [[0, 0]],
      game.pieces_by_board.keys,
    )

    player.pieces.create!(square: 64, kind: 'knight')

    assert_equal(
      [[0, 0], [1, 0]],
      game.pieces_by_board.keys,
    )

    player.pieces.create!(square: 64 * 3, kind: 'knight')

    assert_equal(
      [[0, 0], [1, 0], [1, 1]],
      game.pieces_by_board.keys,
    )

    player.pieces.create!(square: 64 * 2, kind: 'knight')

    assert_equal(
      [[0, 0], [1, 0], [1, 1], [0, 1]],
      game.pieces_by_board.keys,
    )
  end

  test "get_square_idx" do
    game = Game.new(boards_wide: 10, boards_tall: 10)
    cases = {
      [ 0, 0, 0, 0 ] => 0,
      [ 1, 0, 0, 0 ] => 64,
      [ 0, 1, 0, 0 ] => 640,
      [ 0, 0, 1, 0 ] => 1,
      [ 0, 0, 0, 1 ] => 8,
      [ 1, 1, 1, 1 ] => 713,
      [ 1, 2, 3, 4 ] => 1379,
    }
    cases.each do |c, expected|
      assert_equal(
        expected,
        game.get_square_idx(board_x: c[0], board_y: c[1], x: c[2], y: c[3]),
      )
    end
  end

  test "from_square_idx" do
    game = Game.new(boards_wide: 10, boards_tall: 10)
    cases = {
      0 => [ 0, 0, 0, 0 ],
      64 => [ 1, 0, 0, 0 ],
      640 => [ 0, 1, 0, 0 ],
      1 => [ 0, 0, 1, 0 ],
      8 => [ 0, 0, 0, 1 ],
      713 => [ 1, 1, 1, 1 ],
      1379 => [ 1, 2, 3, 4 ],
    }
    cases.each do |idx, expected|
      h = game.from_square_idx(idx)

      assert_equal(expected[0], h[:board_x], 'board_x')
      assert_equal(expected[1], h[:board_y], 'board_x')
      assert_equal(expected[2], h[:x], 'x')
      assert_equal(expected[3], h[:y], 'y')
    end
  end
end
