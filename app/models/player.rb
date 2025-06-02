class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game_room
  
  validates :position, presence: true, uniqueness: { scope: :game_room_id }
  validates :user_id, uniqueness: { scope: :game_room_id, message: "is already in this game room" }
  
  serialize :hand, coder: JSON
  
  def hand_cards
    hand.map { |card_data| Card.find_by(card_data) }
  end
  
  def add_card(card)
    # Ensure string keys when adding to hand for consistency with JSON serialization
    card_data = { 
      "color" => card.color, 
      "value" => card.value, 
      "card_type" => card.card_type 
    }
    self.hand = (self.hand || []) + [card_data] # Initialize hand if nil
    save!
  end
  
  def remove_card(card)
    # Construct card_data with string keys to match the structure in self.hand (due to JSON serialization)
    card_to_remove_attrs = {
      "color" => card.color,
      "value" => card.value,
      "card_type" => card.card_type
    }
    
    current_hand = self.hand || [] # Ensure hand is an array
    index_to_remove = current_hand.index(card_to_remove_attrs)
    
    if index_to_remove
      new_hand = current_hand.dup
      new_hand.delete_at(index_to_remove)
      self.hand = new_hand
      save!
      return true
    else
      Rails.logger.warn "Player #{self.id}: Card to remove #{card_to_remove_attrs.inspect} not found in hand #{current_hand.inspect}"
      return false
    end
  end
  
  def has_won?
    hand.empty?
  end
  
  def hand_size
    hand.size
  end
end
