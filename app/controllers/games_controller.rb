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

  # CLEANUP maybe don't call this "refresh" since this doesn't actually refresh the browser page
  def refresh
    game = Game.find(params[:id])
    player = Player.find(params[:player_id])

    game.broadcast_refresh(player)
  end
end
