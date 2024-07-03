require "rails_helper"

RSpec.describe Game do
  before do
    @game = Game.create(boards_tall: 2, boards_wide: 2, last_turn_completed_at: Time.now.utc)
    @big_game = Game.create(boards_tall: 10, boards_wide: 10, last_turn_completed_at: Time.now.utc)
    @player = @game.players.create!(is_black: true)
  end

  specify "pieces_by_board" do
    @player.pieces.create!(square: 0, kind: 'knight')

    {
      [0, 0] => 1,
      [1, 0] => 0,
      [0, 1] => 0,
      [1, 1] => 0,
    }.each do |coords, expected|
      expect(@game.pieces_by_board[coords].count).to eq(expected)
    end

    @player.pieces.create!(square: 1, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 0,
      [0, 1] => 0,
      [1, 1] => 0,
    }.each do |coords, expected|
      expect(@game.pieces_by_board[coords].count).to eq(expected)
    end

    @player.pieces.create!(square: 64, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 1,
      [0, 1] => 0,
      [1, 1] => 0,
    }.each do |coords, expected|
      expect(@game.pieces_by_board[coords].count).to eq(expected)
    end

    @player.pieces.create!(square: 64 * 3, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 1,
      [0, 1] => 0,
      [1, 1] => 1,
    }.each do |coords, expected|
      expect(@game.pieces_by_board[coords].count).to eq(expected)
    end

    @player.pieces.create!(square: 64 * 2, kind: 'knight')

    {
      [0, 0] => 2,
      [1, 0] => 1,
      [0, 1] => 1,
      [1, 1] => 1,
    }.each do |coords, expected|
      expect(@game.pieces_by_board[coords].count).to eq(expected)
    end
  end

  specify "location_to_square" do
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
      expect(@big_game.location_to_square({ board_x: c[0], board_y: c[1], x: c[2], y: c[3] })).to eq(expected)
    end
  end

  specify "square_to_location" do
    cases = {
      0 => [ 0, 0, 0, 0 ],
      64 => [ 1, 0, 0, 0 ],
      640 => [ 0, 1, 0, 0 ],
      1 => [ 0, 0, 1, 0 ],
      8 => [ 0, 0, 0, 1 ],
      713 => [ 1, 1, 1, 1 ],
      1379 => [ 1, 2, 3, 4 ],
    }
    cases.each do |square, expected|
      h = @big_game.square_to_location(square)

      expect(h[:board_x]).to eq(expected[0])
      expect(h[:board_y]).to eq(expected[1])
      expect(h[:x]).to eq(expected[2])
      expect(h[:y]).to eq(expected[3])
    end
  end

  describe "get_move_steps" do
    def sort_values(h)
      h.each do |k, sub_h|
        sub_h.each do |sub_k, v|
          if v.is_a?(Array)
            sub_h[sub_k] = v.sort
          end
        end
      end
    end

    def expect_moves(expected, move_steps = nil)
      move_steps ||= @game.get_move_steps(@game.build_cache)[[0, 0]]

      expected.each.with_index do |step, idx|
        sorted_move_step = sort_values(move_steps[idx])
        sorted_step = sort_values(step)

        expect(sorted_move_step).to eq(sorted_step)
      end

      remaining_steps = Move::INTERMEDIATE_SQUARES_PER_TURN - expected.length
      final_step = expected.last

      remaining_steps.times do |idx|
        expect(move_steps[expected.length + idx]).to eq(final_step)
      end
    end

    it "tracks pieces that haven't moved" do
      rook = @player.pieces.create!(kind: 'rook', square: 73)
      move_steps = @game.get_move_steps(@game.build_cache)[[1, 0]]

      expect_moves(
        [{ 73 => { initial: rook.id }}],
        move_steps,
      )
    end

    it "steps through each square for linear pieces" do
      rook = @player.pieces.create!(kind: 'rook', square: 73)
      rook.try_move(target_square: 77, direction: :right)
      move_steps = @game.get_move_steps(@game.build_cache)[[1, 0]]

      expect_moves(
        [
          { 74 => { moving: [rook.id] }},
          { 75 => { moving: [rook.id] }},
          { 76 => { moving: [rook.id] }},
          { 77 => { moving: [rook.id] }},
          { 77 => { moved: rook.id }},
        ],
        move_steps,
      )
    end

    it "moves knights in one step" do
      knight = @player.pieces.create!(kind: 'knight', square: 20)
      knight.try_move(target_square: 35, direction: :left1down2)

      expect_moves([
        { 35 => { moving: [knight.id] }},
        { 35 => { moved: knight.id }},
      ])
    end

    describe "bumped pieces" do
      it "bumps two pieces that have moved to the same square on the same step" do
        bishop = @player.pieces.create!(kind: 'bishop', square: 21)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        rook.try_move(target_square: 51, direction: :down)
        bishop.try_move(target_square: 49, direction: :down_left)

        expect_moves([
          { 27 => { moving: [rook.id]}, 28 => { moving: [bishop.id] }},
          { 35 => { moving: [rook.id, bishop.id] }},
          { 19 => { bumped: rook.id }, 21 => { bumped: bishop.id }},
        ])
      end

      it "does not bump pieces that move past each other" do
        queen = @player.pieces.create!(kind: 'queen', square: 22)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        rook.try_move(target_square: 23, direction: :right)
        queen.try_move(target_square: 17, direction: :left)

        expect_moves([
          { 20 => { moving: [rook.id] }, 21 => { moving: [queen.id] }},
          { 21 => { moving: [rook.id] }, 20 => { moving: [queen.id] }},
          { 22 => { moving: [rook.id] }, 19 => { moving: [queen.id] }},
          { 23 => { moving: [rook.id] }, 18 => { moving: [queen.id] }},
          { 23 => { moved: rook.id }, 17 => { moving: [queen.id] }},
          { 23 => { moved: rook.id }, 17 => { moved: queen.id }},
        ])
      end

      it "bumps a piece that arrives to a square second" do
        queen = @player.pieces.create!(kind: 'queen', square: 22)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        rook.try_move(target_square: 21, direction: :right)
        queen.try_move(target_square: 21, direction: :left)

        expect_moves([
          { 20 => { moving: [rook.id] }, 21 => { moving: [queen.id] }},
          { 21 => { moving: [rook.id], moved: queen.id }},
          { 19 => { bumped: rook.id }, 21 => { moved: queen.id }},
        ])
      end

      it "bumps a piece when the other piece hasn't moved" do
        queen = @player.pieces.create!(kind: 'queen', square: 22)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        rook.try_move(target_square: 23, direction: :right)

        expect_moves([
          { 20 => { moving: [rook.id] }, 22 => { initial: queen.id }},
          { 21 => { moving: [rook.id] }, 22 => { initial: queen.id }},
          { 22 => { moving: [rook.id], initial: queen.id }},
          { 19 => { bumped: rook.id }, 22 => { initial: queen.id }},
        ])
      end

      it "chains bumps" do
        queen = @player.pieces.create!(kind: 'queen', square: 22)
        bishop = @player.pieces.create!(kind: 'bishop', square: 26)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        rook.try_move(target_square: 23, direction: :right)
        bishop.try_move(target_square: rook.square, direction: :up_right)

        expect_moves([
          { 20 => { moving: [rook.id] }, 19 => { moving: [bishop.id] }, 22 => { initial: queen.id }},
          { 21 => { moving: [rook.id] }, 19 => { moved: bishop.id }, 22 => { initial: queen.id }},
          { 22 => { moving: [rook.id], initial: queen.id }, 19 => { moved: bishop.id }},
          { 19 => { bumped: rook.id }, 26 => { bumped: bishop.id }, 22 => { initial: queen.id }},
        ])
      end

      it "chains several bumps" do
        knight = @player.pieces.create!(kind: 'knight', square: 36)
        queen = @player.pieces.create!(kind: 'queen', square: 21)
        bishop = @player.pieces.create!(kind: 'bishop', square: 26)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        rook.try_move(target_square: 23, direction: :right)
        bishop.try_move(target_square: rook.square, direction: :up_right)
        knight.try_move(target_square: bishop.square, direction: :left2up1)

        expect_moves([
          {
            20 => { moving: [rook.id] },
            19 => { moving: [bishop.id] },
            21 => { initial: queen.id },
            26 => { moving: [knight.id] },
          },
          {
            21 => { moving: [rook.id], initial: queen.id },
            19 => { moved: bishop.id },
            26 => { moved: knight.id },
          },
          {
            19 => { bumped: rook.id },
            26 => { bumped: bishop.id },
            36 => { bumped: knight.id },
            21 => { initial: queen.id },
          },
        ])
      end
    end

    describe "captures" do
      def expect_captured(piece)
        expect { Piece.find(piece.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      def expect_not_captured(piece)
        expect { Piece.find(piece.id) }.not_to raise_error
      end

      it "captures pieces of different color" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)

        rook.try_move(target_square: 22, direction: :right)

        cache = @game.build_cache
        move_steps = @game.get_move_steps(cache)

        expect_moves(
          [
            { 20 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 21 => { moving: [rook.id] }, 22 => { initial: queen.id }},
            { 22 => { moving: [rook.id], initial: queen.id }},
            { 22 => { moved: rook.id, captured: queen.id }, },
          ],
          move_steps[[0, 0]],
        )

        @game.apply_move_steps(move_steps, cache)
        expect_captured(queen)
      end

      it "does not capture when both capturing pieces bump each other" do
        bishop = @player.pieces.create!(kind: 'bishop', square: 43)
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)

        rook.try_move(target_square: 22, direction: :right)
        bishop.try_move(target_square: 22, direction: :up_right)

        cache = @game.build_cache
        move_steps = @game.get_move_steps(cache)

        expect_moves(
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
          move_steps[[0, 0]],
        )

        @game.apply_move_steps(move_steps, cache)
        expect_not_captured(queen)
      end

      it "can capture multiple pieces" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)
        bishop = other_player.pieces.create!(kind: 'bishop', square: 20)

        rook.try_move(target_square: 22, direction: :right)

        cache = @game.build_cache
        move_steps = @game.get_move_steps(cache)

        expect_moves([
          { 20 => { moving: [rook.id], initial: bishop.id }, 22 => { initial: queen.id }},
          { 21 => { moving: [rook.id] }, 20 => { captured: bishop.id }, 22 => { initial: queen.id }},
          { 22 => { moving: [rook.id], initial: queen.id }, 20 => { captured: bishop.id }},
          { 22 => { moved: rook.id, captured: queen.id }, 20 => { captured: bishop.id }},
        ],
        move_steps[[0, 0]])

        @game.apply_move_steps(move_steps, cache)
        expect_captured(bishop)
        expect_captured(queen)
      end

      it "gives points to the capturer" do
        rook = @player.pieces.create!(kind: 'rook', square: 19)

        other_player = @game.players.create!(is_black: false)
        queen = other_player.pieces.create!(kind: 'queen', square: 22)
        bishop = other_player.pieces.create!(kind: 'bishop', square: 20)

        rook.try_move(target_square: 22, direction: :right)

        original_score = @player.score

        expect {
          @game.get_move_steps(@game.build_cache)
        }.to change { @player.reload.points }.by(Piece.points('queen') + Piece.points('bishop'))

        expect(@player.reload.score).to eq(original_score)
      end
    end

    describe "moves to adjacent boards" do
      it "moves pieces to different boards" do
        rook = @player.pieces.create!(kind: 'rook', square: 36)
        rook.try_move(target_square: 96, direction: :right)

        move_steps_on_initial_board = @game.get_move_steps(@game.build_cache)[[0, 0]]
        move_steps_on_adjacent_board = @game.get_move_steps(@game.build_cache)[[1, 0]]

        expect_moves(
          [
            { 37 => { moving: [rook.id] }},
            { 38 => { moving: [rook.id] }},
            { 39 => { moving: [rook.id] }},
            { 96 => { moving: [rook.id] }},
            {},
          ],
          move_steps_on_initial_board,
        )

        expect_moves(
          [
            {},
            {},
            {},
            { 96 => { moving: [rook.id] }},
            { 96 => { moved: rook.id }},
          ],
          move_steps_on_adjacent_board,
        )
      end

      it "can bump pieces that move to different boards" do
        rook = @player.pieces.create!(kind: 'rook', square: 36)
        knight = @player.pieces.create!(kind: 'knight', square: 96)
        rook.try_move(target_square: 96, direction: :right)

        move_steps_on_initial_board = @game.get_move_steps(@game.build_cache)[[0, 0]]
        move_steps_on_adjacent_board = @game.get_move_steps(@game.build_cache)[[1, 0]]

        expect_moves(
          [
            { 37 => { moving: [rook.id] }},
            { 38 => { moving: [rook.id] }},
            { 39 => { moving: [rook.id] }},
            { 96 => { moving: [rook.id] }},
            { 36 => { bumped: rook.id }},
          ],
          move_steps_on_initial_board,
        )

        expect_moves(
          [
            { 96 => { initial: knight.id }},
            { 96 => { initial: knight.id }},
            { 96 => { initial: knight.id }},
            { 96 => { moving: [rook.id], initial: knight.id }},
            { 96 => { initial: knight.id }, 36 => { bumped: rook.id }},
          ],
          move_steps_on_adjacent_board,
        )
      end

      it "can chain bump pieces that move to different boards" do
        rook = @player.pieces.create!(kind: 'rook', square: 96)
        knight = @player.pieces.create!(kind: 'knight', square: 12)
        bishop = @player.pieces.create!(kind: 'bishop', square: 39)

        bishop.try_move(target_square: 12, direction: :up_left)
        rook.try_move(target_square: 39, direction: :left)

        move_steps_on_initial_board = @game.get_move_steps(@game.build_cache)[[0, 0]]
        move_steps_on_adjacent_board = @game.get_move_steps(@game.build_cache)[[1, 0]]

        expect_moves(
          [
            { 12 => { initial: knight.id }, 30 => { moving: [bishop.id] }, 39 => { moving: [rook.id] }},
            { 12 => { initial: knight.id }, 21 => { moving: [bishop.id] }, 39 => { moved: rook.id }},
            { 12 => { initial: knight.id, moving: [bishop.id] }, 39 => { moved: rook.id }},
            { 12 => { initial: knight.id }, 39 => { bumped: bishop.id }, 96 => { bumped: rook.id }},
          ],
          move_steps_on_initial_board,
        )

        expect_moves(
          [
            { 39 => { moving: [rook.id] }},
            {},
            {},
            { 96 => { bumped: rook.id }},
          ],
          move_steps_on_adjacent_board,
        )
      end
    end
  end

  describe "apply_move_steps" do
    it "updates piece.square for pieces that complete a move" do
      rook = @player.pieces.create!(kind: 'rook', square: 36)
      rook.try_move(target_square: 39, direction: :right)

      cache = @game.build_cache
      steps = @game.get_move_steps(cache)

      expect {
        @game.apply_move_steps(steps, cache)
      }.to change { rook.reload.square }.from(36).to(39)
    end

    it "does not update piece.square when a piece is bumped" do
      rook = @player.pieces.create!(kind: 'rook', square: 36)
      bishop = @player.pieces.create!(kind: 'bishop', square: 37)
      rook.try_move(target_square: 39, direction: :right)

      cache = @game.build_cache
      steps = @game.get_move_steps(cache)

      expect {
        @game.apply_move_steps(steps, cache)
      }.not_to change { rook.reload.square }
    end

    it "spawns new pieces for each move.pending_spawn_kind" do
      original_rook_square = 36
      rook = @player.pieces.create!(kind: 'rook', square: original_rook_square)
      rook.try_move(target_square: 39, direction: :right, spawn_kind: 'bishop')

      cache = @game.build_cache
      steps = @game.get_move_steps(cache)

      expect {
        @game.apply_move_steps(steps, cache)
      }.to change { @player.reload.pieces.count }.by(1)

      spawned_piece = Piece.last

      expect(spawned_piece.kind).to eq('bishop')
      expect(spawned_piece.square).to eq(original_rook_square)
    end

    it "does not spawn new pieces when no move.pending_spawn_kind is set" do
      rook = @player.pieces.create!(kind: 'rook', square: 36)
      rook.try_move(target_square: 39, direction: :right)

      cache = @game.build_cache
      steps = @game.get_move_steps(cache)

      expect {
        @game.apply_move_steps(steps, cache)
      }.not_to change { @player.reload.pieces.count }
    end
  end

  describe "get_boards_to_broadcast" do
    def expect_broadcast_boards(expected_boards)
      cache = @game.build_cache
      steps = @game.get_move_steps(cache)
      @game.apply_move_steps(steps, cache)
      broadcast_boards = @game.get_boards_to_broadcast(@player, steps)

      expect(broadcast_boards.keys.sort).to eq(expected_boards.sort)
    end

    specify "pieces starting on board" do
      rook = @player.pieces.create!(kind: 'rook', square: 36)
      rook.try_move(target_square: 39, direction: :right)

      expect_broadcast_boards([[0, 0]])
    end

    specify "pieces ending on board" do
      rook = @player.pieces.create!(kind: 'rook', square: 39)
      rook.try_move(target_square: 96, direction: :right)

      bishop = @player.pieces.create!(kind: 'bishop', square: 0)
      bishop.try_move(target_square: 192, direction: :down_right)

      expect_broadcast_boards([[0, 0], [1, 0], [1, 1]])
    end

    specify "piece moves to board but gets bumped back" do
      rook = @player.pieces.create!(kind: 'rook', square: 36)
      other_player = @game.players.create!(is_black: @player.is_black)
      knight = other_player.pieces.create!(kind: 'knight', square: 96)
      rook.try_move(target_square: 96, direction: :right)

      expect_broadcast_boards([[0, 0], [1, 0]])
    end

    specify "piece on edge of board moves to board but gets bumped back" do
      rook = @player.pieces.create!(kind: 'rook', square: 39)
      other_player = @game.players.create!(is_black: @player.is_black)
      knight = other_player.pieces.create!(kind: 'knight', square: 96)

      rook.try_move(target_square: 96, direction: :right)

      expect_broadcast_boards([[0, 0], [1, 0]])
    end
  end
end
