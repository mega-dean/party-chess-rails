class GamesController < ApplicationController
  def index
    @games = Game.all
  end

  def show
    if current_player.nil?
      redirect_to :root
    else
      @player = current_player
      if @player.game.id != params[:id].to_i
        redirect_to(game_path(@player.game.id))
      end
    end
  end

  def choose_party
    @player = current_player
    if @player.pieces.any?
      redirect_to(game_path(params[:id]))
    end
  end

  def join
    @player = current_player
    kinds = params[:chosen_kinds].split(',')
    starting_board_x, starting_board_y =
      @player.game.choose_starting_board(player: @player, count: kinds.length)

    begin
      @player.create_starting_pieces!(
        kinds: kinds,
        starting_board_x: starting_board_x,
        starting_board_y: starting_board_y,
      )
    rescue => e
      flash[:error] = "Something went wrong - please try again."
      return redirect_to(choose_party_path(params[:id]))
    end

    redirect_to(game_path(params[:id]))
  end

  # TODO Maybe don't call this "refresh" since it doesn't refresh the browser page.
  def refresh
    game = Game.find(params[:id])
    player = game.players.find(params[:player_id])

    game.broadcast_refresh(player)

    head :ok
  end

  if Rails.env.development?
    def process_moves
      game = Game.find(params[:id])
      ProcessMovesJob.perform_later(game.id, game.current_turn)

      head :ok
    end

    def stop_processing_moves
      game = Game.find(params[:id])
      game.update!(stop_processing_moves_at: game.current_turn + 1)

      head :ok
    end
  end
end
