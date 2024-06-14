class Piece < ApplicationRecord
  belongs_to :player

  KINDS = ['rook', 'queen', 'knight', 'bishop']

  validates :kind, inclusion: {
    in: KINDS
  }
end
