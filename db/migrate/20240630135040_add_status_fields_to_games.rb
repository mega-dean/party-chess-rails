class AddStatusFieldsToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :processing_moves, :boolean, null: false, default: false
    add_column :games, :last_turn_completed_at, :datetime, null: false
  end
end
