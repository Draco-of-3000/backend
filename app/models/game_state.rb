class GameState < ApplicationRecord
  belongs_to :game_room
  
  # validates :discard_pile, presence: true # Temporarily remove/modify for empty discard start
  # validates :draw_pile, presence: true # This one is fine
  
  serialize :discard_pile, coder: JSON
  serialize :draw_pile, coder: JSON
  
  def top_card
    return nil if discard_pile.empty?
    Card.find_by(discard_pile.last)
  end
  
  def add_to_discard_pile(card)
    card_data = card.to_hash
    self.discard_pile = discard_pile + [card_data]
    save!
  end
  
  def draw_card
    return nil if draw_pile.empty?
    
    card_data = draw_pile.first
    self.draw_pile = draw_pile[1..-1]
    save!
    
    Card.find_by(card_data)
  end
  
  def shuffle_discard_into_draw_pile
    return if discard_pile.size <= 1
    
    # Keep the top card in discard pile
    top_card_data = discard_pile.last
    cards_to_shuffle = discard_pile[0..-2]
    
    self.draw_pile = cards_to_shuffle.shuffle
    self.discard_pile = [top_card_data]
    save!
  end
  
  def initialize_deck
    success = false
    self.class.transaction do
      deck_data = Card.create_deck.shuffle
      
      min_cards_needed = (game_room.players.count * 7) # No extra card for discard pile initially
      if deck_data.length < min_cards_needed
        Rails.logger.error "Not enough cards generated to start game. Needed: #{min_cards_needed}, Got: #{deck_data.length}"
        raise ActiveRecord::Rollback, "Not enough cards to start game"
      end

      game_room.players.each do |player|
        player_cards = deck_data.shift(7)
        player.update!(hand: player_cards)
      end
      
      # No first card drawn to discard_pile
      self.discard_pile = [] 
      self.draw_pile = deck_data
      save!
      success = true
    end
    success
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "GameState Initialize Deck Error (RecordInvalid): #{e.message} - #{e.record.errors.full_messages.join(', ')}"
    false
  rescue ActiveRecord::Rollback => e
    Rails.logger.error "GameState Initialize Deck Error (Rollback): #{e.message}"
    false
  end
  
  def cards_remaining_in_draw_pile
    draw_pile.size
  end
  
  def ensure_draw_pile_has_cards
    if draw_pile.empty? && discard_pile.size > 1
      shuffle_discard_into_draw_pile
    end
  end
end
