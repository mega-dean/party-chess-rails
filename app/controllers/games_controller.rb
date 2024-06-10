class GamesController < ApplicationController
  def show
    @game = Game.first
    @pieces = @game.pieces_by_board
  end
end
