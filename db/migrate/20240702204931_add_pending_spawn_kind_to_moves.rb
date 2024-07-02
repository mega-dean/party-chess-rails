class AddPendingSpawnKindToMoves < ActiveRecord::Migration[7.1]
  def change
    add_column :moves, :pending_spawn_kind, :string
  end
end
