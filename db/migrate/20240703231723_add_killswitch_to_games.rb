class AddKillswitchToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :stop_processing_moves_at, :integer
  end
end
