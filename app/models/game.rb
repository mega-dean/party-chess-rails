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

  # Each board is 64 consecutive indexes:
  # + - - - - - - - - + - - - - - - - - +
  # | 0 1 2 3 4 5 6 7 | 65 66 67 ...    |
  # | 8 9 ...         |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |                 |                 |
  # |    ... 62 63 64 |     ... 127 128 |
  # + - - - - - - - - + - - - - - - - - +
  # | 129 130 ...     |                 |
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
end
