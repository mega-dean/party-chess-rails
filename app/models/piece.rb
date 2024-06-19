class Piece < ApplicationRecord
  belongs_to :player
  has_many :moves

  KINDS = ['rook', 'queen', 'knight', 'bishop']

  validates :kind, inclusion: {
    in: KINDS
  }

  def make_move(location)
    target_square = game.location_to_idx({
      board_x: location[:target_board_x],
      board_y: location[:target_board_y],
      x: location[:target_x],
      y: location[:target_y],
    })

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

  # Not calling this `.select` because that method already exists on Models.
  def set_as_selected
    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: self.player,
      target_moves: self.get_target_moves,
      selected_piece: self,
    }
  end

  def deselect
    self.moves.find_by(turn: self.player.game.current_turn)&.destroy!

    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: self.player,
    }
  end

  def get_target_moves
    location = game.idx_to_location(self.square)

    target_moves = game.board_hash
    target_moves[[location[:board_x], location[:board_y]]] =
      {
        'rook' => horizontal_moves,
        'bishop' => diagonal_moves,
        'queen' => diagonal_moves + horizontal_moves,
        'knight' => knight_moves
      }[self.kind] || raise("unreachable: unknown kind #{self.kind}")

    target_moves

    # TODO targets to adjacent boards
  end

  private

  def horizontal_moves
    location = game.idx_to_location(self.square)

    get_moves(location[:y]) { |i| self.square - (8 * i) } +
      get_moves(7 - location[:y]) { |i| self.square + (8 * i) } +
      get_moves(location[:x]) { |i| self.square - i } +
      get_moves(7 - location[:x]) { |i| self.square + i }
  end

  def diagonal_moves
    location = game.idx_to_location(self.square)

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
      game.idx_to_location(yield(i + 1))
    end
  end

  # . . 0 . 1 . .
  # . 2 . . . 3 .
  # . . . K . . .
  # . 4 . . . 5 .
  # . . 6 . 7 . .
  def knight_moves
    current_location = game.idx_to_location(self.square)

    moves = [
      game.idx_to_location(self.square - 17),
      game.idx_to_location(self.square - 15),
      game.idx_to_location(self.square - 10),
      game.idx_to_location(self.square - 6),
      game.idx_to_location(self.square + 6),
      game.idx_to_location(self.square + 10),
      game.idx_to_location(self.square + 15),
      game.idx_to_location(self.square + 17),
    ]

    move_indexes = (0..7).to_set

    if current_location[:x] == 0
      move_indexes.subtract([0, 2, 4, 6])
    elsif current_location[:x] == 1
      move_indexes.subtract([2, 4])
    end

    if current_location[:x] == 7
      move_indexes.subtract([1, 3, 5, 7])
    elsif current_location[:x] == 6
      move_indexes.subtract([3, 5])
    end

    if current_location[:y] == 0
      move_indexes.subtract([0, 1, 2, 3])
    elsif current_location[:y] == 1
      move_indexes.subtract([0, 1])
    end

    if current_location[:y] == 7
      move_indexes.subtract([4, 5, 6, 7])
    elsif current_location[:y] == 6
      move_indexes.subtract([6, 7])
    end

    moves.select.with_index do |location, idx|
      move_indexes.include?(idx) &&
        current_location[:board_x] == location[:board_x] &&
        current_location[:board_y] == location[:board_y]
    end
  end

  def game
    @game ||= self.player.game
  end
end
