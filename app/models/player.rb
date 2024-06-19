class Player < ApplicationRecord
  belongs_to :game
  has_many :pieces

  def color
    if is_black
      'black'
    else
      'white'
    end
  end

  def pending_moves
    board_hash = self.game.board_hash

    Move.where(piece_id: self.pieces.select(:id), turn: self.game.current_turn).each do |move|
      location = self.game.idx_to_location(move.target_square)
      board_hash[[location[:board_x], location[:board_y]]] << move
    end

    board_hash
  end
end
