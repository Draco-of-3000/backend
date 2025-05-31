class GameState < ApplicationRecord
  belongs_to :game_room
  
  validates :discard_pile, presence: true
  validates :draw_pile, presence: true
  
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
    self.class.transaction do # Use self.class.transaction for model methods
      deck_data = Card.create_deck.shuffle
      
      # Ensure there are enough cards for dealing and initial discard
      min_cards_needed = (game_room.players.count * 7) + 1
      if deck_data.length < min_cards_needed
        Rails.logger.error "Not enough cards generated to start game. Needed: #{min_cards_needed}, Got: #{deck_data.length}"
        # This should ideally not happen if Card.create_deck is correct
        raise ActiveRecord::Rollback, "Not enough cards to start game"
      end

      game_room.players.each do |player|
        player_cards = deck_data.shift(7)
        player.update!(hand: player_cards) # If this fails, transaction rolls back
      end
      
      first_card = deck_data.shift
      # This check is now less critical due to the one above, but good for safety.
      raise ActiveRecord::Rollback, "Internal error: Not enough cards for discard pile after dealing" if first_card.nil?

      self.discard_pile = [first_card]
      self.draw_pile = deck_data
      save! # If this fails (e.g., presence validation if piles somehow ended up empty), transaction rolls back
      success = true
    end
    success # Return true if transaction completed
  rescue ActiveRecord::RecordInvalid => e # Catch validation errors from self.save! or player.update!
    Rails.logger.error "GameState Initialize Deck Error (RecordInvalid): #{e.message} - #{e.record.errors.full_messages.join(', ')}"
    false # Explicitly return false on error
  rescue ActiveRecord::Rollback => e # Catch explicit rollback
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
