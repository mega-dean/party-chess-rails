require "rails_helper"

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

  describe "get_move_steps" do
    before do
      @game = Game.create(boards_tall: 2, boards_wide: 2)
      @player = @game.players.create!(is_black: true)
    end

    it "tracks pieces that haven't moved" do
      rook = @player.pieces.create!(kind: 'rook', square: 73)
      move_steps = @game.get_move_steps[[1, 0]]

      assert_equal(
        [
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
          { 73 => { initial: rook.id }},
        ],
        move_steps,
      )
    end

    describe "rook movement" do
      it "steps through each square for linear pieces" do
        rook = @player.pieces.create!(kind: 'rook', square: 73)
        rook.make_move({
          board_x: 1,
          board_y: 0,
          x: 5,
          y: 1,
        })
        move_steps = @game.get_move_steps[[1, 0]]

        assert_equal(
          [
            { 74 => { moving: [rook.id] }},
            { 75 => { moving: [rook.id] }},
            { 76 => { moving: [rook.id] }},
            { 77 => { moving: [rook.id] }},
            { 77 => { moved: rook.id }},
            { 77 => { moved: rook.id }},
            { 77 => { moved: rook.id }},
            { 77 => { moved: rook.id }},
          ],
          move_steps,
        )
      end
    end

    describe "knight movement" do
      it "moves knights in one step" do
        knight = @player.pieces.create!(kind: 'knight', square: 20)
        knight.make_move({
          board_x: 0,
          board_y: 0,
          x: 35,
          y: 0,
        })
        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 35 => { moving: [knight.id] }},
            { 35 => { moved: knight.id }},
            { 35 => { moved: knight.id }},
            { 35 => { moved: knight.id }},
            { 35 => { moved: knight.id }},
            { 35 => { moved: knight.id }},
            { 35 => { moved: knight.id }},
            { 35 => { moved: knight.id }},
          ],
          move_steps,
        )
      end
    end

    describe "bumped pieces" do
      it "bumps two pieces that have moved to the same square on the same step" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)
        bishop = @player.pieces.create!(kind: 'bishop', square: 21)

        rook.make_move({
          board_x: 0,
          board_y: 0,
          x: 3,
          y: 6,
        })

        bishop.make_move({
          board_x: 0,
          board_y: 0,
          x: 1,
          y: 6,
        })

        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 27 => { moving: [rook.id]}, 28 => { moving: [bishop.id] }},
            { 35 => { moving: [rook.id, bishop.id] }},
            { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
            { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
            { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
            { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
            { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
            { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
          ],
          move_steps,
        )
      end

      it "does not bump pieces that move past each other" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)
        queen = @player.pieces.create!(kind: 'queen', square: 22)

        rook.make_move(@game.idx_to_location(23))
        queen.make_move(@game.idx_to_location(17))

        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 20 => { moving: [rook.id] }, 21 => { moving: [queen.id] }},
            { 21 => { moving: [rook.id] }, 20 => { moving: [queen.id] }},
            { 22 => { moving: [rook.id] }, 19 => { moving: [queen.id] }},
            { 23 => { moving: [rook.id] }, 18 => { moving: [queen.id] }},
            { 23 => { moved: rook.id }, 17 => { moving: [queen.id] }},
            { 23 => { moved: rook.id }, 17 => { moved: queen.id }},
            { 23 => { moved: rook.id }, 17 => { moved: queen.id }},
            { 23 => { moved: rook.id }, 17 => { moved: queen.id }},
          ],
          move_steps,
        )
      end

      it "bumps a piece that arrives to a square second" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)
        queen = @player.pieces.create!(kind: 'queen', square: 22)

        rook.make_move(@game.idx_to_location(21))
        queen.make_move(@game.idx_to_location(21))

        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 20 => { moving: [rook.id] }, 21 => { moving: [queen.id] }},
            { 21 => { moving: [rook.id], moved: queen.id }},
            { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
            { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
            { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
            { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
            { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
            { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
          ],
          move_steps,
        )
      end

      it "bumps a piece when the other piece hasn't moved" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)
        queen = @player.pieces.create!(kind: 'queen', square: 22)

        rook.make_move(@game.idx_to_location(23))

        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 20 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 21 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 22 => { moving: [rook.id], initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
          ],
          move_steps,
        )
      end

      # FIXME this case tests when bumped piece is before moved piece
      # - also need to check the opposite case
      it "chains bumps" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)
        bishop = @player.pieces.create!(kind: 'bishop', square: 26)
        queen = @player.pieces.create!(kind: 'queen', square: 22)

        rook.make_move(@game.idx_to_location(23))
        bishop.make_move(@game.idx_to_location(19))

        move_steps = @game.get_move_steps[[0, 0]]

        # binding.pry

        assert_equal(
          [
            { 20 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 21 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 22 => { moving: [rook.id], initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
          ],
          move_steps,
        )
      end

      # FIXME test bumps after the 8th step
    end

    describe "captures" do
      def assert_captured(piece)
        assert(
          begin Piece.find(piece.id)
          rescue ActiveRecord::RecordNotFound
            true
          else
            false
          end
        )
      end

      def assert_not_captured(piece)
        assert(
          begin Piece.find(piece.id)
          rescue ActiveRecord::RecordNotFound
            false
          else
            true
          end
        )
      end

      def assert_moves(expected, actual)
        expected.each.with_index do |step, idx|
          assert_equal(step, actual[idx], "step #{idx}:")
        end
      end

      it "captures pieces of different color" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)

        rook.make_move(@game.idx_to_location(22))

        move_steps = @game.get_move_steps[[0, 0]]

        # binding.pry

        assert_equal(1, 2, 'something went wrong')

        assert_moves(
          [
            { 20 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 21 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 22 => { moving: [rook.id], initial: queen.id }},
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
          ],
          move_steps,
        )

        assert_captured(queen)
      end

      it "does not capture when both capturing pieces bump each other" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)
        bishop = @player.pieces.create!(kind: 'bishop', square: 43)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)

        rook.make_move(@game.idx_to_location(22))
        bishop.make_move(@game.idx_to_location(22))

        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 20 => { moving: [rook.id] }, 36 => { moving: [bishop.id] }, 22 => { initial: queen.id }},
            { 21 => { moving: [rook.id] }, 29 => { moving: [bishop.id] }, 22 => { initial: queen.id }},
            { 22 => { moving: [rook.id, bishop.id], initial: queen.id }},
            { 19 => { bumped: rook.id }, 43 => { bumped: bishop.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 43 => { bumped: bishop.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 43 => { bumped: bishop.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 43 => { bumped: bishop.id }, 22 => { initial: queen.id }},
            { 19 => { bumped: rook.id }, 43 => { bumped: bishop.id }, 22 => { initial: queen.id }},
          ],
          move_steps,
        )

        assert_not_captured(queen)
      end

      it "can capture multiple pieces" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)
        bishop = other_player.pieces.create!(kind: 'bishop', square: 20)

        rook.make_move(@game.idx_to_location(22))

        move_steps = @game.get_move_steps[[0, 0]]

        assert_equal(
          [
            { 20 => { moving: [rook.id], initial: bishop.id }, 22 => { initial: queen.id }},
            { 21 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 22 => { moving: [rook.id], initial: queen.id }},
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
            { 22 => { moved: rook.id }, },
          ],
          move_steps,
        )

        assert_captured(bishop)
        assert_captured(queen)
      end
    end
  end
end
