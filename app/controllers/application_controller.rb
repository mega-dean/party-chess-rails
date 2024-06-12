class ApplicationController < ActionController::Base
  helper_method :current_player

  def current_player
    if session[:player_id]
      @current_player = Player.find(session[:player_id])
    end
  end
end
