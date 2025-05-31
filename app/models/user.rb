class User < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :game_rooms, through: :players
  
  validates :username, presence: true, uniqueness: true, length: { maximum: 50 }
end
