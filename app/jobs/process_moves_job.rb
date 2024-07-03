class ProcessMovesJob < ApplicationJob
  queue_as :default

  def perform(game_id, turn)
    game = Game.find(game_id)
    # Check the current_turn to handle jobs retrying. From the sidekiq wiki:
    #   Just remember that Sidekiq will execute your job at least once, not exactly once. Even a job which has completed
    #   can be re-run. Redis can go down between the point where your job finished but before Sidekiq has acknowledged
    #   it in Redis. Sidekiq makes no exactly-once guarantee at all.

    # The !processing_moves check should handle duplicate jobs started at the same time. The current_turn check should
    # handle jobs that retry because of a failure.
    if !game.processing_moves && game.current_turn == turn
      game.process_current_moves

      ProcessMovesJob.set(wait: game.minimum_turn_duration.seconds).perform_later(game.id, game.current_turn)
    end
  end
end
