class ApplicationController < ActionController::Base
  helper_method :current_player

  def current_player
    @current_player ||= if session[:player_id]
      # Player.find(session[:player_id])
      Player.find(28)
    end
  end
end
