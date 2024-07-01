class AddPointsToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :points, :integer, null: false, default: 0
    add_column :players, :score, :integer, null: false, default: 0
  end
end
