class MovesController < ApplicationController
  def create
    piece = Piece.find(params[:piece_id])
    piece.make_move(params.slice(:target_board_x, :target_board_y, :target_x, :target_y))
    head :ok
  end
end
