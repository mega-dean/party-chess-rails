class Game < ApplicationRecord
  has_many :players

  def reset
    Game.includes(players: { pieces: :moves })
      .find_by(id: self.id)
      .players
      .flat_map(&:pieces)
      .flat_map(&:moves)
      .map(&:destroy!)

    self.update!(current_turn: 0)
  end

  def board_hash
    h = {}

    self.boards_tall.times do |board_y|
      self.boards_wide.times do |board_x|
        h[[board_x, board_y]] = []
      end
    end

    h
  end

  def pieces_by_board
    h = self.board_hash

    players.includes(:pieces).each do |player|
      player.pieces.each do |piece|
        location = self.square_to_location(piece.square)
        h[[location[:board_x], location[:board_y]]] << piece
      end
    end

    h
  end

  # Each board is 64 consecutive indexes:
  # + - - - - - - - - + - - - - - - - - +
  # | 0 1 2 3 4 5 6 7 | 64 64 66 ...    |
  # | 8 9 ...         |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |    ... 61 62 63 |     ... 126 127 |
  # + - - - - - - - - + - - - - - - - - +
  # | 128 129 ...     |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # + - - - - - - - - + - - - - - - - - +
  def location_to_square(location)
    squares_per_board_row = self.boards_wide * 64

    (location[:board_y] * squares_per_board_row) +
      (location[:board_x] * 64) +
      (location[:y] * 8) +
      location[:x]
  end

  def square_to_location(square)
    squares_per_board_row = self.boards_wide * 64

    board_y = square / squares_per_board_row
    square %= squares_per_board_row

    board_x = square / 64
    square %= 64

    y = square / 8
    square %= 8

    x = square

    {
      board_x: board_x,
      board_y: board_y,
      x: x,
      y: y,
    }
  end

  def get_move_steps
    steps = {}
    pieces_by_board = self.pieces_by_board

    pieces_by_board.each do |(board_x, board_y), pieces|
      steps_by_piece = {}

      moves_by_piece_id = {}
      moves = Move.includes(:piece).where(turn: self.current_turn, piece_id: pieces.map(&:id)).each do |move|
        moves_by_piece_id[move.piece.id] = move
      end

      pieces_by_id = {}
      pieces.each do |piece|
        pieces_by_id[piece.id] = piece
        if move = moves_by_piece_id[piece.id]
          steps_by_piece[piece] = move.to_steps
        else
          steps_by_piece[piece] = [piece.square] * Move::STEPS_PER_TURN
        end
      end

      bumped_pieces = Set.new
      captured_pieces = Set.new

      steps[[board_x, board_y]] = Move::STEPS_PER_TURN.times.map do |idx|
        h = {}

        bumped, non_bumped = steps_by_piece.partition { |piece, _| bumped_pieces.include?(piece.id) }

        # Handling all bumped pieces first makes it easier to check for chained bumps.
        bumped.each do |piece, steps|
          h[piece.square] ||= {}
          h[piece.square][:bumped] = piece.id
        end

        non_bumped.each do |piece, steps|
          h[steps[idx]] ||= {}

          if captured_pieces.include?(piece.id)
            h[steps[idx]][:captured] = piece.id
          else
            if piece.square == steps[idx]
              h[steps[idx]][:initial] = piece.id
            elsif idx > 0 && steps[idx] == steps[idx - 1]
              if h[steps[idx]][:bumped]
                h[piece.square] ||= {}
                h[piece.square][:bumped] = piece.id
              else
                h[steps[idx]][:moved] = piece.id
              end
            else
              h[steps[idx]][:moving] ||= []
              h[steps[idx]][:moving] << piece.id
            end
          end
        end

        h.each do |square, moves|
          bump_moving_pieces = if moves[:moving]
            if moves[:moving].length > 1
              # Many pieces arrived at the square at the same time.
              true
            elsif moves[:moving].length == 1
              if moves[:moved]
                # Another piece already arrived at this square first.
                true
              elsif moves[:initial]
                moving_piece = pieces_by_id[moves[:moving].only!]
                other_piece = pieces_by_id[moves[:initial]]

                if other_piece.player.is_black == moving_piece.player.is_black
                  # Another piece was here and didn't move this turn.
                  true
                else
                  captured_pieces.add(other_piece.id)
                  false
                end
              end
            end
          end

          if bump_moving_pieces
            bumped_pieces.merge(moves[:moving])
          end
        end

        h
      end

      Piece.where(id: captured_pieces).destroy_all
    end

    steps
  end

  def process_current_moves
    steps = self.get_move_steps
    self.apply_move_steps(steps)
    self.broadcast_move_steps(steps)
  end

  private

  def apply_move_steps(steps_by_board)
    self.update!(current_turn: self.current_turn + 1)

    steps_by_board.each do |_, steps|
      final = steps.last

      final.each do |target_square, moves|
        # TODO won't work for moves to adjacent boards (steps have to be 9 long, to allow for 8 moves + 1 bump)

        if piece_id = moves[:moved]
          Piece.find(piece_id).update!(square: target_square)
        end
      end
    end
  end

  def broadcast_move_steps(steps_by_board)
    self.players.each do |player|
      data = steps_by_board.select do |(board_x, board_y), _steps|
        pieces_by_board[[board_x, board_y]].any? do |piece|
          piece.player_id == player.id
        end
      end

      broadcast_replace_to "player_#{player.id}_moves", target: 'game-moves', partial: "games/moves", locals: {
        data: data,
      }
    end
  end
end
