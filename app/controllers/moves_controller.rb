class MovesController < ApplicationController
  def create
    piece = Piece.find(params[:piece_id])
    target_square = piece.player.game.location_to_square(params.slice(:board_x, :board_y, :x, :y))

    piece.try_move(
      target_square: target_square,
      direction: params[:direction],
      spawn_kind: params[:spawn_kind],
    )

    head :ok
  end
end
