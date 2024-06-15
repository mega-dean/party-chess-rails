require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "pieces_by_board" do
    game = Game.create!(boards_wide: 2, boards_tall: 2)
    player = game.players.create!(is_black: true)

    player.pieces.create!(square: 0, kind: 'knight')

    {
      [0, 0] => 1,
      [1, 0] => 0,
      [0, 1] => 0,
      [1, 1] => 0,
    }.each do |coords, expected|
      assert_equal(
        expected,
        game.pieces_by_board[coords].count,
      )
    end

    player.pieces.create!(square: 1, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 0,
      [0, 1] => 0,
      [1, 1] => 0,
    }.each do |coords, expected|
      assert_equal(
        expected,
        game.pieces_by_board[coords].count,
      )
    end

    player.pieces.create!(square: 64, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 1,
      [0, 1] => 0,
      [1, 1] => 0,
    }.each do |coords, expected|
      assert_equal(
        expected,
        game.pieces_by_board[coords].count,
      )
    end

    player.pieces.create!(square: 64 * 3, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 1,
      [0, 1] => 0,
      [1, 1] => 1,
    }.each do |coords, expected|
      assert_equal(
        expected,
        game.pieces_by_board[coords].count,
      )
    end

    player.pieces.create!(square: 64 * 2, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 1,
      [0, 1] => 1,
      [1, 1] => 1,
    }.each do |coords, expected|
      assert_equal(
        expected,
        game.pieces_by_board[coords].count,
      )
    end
  end

  test "location_to_idx" do
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
        game.location_to_idx({ board_x: c[0], board_y: c[1], x: c[2], y: c[3] }),
      )
    end
  end

  test "idx_to_location" do
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
      h = game.idx_to_location(idx)

      assert_equal(expected[0], h[:board_x], 'board_x')
      assert_equal(expected[1], h[:board_y], 'board_x')
      assert_equal(expected[2], h[:x], 'x')
      assert_equal(expected[3], h[:y], 'y')
    end
  end
end
