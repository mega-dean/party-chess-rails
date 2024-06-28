class ProcessMovesJob < ApplicationJob
  queue_as :default

  def perform(game_id, turn)
    game = Game.find(game_id)
    # Check the current_turn to handle jobs retrying. From the sidekiq wiki:
    #   Just remember that Sidekiq will execute your job at least once, not exactly once. Even a job which has completed
    #   can be re-run. Redis can go down between the point where your job finished but before Sidekiq has acknowledged
    #   it in Redis. Sidekiq makes no exactly-once guarantee at all.
    if game.current_turn == turn
      game.process_current_moves
    end

    ProcessMovesJob.set(wait: game.minimum_turn_duration.seconds).perform_later(game.id, game.current_turn)
  end
end
