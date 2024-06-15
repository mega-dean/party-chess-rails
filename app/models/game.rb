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
end
