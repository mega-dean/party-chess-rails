class MovesController < ApplicationController
  def create
    piece = Piece.find(params[:piece_id])
    piece.try_move(params[:target_idx])
    head :ok
  end
end
