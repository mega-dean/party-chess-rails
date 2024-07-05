class PiecesController < ApplicationController
  def deselect
    piece = Piece.find(params[:id])
    piece.deselect

    head :ok
  end
end
