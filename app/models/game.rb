class Game < ApplicationRecord
  has_many :players

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

  def process_current_moves
    # TODO
    # self.update!(current_turn: self.current_turn + 1)
    self.pieces_by_board.map do |(board_x, board_y), pieces|
      steps_by_piece = {}

      # CLEANUP make sure this .includes is actually helping
      moves = Move.includes(:piece).where(turn: self.current_turn, piece_id: pieces.map(&:id))
      piece_ids = Set.new(moves.map(&:piece_id))

      pieces_without_move = pieces.select do |piece|
        !piece_ids.include?(piece.id)
      end

      moves.each do |move|
        steps_by_piece[move.piece] = move.to_steps
      end

      pieces_without_move.each do |piece|
        steps_by_piece[piece] = [piece.square] * 8
      end

      bumped_pieces = Set.new

      8.times.map do |idx|
        h = {}

        steps_by_piece.each do |piece, steps|
          h[steps[idx]] ||= {}
          h[steps[idx]][:moving] ||= []

          if bumped_pieces.include?(piece.id)
            h[piece.square] ||= {}
            h[piece.square][:moving] ||= []
            h[piece.square][:initial] = piece.id
          elsif piece.square == steps[idx]
            h[steps[idx]][:initial] = piece.id
          elsif idx > 0 && steps[idx] == steps[idx - 1]
            h[steps[idx]][:moved] = piece.id
          else
            h[steps[idx]][:moving] << piece.id
          end
        end

        h.each do |square, moves|
          bump_moving_pieces =
            moves[:moving].length > 1 ||
            moves[:moving].length == 1 && (moves[:initial] || moves[:moved])

          if bump_moving_pieces
            bumped_pieces.merge(moves[:moving])
          end
        end

        h
      end
    end
  end
end
