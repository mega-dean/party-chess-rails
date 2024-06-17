class AddCurrentTurnToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :current_turn, :integer, null: false, default: 0
  end
end
