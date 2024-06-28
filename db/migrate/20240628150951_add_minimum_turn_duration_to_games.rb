class AddMinimumTurnDurationToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :minimum_turn_duration, :integer, null: false, default: 10
  end
end
