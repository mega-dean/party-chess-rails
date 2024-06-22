class MovesController < ApplicationController
  def create
    piece = Piece.find(params[:piece_id])
    piece.try_move(params[:target_square])
    head :ok
  end
end
