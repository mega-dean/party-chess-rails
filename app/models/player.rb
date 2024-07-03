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

  def pending_moves_by_board
    board_hash = self.game.board_hash(:array)

    self.all_pending_moves.each do |move|
      location = self.game.square_to_location(move.piece.square)
      board_hash[[location[:board_x], location[:board_y]]] << move
    end

    board_hash
  end

  def all_pending_moves
    Move.includes(:piece).where(piece_id: self.pieces.select(:id), turn: self.game.current_turn)
  end

  def spawn_piece(square:, kind:)
    self.update!(
      points: self.points - Piece.cost(kind),
      score: self.score + Piece.points(kind),
    )
    self.pieces.create!(kind: kind, square: square)
    self.game.broadcast_boards(self)
  end

  def get_points
    pending_spawn_kinds = self.all_pending_moves.map(&:pending_spawn_kind).compact
    pending_points = pending_spawn_kinds.map { |kind| Piece.cost(kind) }.sum

    {
      bank: self.points - pending_points,
      pending: pending_points,
      on_board: self.pieces.map(&:points).sum,
    }
  end
end
