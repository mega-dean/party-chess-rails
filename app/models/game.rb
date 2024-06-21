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
        location = self.idx_to_location(piece.square)
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
  def location_to_idx(location)
    squares_per_board_row = self.boards_wide * 64

    (location[:board_y] * squares_per_board_row) +
      (location[:board_x] * 64) +
      (location[:y] * 8) +
      location[:x]
  end

  def idx_to_location(idx)
    squares_per_board_row = self.boards_wide * 64

    board_y = idx / squares_per_board_row
    idx %= squares_per_board_row

    board_x = idx / 64
    idx %= 64

    y = idx / 8
    idx %= 8

    x = idx

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

      # CLEANUP make sure this .includes is actually helping
      moves = Move.includes(:piece).where(turn: self.current_turn, piece_id: pieces.map(&:id))
      piece_ids = Set.new(moves.map(&:piece_id))

      pieces.each do |piece|
        if piece_ids.include?(piece.id)
          # CLEANUP add .only!
          # CLEANUP this could be a method piece.get_current_move(game)
          move = piece.moves.where(turn: self.current_turn).first
          steps_by_piece[piece] = move.to_steps
        else
          steps_by_piece[piece] = [piece.square] * 8
        end
      end

      bumped_pieces = Set.new
      captured_pieces = Set.new

      steps[[board_x, board_y]] = 8.times.map do |idx|
        h = {}

        # CLEANUP comment
        bumped, non_bumped = steps_by_piece.partition { |piece, _| bumped_pieces.include?(piece.id) }

        bumped.each do |piece, steps|
          h[piece.square] ||= {}
          h[piece.square][:bumped] = piece.id
        end

        non_bumped.each do |piece, steps|
          if captured_pieces.include?(piece.id)
            #noop
          else
            h[steps[idx]] ||= {}

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
            # CLEANUP maybe combine some of these conditions if possible
            if moves[:moving].length > 1
              true
            elsif moves[:moving].length == 1
              if moves[:moved]
                true
              elsif moves[:initial]
                # CLEANUP avoid these lookups
                piece = Piece.find(moves[:moving].first)
                other_piece = Piece.find(moves[:initial])

                if other_piece.player.is_black == piece.player.is_black
                  true
                else
                  # CLEANUP maybe just .destroy inline here and remove from steps_by_piece
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
        # FIXME will probably need to check :moving here too, for the case where piece moves 8 squares (and is still moving at the last step)
        # - actually that probably means these steps have to be 9 long, to allow for 8 moves + 1 bump

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
