class Move < ApplicationRecord
  INTERMEDIATE_SQUARES_PER_TURN = 9

  belongs_to :piece

  validate :current_color_is_this_player, on: :create

  def get_intermediate_squares
    intermediate_squares = if self.piece.kind == KNIGHT
      [self.target_square]
    else
      get_linear_intermediate_squares(self.direction.to_sym)
    end

    INTERMEDIATE_SQUARES_PER_TURN.times do |idx|
      if !intermediate_squares[idx]
        intermediate_squares[idx] = intermediate_squares[idx - 1]
      end
    end

    intermediate_squares
  end

  private

  def on_same_board(square)
    start_location = self.piece.player.game.square_to_location(square)
    target_location = self.piece.player.game.square_to_location(self.target_square)

    start_location[:board_x] == target_location[:board_x] &&
      start_location[:board_y] == target_location[:board_y]
  end

  def get_linear_intermediate_squares(direction)
    current_square = self.piece.square
    intermediate_squares = []

    delta = {
      up_left: -9,
      up: -8,
      up_right: -7,
      left: -1,
      right: 1,
      down_left: 7,
      down: 8,
      down_right: 9,
    }[direction]

    if on_same_board(self.piece.square)
      while current_square != self.target_square
        next_square = current_square + delta
        intermediate_squares << next_square
        current_square = next_square
      end
    else
      current_location = self.piece.player.game.square_to_location(current_square)

      on_edge_of_board = -> (location) do
        x = location[:x]
        y = location[:y]

        {
          up: y == 0,
          down: y == 7,
          left: x == 0,
          right: x == 7,
          up_left: x == 0 || y == 0,
          up_right: x == 7 || y == 0,
          down_left: x == 0 || y == 7,
          down_right: x == 7 || y == 7,
        }[direction]
      end

      while !on_edge_of_board.(current_location)
        next_square = current_square + delta
        intermediate_squares << next_square
        current_square = next_square
        current_location = self.piece.player.game.square_to_location(current_square)
      end

      intermediate_squares << self.target_square
    end

    intermediate_squares
  end

  def current_color_is_this_player
    if self.piece.player.color != self.piece.player.game.current_color
      errors.add(:piece, "#{self.piece.player.color} #{self.piece.kind} tried to move, but it is #{self.piece.player.game.current_color}'s turn")
    end
  end
end
