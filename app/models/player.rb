class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game_room
  
  validates :position, presence: true, uniqueness: { scope: :game_room_id }
  validate :unique_user_per_game_room
  
  serialize :hand, coder: JSON
  
  def hand_cards
    hand.map { |card_data| Card.find_by(card_data) }
  end
  
  def add_card(card)
    card_data = { color: card.color, value: card.value, card_type: card.card_type }
    self.hand = hand + [card_data]
    save!
  end
  
  def remove_card(card)
    card_data = { color: card.color, value: card.value, card_type: card.card_type }
    self.hand = hand - [card_data]
    save!
  end
  
  def has_won?
    hand.empty?
  end
  
  def hand_size
    hand.size
  end
  
  private
  
  def unique_user_per_game_room
    if Player.where(user: user, game_room: game_room).where.not(id: id).exists?
      errors.add(:user, "is already in this game room")
    end
  end
end
