class CreateMoves < ActiveRecord::Migration[7.1]
  def change
    create_table :moves do |t|
      t.integer :number, null: false
      t.integer :to_square, null: false
      t.integer :from_square, null: false
      t.belongs_to :player

      t.timestamps
    end
  end
end
