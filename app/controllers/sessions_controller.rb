class SessionsController < ApplicationController
  def create
    game = Game.find(params[:game_id])

    player = game.create_player
    start_session(player)

    redirect_to(choose_party_path(game))
  end

  def destroy
    quit_game

    redirect_to(root_path)
  end

  private

  def start_session(player)
    session[:player_id] = player.id
    # CLEANUP this might not be needed because the definition on ApplicationController should look it up
    # from session[:player_id]
    @current_player = player
  end

  def quit_game
    session.delete(:player_id)
    @current_player = nil
  end
end
