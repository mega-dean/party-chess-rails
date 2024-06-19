class GamesController < ApplicationController
  def index
    @games = Game.all
  end

  def show
    @player = current_player
  end

  # CLEANUP This is temporary because processing moves won't be triggered by request from frontend
  def process_moves
    game = Game.find(params[:id])
    game.process_current_moves

    head :ok
  end
end
