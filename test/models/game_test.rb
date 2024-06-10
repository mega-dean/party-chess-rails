require "test_helper"

class GameTest < ActiveSupport::TestCase
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
        game.get_square_idx(board_x: c[0], board_y: c[1], x: c[2], y: c[3]),
        expected,
      )
    end
  end
end
