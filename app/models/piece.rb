class Piece < ApplicationRecord
  belongs_to :player
  has_many :moves

  KINDS = [KNIGHT, BISHOP, ROOK, QUEEN]

  class InvalidKind < StandardError; end

  validates :kind, inclusion: { in: KINDS }

  # This represents a single step in a move for a piece.
  # :kind values:
  # - :initial - the piece started in this square and isn't moving this turn
  # - :moving - the piece moved to this square this step
  # - :moved - the piece moved to this square last step, and this is the move.target_square
  # - :bumped - the piece tried moving somewhere, but got bumped back here
  # - :captured - the piece was captured
  Stage = Struct.new(:kind, :target_square, :original_board, :is_array, keyword_init: true)

  class << self
    def points(kind, error_fn = "points")
      {
        KNIGHT => 1,
        BISHOP => 2,
        ROOK => 4,
        QUEEN => 8,
      }[kind] || raise(InvalidKind.new("Piece.#{error_fn}: #{kind}"))
    end

    # Cost is greater than points so that every time a capture happens, the total number of points in the game
    # decreases. If the cost was the same as the points, then trading pieces would be inconsequential since players
    # could just spawn a new piece immediately.
    def cost(kind)
      points(kind, "cost") + 1
    end

    if Rails.env.development?
      def move(old, new)
        Piece.where(square: old).only!.update!(square: new)
      end

      def at(square, game_id: nil)
        if game_id
          Piece.where(square: square).each do |piece|
            if piece.player.game.id != game_id
              piece.destroy!
            end
          end
        end

        Piece.where(square: square).only!
      end
    end
  end

  def points
    Piece.points(self.kind)
  end

  def cost
    Piece.cost(self.kind)
  end

  def try_move(target_square:, direction:, spawn_kind: nil)
    can_make_move = !self.player.game.processing_moves &&
      self.get_target_squares.any? { |_, squares| squares.values.flatten.include?(target_square) }

    if can_make_move
      move = self.current_move

      if move
        move.update!(
          target_square: target_square,
          direction: direction,
          pending_spawn_kind: spawn_kind,
        )
      else
        self.moves.create!(
          target_square: target_square,
          turn: game.current_turn,
          direction: direction,
          pending_spawn_kind: spawn_kind,
        )
      end

      self.player.broadcast_boards
    end
  end

  def deselect
    if !self.player.game.processing_moves
      self.current_move&.destroy!

      self.player.broadcast_boards
    end
  end

  def get_target_squares
    current_location = game.square_to_location(self.square)

    move_targets = game.board_hash(:hash)

    if self.kind == KNIGHT
      set_knight_targets(move_targets, current_location)
    elsif self.kind == BISHOP
      move_targets[[current_location[:board_x], current_location[:board_y]]] = diagonal_targets
      set_diagonal_targets_to_adjacent_boards(move_targets, current_location)
    elsif self.kind == ROOK
      move_targets[[current_location[:board_x], current_location[:board_y]]] = horizontal_targets
      set_horizontal_targets_to_adjacent_boards(move_targets, current_location)
    elsif self.kind == QUEEN
      move_targets[[current_location[:board_x], current_location[:board_y]]] = diagonal_targets.merge(horizontal_targets)
      set_horizontal_targets_to_adjacent_boards(move_targets, current_location)
      set_diagonal_targets_to_adjacent_boards(move_targets, current_location)
    else
      raise("unreachable: unknown kind #{self.kind}")
    end

    move_targets
  end

  # Optional game arg in case game is already in memory.
  def current_move(game = self.player.game)
    current_moves = self.moves.where(turn: game.current_turn)
    if current_moves.length > 1
      raise "too many current moves for Piece #{self.id} (move ids: #{moves.map(&:id)})"
    else
      current_moves.first
    end
  end

  private

  def set_knight_targets(move_targets, current_location)
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

    new_targets = {}
    [
      { left: 1, up: 2 },
      { left: 2, up: 1 },
      { left: 1, down: 2 },
      { left: 2, down: 1 },
      { right: 1, up: 2 },
      { right: 2, up: 1 },
      { right: 1, down: 2 },
      { right: 2, down: 1 },
    ].each do |dist|
      # Knight move direction isn't used for anything - just making this unique per-move so that it follows the
      # same format as adjacent-board moves for other piece kinds.
      direction = dist.map { |k, v| "#{k}#{v}" }.join.to_sym
      new_targets[direction] = [{
        board_x: get_board_x.(dist),
        board_y: get_board_y.(dist),
        x: get_x.(dist),
        y: get_y.(dist),
      }]
    end

    add_target_locations(move_targets, new_targets)
  end

  def set_diagonal_targets_to_adjacent_boards(move_targets, current_location)
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

    add_target_locations(move_targets, {
      up_left: [up_left_target],
      up_right: [up_right_target],
      down_left: [down_left_target],
      down_right: [down_right_target],
    })
  end

  def set_horizontal_targets_to_adjacent_boards(move_targets, current_location)
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

    add_target_locations(move_targets, { up: [up], down: [down], left: [left], right: [right] })
  end

  def add_target_locations(move_targets, new_target_locations)
    new_target_locations.each do |direction, target_locations|
      target_locations.each do |target_location|
        board_x = target_location[:board_x]
        board_y = target_location[:board_y]
        if 0 <= board_x && board_x < game.boards_wide &&
            0 <= board_y && board_y < game.boards_tall
          move_targets[[board_x, board_y]] ||= {}
          move_targets[[board_x, board_y]][direction] ||= []
          move_targets[[board_x, board_y]][direction] << game.location_to_square(target_location)
        end
      end
    end
  end

  def horizontal_targets
    location = game.square_to_location(self.square)

    {
      up: get_targets(location[:y]) { |i| self.square - (8 * i) },
      down: get_targets(7 - location[:y]) { |i| self.square + (8 * i) },
      left: get_targets(location[:x]) { |i| self.square - i },
      right: get_targets(7 - location[:x]) { |i| self.square + i },
    }
  end

  def diagonal_targets
    location = game.square_to_location(self.square)

    up_left_targets = [location[:x], location[:y]].min
    up_right_targets = [7 - location[:x], location[:y]].min
    down_left_targets = [location[:x], 7 - location[:y]].min
    down_right_targets = [7 - location[:x], 7 - location[:y]].min

    {
      up_left: get_targets(up_left_targets) { |i| self.square - (9 * i) },
      up_right: get_targets(up_right_targets) { |i| self.square - (7 * i) },
      down_left: get_targets(down_left_targets) { |i| self.square + (7 * i) },
      down_right: get_targets(down_right_targets) { |i| self.square + (9 * i) },
    }
  end

  def get_targets(count, &blk)
    count.times.map do |i|
      yield(i + 1)
    end
  end

  def game
    @game ||= self.player.game
  end
end
