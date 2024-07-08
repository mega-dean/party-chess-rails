class Player < ApplicationRecord
  STARTING_POINTS = 12

  class TooManyStartingPointsError < StandardError; end

  belongs_to :game
  has_many :pieces

  def create_starting_pieces!(kinds:, starting_board_x:, starting_board_y:)
    points = kinds.map { |kind| Piece.cost(kind) }.sum

    if points > STARTING_POINTS
      raise TooManyStartingPointsError
    end

    # CLEANUP duplicated in choose_starting_board
    pieces = self.game.pieces_by_board[[starting_board_x, starting_board_y]]
    first_square = self.game.location_to_square({ board_x: starting_board_x, board_y: starting_board_y, x: 0, y: 0 })
    empty_squares = (first_square..first_square+63).to_a - pieces.map(&:square)
    starting_squares = empty_squares.shuffle

    kinds.each.with_index do |kind, idx|
      self.pieces.create!(kind: kind, square: starting_squares[idx])
    end
  end

  def color
    if is_black then BLACK else WHITE end
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
