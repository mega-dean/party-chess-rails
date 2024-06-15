class ApplicationController < ActionController::Base
  def current_player
    # CLEANUP tmp
    @current_player ||= Player.find(2)
    # @current_player ||= if session[:player_id]
    #   Player.find(session[:player_id])
    # end
  end

  helper_method :get_translate
  def get_translate(location)
    square_rem = 4
    padding_rem = 0.6
    x_rem = (square_rem * location[:x]) + padding_rem
    y_rem = (square_rem * location[:y]) + padding_rem

    "transform: translate(#{x_rem}rem, #{y_rem}rem)"
  end
end
