class Player < ApplicationRecord
  belongs_to :game
  has_many :pieces

  STARTING_POINTS = 12

  class TooManyStartingPointsError < StandardError; end
  class NotEnoughEmptySquaresError < StandardError; end
  class EmptyKindsError < StandardError; end

  STATUSES = [CHOOSING_PARTY, JOINING, PLAYING, DEAD]

  validates :status, inclusion: { in: STATUSES }

  def create_starting_pieces!(kinds:, starting_board_x:, starting_board_y:)
    points = kinds.map { |kind| Piece.cost(kind) }.sum

    if points > STARTING_POINTS
      raise TooManyStartingPointsError
    end

    empty_squares = self.game.empty_squares(starting_board_x, starting_board_y)
    starting_squares = empty_squares.shuffle

    if kinds.length == 0
      raise EmptyKindsError
    elsif kinds.length > empty_squares.length
      raise NotEnoughEmptySquaresError
    end

    kinds.each.with_index do |kind, idx|
      spawn_piece(kind: kind, square: starting_squares[idx])
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
  end

  def broadcast_boards
    broadcast_replace_to("player_#{self.id}_game_board",
      target: 'board-grid',
      partial: "games/board_grid",
      locals: {
        player: self,
      },
    )
  end

  def get_points
    pending_spawn_kinds = self.all_pending_moves.map(&:pending_spawn_kind).compact
    pending_points = pending_spawn_kinds.map { |kind| Piece.cost(kind) }.sum

    {
      bank: self.points - pending_points,
      pending: pending_points,
      on_board: self.pieces.map(&:cost).sum,
    }
  end
end
