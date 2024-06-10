class Game < ApplicationRecord
  has_many :players

  def all_pieces
    players.includes(:pieces).reduce({}) do |acc, player|
      player.pieces.each do |piece|
        acc[piece.square] = piece
      end
      acc
    end
  end

  def pieces_by_board
    players.includes(:pieces).reduce({}) do |acc, player|
      player.pieces.each do |piece|
        location = self.from_square_idx(piece.square)
        acc[[location[:board_x], location[:board_y]]] ||= []
        acc[[location[:board_x], location[:board_y]]] << piece
      end
      acc
    end
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
  def get_square_idx(board_x:, board_y:, x:, y:)
    squares_per_board_row = self.boards_wide * 64

    (board_y * squares_per_board_row) +
      (board_x * 64) +
      (y * 8) +
      x
  end

  def from_square_idx(idx)
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
