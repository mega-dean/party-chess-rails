class Piece < ApplicationRecord
  belongs_to :player

  KINDS = ['rook', 'queen', 'knight', 'bishop']

  validates :kind, inclusion: {
    in: KINDS
  }

  # Not calling this `.select` because that method already exists on Models.
  def set_as_selected
    game = self.player.game

    # TODO Get moves based on piece.kind.
    target_moves = [
      game.from_square_idx(self.square + 1),
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
