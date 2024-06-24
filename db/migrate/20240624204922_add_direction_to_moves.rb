class AddDirectionToMoves < ActiveRecord::Migration[7.1]
  def change
    add_column :moves, :direction, :string, null: false
  end
end
