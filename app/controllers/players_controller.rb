class PlayersController < ApplicationController
  include Turbo::Broadcastable

  def select_piece
    @game = current_player.game
    @pieces = @game.pieces_by_board

    # CLEANUP tmp
    piece = Piece.find(params[:piece_id])
    piece.update!(square: piece.square + 1)

    current_player.broadcast_target_moves(params[:piece_id])

    respond_to do |format|
      format.json { head :ok }
    end
  end
end
