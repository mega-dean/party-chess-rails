class Player < ApplicationRecord
  belongs_to :game
  # FIXME Move should just belong_to Piece
  has_many :moves
  has_many :pieces

  def color
    if is_black
      'black'
    else
      'white'
    end
  end
end
