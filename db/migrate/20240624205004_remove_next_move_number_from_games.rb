class RemoveNextMoveNumberFromGames < ActiveRecord::Migration[7.1]
  def change
    remove_column :games, :next_move_number, :integer
  end
end
