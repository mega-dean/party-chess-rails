class GamesController < ApplicationController
  def index
    @games = Game.all
  end

  def show
    @game = Game.first
    @pieces = @game.pieces_by_board
  end
end
