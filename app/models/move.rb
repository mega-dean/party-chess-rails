class Move < ApplicationRecord
  INTERMEDIATE_SQUARES_PER_TURN = 9

  belongs_to :piece

  def get_intermediate_squares
    intermediate_squares = self.send({
      'rook' => :get_rook_intermediate_squares,
      'knight' => :get_knight_intermediate_squares,
      'bishop' => :get_bishop_intermediate_squares,
      'queen' => :get_queen_intermediate_squares,
    }[self.piece.kind])

    INTERMEDIATE_SQUARES_PER_TURN.times do |idx|
      if !intermediate_squares[idx]
        intermediate_squares[idx] = intermediate_squares[idx - 1]
      end
    end

    intermediate_squares
  end

  private

  def get_rook_intermediate_squares
    diff = self.target_square - self.piece.square

    # FIXME These conditions will only work for moves onto the same board
    if self.target_square < self.piece.square
      if -8 < diff && diff < 0
        get_linear_intermediate_squares(:left)
      else
        get_linear_intermediate_squares(:up)
      end
    else
      if 0 < diff && diff < 8
        get_linear_intermediate_squares(:right)
      else
        get_linear_intermediate_squares(:down)
      end
    end
  end

  def get_bishop_intermediate_squares
    diff = self.target_square - self.piece.square

    if self.target_square < self.piece.square
      if diff % 9 == 0
        get_linear_intermediate_squares(:up_left)
      else
        get_linear_intermediate_squares(:up_right)
      end
    else
      if diff % 9 == 0
        get_linear_intermediate_squares(:down_right)
      else
        get_linear_intermediate_squares(:down_left)
      end
    end
  end

  def get_knight_intermediate_squares
    [self.target_square]
  end

  def get_queen_intermediate_squares
    diff = self.target_square - self.piece.square

    # Need to check this specifically because eg. moving left 7 squares and moving up-right 1 square
    # both have diff == -7.
    moving_horizontally = (self.target_square / 8) == (self.piece.square / 8)

    if self.target_square < self.piece.square
      if moving_horizontally
        get_linear_intermediate_squares(:left)
      elsif diff % 9 == 0
        get_linear_intermediate_squares(:up_left)
      elsif diff % 8 == 0
        get_linear_intermediate_squares(:up)
      else
        get_linear_intermediate_squares(:up_right)
      end
    else
      if moving_horizontally
        get_linear_intermediate_squares(:right)
      elsif diff % 9 == 0
        get_linear_intermediate_squares(:down_right)
      elsif diff % 8 == 0
        get_linear_intermediate_squares(:down)
      else
        get_linear_intermediate_squares(:down_left)
      end
    end
  end

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
end
