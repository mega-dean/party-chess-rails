class AddStatusToPlayers < ActiveRecord::Migration[7.1]
  def change
    # Player lifecycle:
    # - root page -> no current_player
    # - click on a game -> create current_player with status: 'choosing_party'
    # - choose pieces and click join -> status: 'joining'
    # - pieces placed on board -> status: 'playing'
    # - all pieces die -> status: 'dead'
    add_column :players, :status, :string, null: false, default: CHOOSING_PARTY
  end
end
