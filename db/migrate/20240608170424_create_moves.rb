class CreateMoves < ActiveRecord::Migration[7.1]
  def change
    create_table :moves do |t|
      t.integer :target_square, null: false
      t.belongs_to :piece, null: false

      t.timestamps
    end
  end
end
