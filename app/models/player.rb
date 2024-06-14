class Player < ApplicationRecord
  belongs_to :game
  # TODO Move should just belong_to Piece
  has_many :moves
  has_many :pieces

  def color
    if is_black
      'black'
    else
      'white'
    end
  end

  def broadcast_target_moves(piece_id)
    broadcast_replace_to "game_board", target: 'board-grid', partial: "games/board_grid", locals: {
      game: self.game,
      pieces: self.game.pieces_by_board,
      current_player: self,
    }
  end
end
