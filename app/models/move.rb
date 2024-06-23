class Move < ApplicationRecord
  STEPS_PER_TURN = 9

  belongs_to :piece

  def to_steps
    steps = self.send({
      'rook' => :get_rook_moves,
      'knight' => :get_knight_moves,
      'bishop' => :get_bishop_moves,
      'queen' => :get_queen_moves,
    }[self.piece.kind])

    STEPS_PER_TURN.times do |idx|
      if !steps[idx]
        steps[idx] = steps[idx - 1]
      end
    end

    steps
  end

  def get_rook_moves
    diff = self.target_square - self.piece.square

    if self.target_square < self.piece.square
      if -8 < diff && diff < 0
        # left
        get_steps(-1)
      else
        # up
        get_steps(-8)
      end
    else
      if 0 < diff && diff < 8
        # right
        get_steps(1)
      else
        # down
        get_steps(8)
      end
    end
  end

  def get_bishop_moves
    diff = self.target_square - self.piece.square

    if self.target_square < self.piece.square
      if diff % 9 == 0
        # up left
        get_steps(-9)
      else
        # up right
        get_steps(-7)
      end
    else
      if diff % 9 == 0
        # down right
        get_steps(9)
      else
        # down left
        get_steps(7)
      end
    end
  end

  def get_knight_moves
    [self.target_square]
  end

  def get_queen_moves
    diff = self.target_square - self.piece.square

    # Need to check this specifically because eg. moving left 7 squares and moving up-right 1 square
    # both have diff == -7.
    moving_horizontally = (self.target_square / 8) == (self.piece.square / 8)

    if self.target_square < self.piece.square
      if moving_horizontally
        # left
        get_steps(-1)
      elsif diff % 9 == 0
        # up left
        get_steps(-9)
      elsif diff % 8 == 0
        # up
        get_steps(-8)
      else
        # up right
        get_steps(-7)
      end
    else
      if moving_horizontally
        # right
        get_steps(1)
      elsif diff % 9 == 0
        # down right
        get_steps(9)
      elsif diff % 8 == 0
        # down
        get_steps(8)
      else
        # down left
        get_steps(7)
      end
    end
  end

  def get_steps(step_size)
    current_square = self.piece.square
    steps = []

    while current_square != self.target_square
      next_square = current_square + step_size
      steps << next_square
      current_square = next_square
    end

    steps
  end
end
