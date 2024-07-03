class PiecesController < ApplicationController
  def set_as_selected
    piece = Piece.find(params[:id])
    piece.set_as_selected

    head :ok
  end

  def deselect
    piece = Piece.find(params[:id])
    piece.deselect

    head :ok
  end
end
