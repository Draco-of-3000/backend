class UnoGameService
  attr_reader :game_room, :game_state
  
  def initialize(game_room)
    @game_room = game_room
    @game_state = game_room.game_state
  end
  
  def start_game
    return false unless game_room.can_start?
    
    # Build game state if it doesn't exist, or use existing one
    # GameState#initialize_deck will handle saving itself.
    @game_state = game_room.game_state || game_room.build_game_state
    
    # initialize_deck now populates piles and saves the game_state record.
    # It should return true on success or raise an error on failure.
    # For simplicity, we assume it succeeds or raises.
    unless @game_state.initialize_deck
      Rails.logger.error "Failed to initialize deck for game room: #{game_room.id} in UnoGameService."
      # Errors should be logged within initialize_deck itself too.
      return false 
    end
    
    # Reload to ensure we have the persisted state, especially if it was just built and saved in initialize_deck
    @game_state.reload

    # Set first player
    first_player = game_room.players.order(:position).first
    game_room.update!(
      status: 'in_progress',
      turn_player: first_player,
      current_color: game_state.top_card&.color
    )
    
    # Handle special first card
    handle_first_card_special_effects
    
    true
  rescue ActiveRecord::RecordInvalid => e
    # Log the error if GameState#initialize_deck or game_room.update! fails validation
    Rails.logger.error "UnoGameService Start Game Error (after deck init): #{e.message} - #{e.record.errors.full_messages.join(', ')}"
    false
  end
  
  def play_card(player, card_data, chosen_color = nil)
    return { success: false, error: "Not your turn" } unless player == game_room.turn_player
    return { success: false, error: "Game not in progress" } unless game_room.in_progress?
    
    card = Card.find_by(card_data)
    return { success: false, error: "Card not found" } unless card
    return { success: false, error: "Card not in hand" } unless player_has_card?(player, card)
    return { success: false, error: "Invalid play" } unless valid_play?(card)
    
    # Remove card from player's hand
    player.remove_card(card)
    
    # Add card to discard pile
    game_state.add_to_discard_pile(card)
    
    # Handle wild card color choice
    if card.wild? && chosen_color
      game_room.update!(current_color: chosen_color)
    else
      game_room.update!(current_color: card.color)
    end
    
    # Check for win condition
    if player.has_won?
      game_room.update!(status: 'finished')
      return { success: true, winner: player, game_finished: true }
    end
    
    # Apply special card effects
    apply_special_card_effects(card, player)
    
    { success: true, card_played: card }
  end
  
  def draw_card(player)
    return { success: false, error: "Not your turn" } unless player == game_room.turn_player
    return { success: false, error: "Game not in progress" } unless game_room.in_progress?
    
    game_state.ensure_draw_pile_has_cards
    drawn_card = game_state.draw_card
    
    return { success: false, error: "No cards to draw" } unless drawn_card
    
    player.add_card(drawn_card)
    
    # Player can play the drawn card if it's valid
    if valid_play?(drawn_card)
      { success: true, card_drawn: drawn_card, can_play: true }
    else
      advance_turn
      { success: true, card_drawn: drawn_card, can_play: false }
    end
  end
  
  def valid_play?(card)
    top_card = game_state.top_card
    return false unless top_card
    
    card.can_play_on?(top_card, game_room.current_color)
  end
  
  def current_game_state
    {
      game_room: {
        id: game_room.id,
        status: game_room.status,
        direction: game_room.direction,
        current_color: game_room.current_color,
        turn_player_id: game_room.turn_player_id
      },
      players: game_room.players.order(:position).map do |player|
        {
          id: player.id,
          user_id: player.user_id,
          username: player.user.username,
          position: player.position,
          hand_size: player.hand_size,
          hand: player.hand
        }
      end,
      top_card: game_state.top_card&.to_hash,
      draw_pile_size: game_state.cards_remaining_in_draw_pile
    }
  end
  
  private
  
  def player_has_card?(player, card)
    player.hand.any? do |hand_card|
      hand_card['color'] == card.color &&
      hand_card['value'] == card.value &&
      hand_card['card_type'] == card.card_type
    end
  end
  
  def handle_first_card_special_effects
    top_card = game_state.top_card
    return unless top_card&.special?
    
    case top_card.card_type
    when 'skip'
      advance_turn
    when 'reverse'
      reverse_direction
      advance_turn if game_room.players.count == 2
    when 'draw_two'
      force_draw_cards(game_room.turn_player, 2)
      advance_turn
    when 'wild', 'wild_draw_four'
      # Set a random color for wild cards at start
      game_room.update!(current_color: %w[red blue green yellow].sample)
      if top_card.card_type == 'wild_draw_four'
        force_draw_cards(game_room.turn_player, 4)
        advance_turn
      end
    end
  end
  
  def apply_special_card_effects(card, current_player)
    case card.card_type
    when 'skip'
      advance_turn # Skip next player
      advance_turn # Move to player after skipped player
    when 'reverse'
      reverse_direction
      if game_room.players.count == 2
        # In 2-player game, reverse acts like skip
        advance_turn
      else
        advance_turn
      end
    when 'draw_two'
      next_player = game_room.next_player(current_player)
      force_draw_cards(next_player, 2)
      advance_turn # Skip the player who drew cards
      advance_turn # Move to next player
    when 'wild_draw_four'
      next_player = game_room.next_player(current_player)
      force_draw_cards(next_player, 4)
      advance_turn # Skip the player who drew cards
      advance_turn # Move to next player
    else
      advance_turn
    end
  end
  
  def advance_turn
    next_player = game_room.next_player(game_room.turn_player)
    game_room.update!(turn_player: next_player)
  end
  
  def reverse_direction
    new_direction = game_room.direction == 'clockwise' ? 'counter_clockwise' : 'clockwise'
    game_room.update!(direction: new_direction)
  end
  
  def force_draw_cards(player, count)
    count.times do
      game_state.ensure_draw_pile_has_cards
      drawn_card = game_state.draw_card
      break unless drawn_card
      player.add_card(drawn_card)
    end
  end
end 