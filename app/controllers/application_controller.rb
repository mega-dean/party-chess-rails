class ApplicationController < ActionController::Base
  def current_player
    # CLEANUP tmp
    @current_player ||= Player.find(2)
    # @current_player ||= if session[:player_id]
    #   Player.find(session[:player_id])
    # end
  end

  helper_method :get_translate
  def get_translate(game, target_idx)
    location = game.idx_to_location(target_idx)

    square_rem = 4
    padding_rem = 0.6
    x_rem = (square_rem * location[:x]) + padding_rem
    y_rem = (square_rem * location[:y]) + padding_rem

    "transform: translate(#{x_rem}rem, #{y_rem}rem)"
  end

  helper_method :get_pending_move_line
  def get_pending_move_line(move)
    square_rem = 4
    padding_rem = 0.6

    start_location = move.piece.player.game.idx_to_location(move.piece.square)
    target_location = move.piece.player.game.idx_to_location(move.target_square)

    # TODO this won't work for adjacent-board moves
    start_x = (square_rem * start_location[:x]) + (square_rem / 2) + padding_rem
    start_y = (square_rem * start_location[:y]) + (square_rem / 2) + padding_rem
    target_x = (square_rem * target_location[:x]) + (square_rem / 2) + padding_rem
    target_y = (square_rem * target_location[:y]) + (square_rem / 2) + padding_rem

    length = Math.sqrt(((target_x - start_x) ** 2) + ((target_y - start_y) ** 2))
    angle = Math.atan2(target_y - start_y, target_x - start_x) * (180 / Math::PI)

    <<STR
width: #{length}rem;
transform: rotate(#{angle}deg);
top: #{start_y}rem;
left: #{start_x}rem;
STR
  end
end
