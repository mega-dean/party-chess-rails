class GamesController < ApplicationController
  def show
    @game = Game.first
    @pieces = @game.all_pieces
  end
end
