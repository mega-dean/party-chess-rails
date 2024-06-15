class Piece < ApplicationRecord
  belongs_to :player
  has_many :moves

  KINDS = ['rook', 'queen', 'knight', 'bishop']

  validates :kind, inclusion: {
    in: KINDS
  }

  def make_move(location)
    target_square = self.player.game.location_to_idx({
      board_x: location[:target_board_x],
      board_y: location[:target_board_y],
      x: location[:target_x],
      y: location[:target_y],
    })

    # CLEANUP use one of the first_or_ methods
    move = if self.moves.first
      self.moves.first.update!(target_square: target_square)
    else
      self.moves.create!(target_square: target_square)
    end

    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: self.player,
    }
  end

  # Not calling this `.select` because that method already exists on Models.
  def set_as_selected
    game = self.player.game

    location = game.idx_to_location(self.square)

    # TODO Get moves based on piece.kind.
    target_moves = game.board_hash
    target_moves[[location[:board_x], location[:board_y]]] = [
      game.idx_to_location(self.square - 9),
      game.idx_to_location(self.square - 8),
      game.idx_to_location(self.square - 7),
      game.idx_to_location(self.square - 1),
      game.idx_to_location(self.square + 1),
      game.idx_to_location(self.square + 7),
      game.idx_to_location(self.square + 8),
      game.idx_to_location(self.square + 9),
    ]

    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: self.player,
      target_moves: target_moves,
      selected_piece: self,
    }
  end

  def self.deselect(player)
    new.broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      player: player,
    }
  end
end
