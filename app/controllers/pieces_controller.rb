class PiecesController < ApplicationController
  include Turbo::Broadcastable

  def set_as_selected
    piece = Piece.find(params[:id])
    piece.set_as_selected

    respond_to do |format|
      format.json { head :ok }
    end
  end

  def deselect
    Piece.deselect(current_player)

    respond_to do |format|
      format.json { head :ok }
    end
  end

end
