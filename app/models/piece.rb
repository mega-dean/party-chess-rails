class Piece < ApplicationRecord
  belongs_to :player
  has_many :moves

  KINDS = ['rook', 'queen', 'knight', 'bishop']

  validates :kind, inclusion: { in: KINDS }

  def try_move(target_square)
    valid_target_squares = self.get_target_squares

    if valid_target_squares.any? {|_, squares| squares.include?(target_square) }
      move = self.moves.find_by(turn: game.current_turn)

      if move
        move.update!(target_square: target_square)
      else
        self.moves.create!(target_square: target_square, turn: game.current_turn)
      end

      broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
        player: self.player,
      }
    end
  end

  # Not calling this `.select` because that method already exists on Models.
  def set_as_selected
    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: self.player,
      target_moves: self.get_target_squares,
      selected_piece: self,
    }
  end

  def deselect
    self.moves.find_by(turn: self.player.game.current_turn)&.destroy!

    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: self.player,
    }
  end

  def get_target_squares
    current_location = game.square_to_location(self.square)

    target_moves = game.board_hash

    if self.kind == 'knight'
      set_knight_moves(target_moves, current_location)
    elsif self.kind == 'bishop'
      target_moves[[current_location[:board_x], current_location[:board_y]]] = diagonal_moves
      set_diagonal_moves_to_adjacent_boards(target_moves, current_location)
    elsif self.kind == 'rook'
      target_moves[[current_location[:board_x], current_location[:board_y]]] = horizontal_moves
      set_horizontal_moves_to_adjacent_boards(target_moves, current_location)
    elsif self.kind == 'queen'
      target_moves[[current_location[:board_x], current_location[:board_y]]] = diagonal_moves + horizontal_moves
      set_horizontal_moves_to_adjacent_boards(target_moves, current_location)
      set_diagonal_moves_to_adjacent_boards(target_moves, current_location)
    else
      raise("unreachable: unknown kind #{self.kind}")
    end

    target_moves
  end

  # Optional game arg in case game is already in memory.
  def get_current_move(game = self.player.game)
    current_moves = self.moves.where(turn: game.current_turn)
    if current_moves.length > 1
      raise "too many current moves for Piece #{self.id} (move ids: #{moves.map(&:id)})"
    else
      current_moves.first
    end
  end

  private

  def set_knight_moves(target_moves, current_location)
    x = current_location[:x]
    y = current_location[:y]
    board_x = current_location[:board_x]
    board_y = current_location[:board_y]

    get_board_x = ->(h) do
      if x < (h[:left] || 0)
        board_x - 1
      elsif x > (7 - (h[:right] || 0))
        board_x + 1
      else
        board_x
      end
    end

    get_board_y = ->(h) do
      if y < (h[:up] || 0)
        board_y - 1
      elsif y > (7 - (h[:down] || 0))
        board_y + 1
      else
        board_y
      end
    end

    get_x = ->(h) do
      if x < (h[:left] || 0)
        x + 8 - h[:left]
      elsif x > (7 - (h[:right] || 0))
        x + h[:right] - 8
      else
        dx = h[:right] || -h[:left]
        x + dx
      end
    end

    get_y = ->(h) do
      if y < (h[:up] || 0)
        y + 8 - h[:up]
      elsif y > (7 - (h[:down] || 0))
        y + h[:down] - 8
      else
        dy = h[:down] || -h[:up]
        y + dy
      end
    end

    new_moves = [
      { left: 1, up: 2 },
      { left: 2, up: 1 },
      { left: 1, down: 2 },
      { left: 2, down: 1 },
      { right: 1, up: 2 },
      { right: 2, up: 1 },
      { right: 1, down: 2 },
      { right: 2, down: 1 },
    ].map do |dist|
      {
        board_x: get_board_x.(dist),
        board_y: get_board_y.(dist),
        x: get_x.(dist),
        y: get_y.(dist),
      }
    end

    add_moves(target_moves, new_moves)
  end

  def set_diagonal_moves_to_adjacent_boards(target_moves, current_location)
    x = current_location[:x]
    y = current_location[:y]

    up_left_target, down_right_target = if x - y == 0
      [
        {
          board_x: current_location[:board_x] - 1,
          board_y: current_location[:board_y] - 1,
          x: 7,
          y: 7,
        },
        {
          board_x: current_location[:board_x] + 1,
          board_y: current_location[:board_y] + 1,
          x: 0,
          y: 0,
        },
      ]
    elsif x - y < 0
      [
        {
          board_x: current_location[:board_x] - 1,
          board_y: current_location[:board_y],
          x: 7,
          y: y - x - 1,
        },
        {
          board_x: current_location[:board_x],
          board_y: current_location[:board_y] + 1,
          x: x - y + 8,
          y: 0,
        },
      ]
    else
      [
        {
          board_x: current_location[:board_x],
          board_y: current_location[:board_y] - 1,
          x: x - y - 1,
          y: 7,
        },
        {
          board_x: current_location[:board_x] + 1,
          board_y: current_location[:board_y],
          x: 0,
          y: y - x + 8,
        },
      ]
    end

    down_left_target, up_right_target = if x + y == 7
      [
        {
          board_x: current_location[:board_x] - 1,
          board_y: current_location[:board_y] + 1,
          x: 7,
          y: 0,
        },
        {
          board_x: current_location[:board_x] + 1,
          board_y: current_location[:board_y] - 1,
          x: 0,
          y: 7,
        },
      ]
    elsif x + y < 7
      [
        {
          board_x: current_location[:board_x] - 1,
          board_y: current_location[:board_y],
          x: 7,
          y: x + y + 1,
        },
        {
          board_x: current_location[:board_x],
          board_y: current_location[:board_y] - 1,
          x: x + y + 1,
          y: 7,
        },
      ]
    else
      [
        {
          board_x: current_location[:board_x],
          board_y: current_location[:board_y] + 1,
          x: x + y - 8,
          y: 0,
        },
        {
          board_x: current_location[:board_x] + 1,
          board_y: current_location[:board_y],
          x: 0,
          y: x + y - 8,
        },
      ]
    end

    add_moves(target_moves, [up_left_target, up_right_target, down_left_target, down_right_target])
  end

  def set_horizontal_moves_to_adjacent_boards(target_moves, current_location)
    up = {
      board_x: current_location[:board_x],
      board_y: current_location[:board_y] - 1,
      x: current_location[:x],
      y: 7,
    }
    down = {
      board_x: current_location[:board_x],
      board_y: current_location[:board_y] + 1,
      x: current_location[:x],
      y: 0,
    }
    left = {
      board_x: current_location[:board_x] - 1,
      board_y: current_location[:board_y],
      x: 7,
      y: current_location[:y],
    }
    right = {
      board_x: current_location[:board_x] + 1,
      board_y: current_location[:board_y],
      x: 0,
      y: current_location[:y],
    }

    add_moves(target_moves, [up, down, left, right])
  end

  def add_moves(target_moves, new_moves)
    new_moves.each do |target_location|
      board_x = target_location[:board_x]
      board_y = target_location[:board_y]
      if 0 <= board_x && board_x < game.boards_wide &&
          0 <= board_y && board_y < game.boards_tall
        target_moves[[board_x, board_y]] ||= []
        target_moves[[board_x, board_y]] <<
          game.location_to_square({
            board_x: board_x,
            board_y: board_y,
            x: target_location[:x],
            y: target_location[:y],
          })
      end
    end
  end

  def horizontal_moves
    location = game.square_to_location(self.square)

    get_moves(location[:y]) { |i| self.square - (8 * i) } +
      get_moves(7 - location[:y]) { |i| self.square + (8 * i) } +
      get_moves(location[:x]) { |i| self.square - i } +
      get_moves(7 - location[:x]) { |i| self.square + i }
  end

  def diagonal_moves
    location = game.square_to_location(self.square)

    up_left_targets = [location[:x], location[:y]].min
    up_right_targets = [7 - location[:x], location[:y]].min
    down_left_targets = [location[:x], 7 - location[:y]].min
    down_right_targets = [7 - location[:x], 7 - location[:y]].min

    get_moves(up_left_targets) { |i| self.square - (9 * i) } +
      get_moves(up_right_targets) { |i| self.square - (7 * i) } +
      get_moves(down_left_targets) { |i| self.square + (7 * i) } +
      get_moves(down_right_targets) { |i| self.square + (9 * i) }
  end

  def get_moves(count, &blk)
    count.times.map do |i|
      yield(i + 1)
    end
  end

  def game
    @game ||= self.player.game
  end
end
