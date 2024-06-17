class AddTurnToMoves < ActiveRecord::Migration[7.1]
  def change
    add_column :moves, :turn, :integer, null: false
  end
end
