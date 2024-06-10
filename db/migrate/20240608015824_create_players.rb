class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.boolean :is_black, null: false
      t.belongs_to :game

      t.timestamps
    end
  end
end
