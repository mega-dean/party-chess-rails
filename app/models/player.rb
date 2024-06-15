class Player < ApplicationRecord
  belongs_to :game
  has_many :pieces

  def color
    if is_black
      'black'
    else
      'white'
    end
  end
end
