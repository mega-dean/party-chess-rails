class MovesController < ApplicationController
  def create
    piece = Piece.find(params[:piece_id])
    piece.try_move(
      target_square: params[:target_square],
      direction: params[:direction],
      spawn_kind: params[:spawn_kind],
    )

    head :ok
  end
end
