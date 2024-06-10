class Piece < ApplicationRecord
  belongs_to :player

  validates :kind, inclusion: {
    in: ['rook', 'queen', 'knight', 'bishop']
  }
end
