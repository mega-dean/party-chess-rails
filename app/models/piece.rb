class Piece < ApplicationRecord
  belongs_to :player

  validates :kind, inclusion: {
    in: ['rook', 'queen', 'knight', 'bishop']
  }

  after_update_commit -> {
    broadcast_replace_to "pieces"
  }
end
