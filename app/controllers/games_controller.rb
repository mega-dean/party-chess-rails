class GamesController < ApplicationController
  def index
    @games = Game.all
  end

  def show
    if current_player.nil?
      redirect_to :root
    else
      @player = current_player
    end
  end

  # TMP Processing moves won't be triggered by request from frontend.
  def process_moves
    game = Game.find(params[:id])
    ProcessMovesJob.perform_later(game.id, game.current_turn)

    head :ok
  end

  # TODO Maybe don't call this "refresh" since it doesn't refresh the browser page.
  def refresh
    game = Game.find(params[:id])
    player = Player.find(params[:player_id])

    game.broadcast_refresh(player)

    head :ok
  end
end
