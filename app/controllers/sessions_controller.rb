class SessionsController < ApplicationController
  def create
    # TMP Need to create a Player.
    game = Game.find(params[:game_id])
    join_game(player, game)
  end

  def destroy
    quit_game
    redirect_to(root_path)
  end

  private

  def join_game(player, game)
    session[:player_id] = player.id
    @current_player = player
    redirect_to(game_path(game))
  end

  def quit_game
    session.delete(:player_id)
    @current_player = nil
  end
end
