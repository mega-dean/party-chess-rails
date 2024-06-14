class SessionsController < ApplicationController
  def create
    # CLEANUP error handling
    game = Game.find(params[:game_id])

    # CLEANUP tmp
    player = game.players.create!(is_black: [true, false].sample)
    pieces = game.pieces_by_board[[0, 0]]
    occupied_squares = Set.new(pieces.map(&:square))
    square = (0..64).find { |idx| !occupied_squares.include?(idx) }
    player.pieces.create!(kind: Piece::KINDS.sample, square: square)

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
