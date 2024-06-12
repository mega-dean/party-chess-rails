class Piece < ApplicationRecord
  belongs_to :player

  KINDS = ['rook', 'queen', 'knight', 'bishop']

  validates :kind, inclusion: {
    in: KINDS
  }

  after_update_commit -> {
    broadcast_replace_to "pieces"
  }
end
