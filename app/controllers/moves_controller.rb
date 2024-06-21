class MovesController < ApplicationController
  def create
    piece = Piece.find(params[:piece_id])
    target_location = {
      board_x: params[:target_board_x],
      board_y: params[:target_board_y],
      x: params[:target_x],
      y: params[:target_y],
    }
    piece.make_move(target_location)
    head :ok
  end
end
