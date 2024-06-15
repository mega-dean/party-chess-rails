class GamesController < ApplicationController
  def index
    @games = Game.all
  end

  def show
    @player = current_player
  end
end
