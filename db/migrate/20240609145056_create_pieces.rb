class CreatePieces < ActiveRecord::Migration[7.1]
  def change
    create_table :pieces do |t|
      t.references :player, null: false
      t.string :kind, null: false
      t.integer :square, null: false

      t.timestamps
    end
  end
end
