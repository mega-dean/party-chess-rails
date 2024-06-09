class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.integer :boards_tall, null: false
      t.integer :boards_wide, null: false
      t.integer :next_move_number, null: false, default: 1

      t.timestamps
    end
  end
end
