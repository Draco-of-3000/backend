class UnoGameService
  attr_reader :game_room, :game_state
  
  def initialize(game_room)
    @game_room = game_room
    @game_state = game_room.game_state
  end
  
  def start_game
    return false unless game_room.can_start?
    
    @game_state = game_room.game_state || game_room.build_game_state
    
    # Initialize deck (deals cards to players, sets up draw_pile, discard_pile starts empty)
    unless @game_state.initialize_deck 
      Rails.logger.error "Failed to initialize deck for game room: #{game_room.id} in UnoGameService."
      return false 
    end
    @game_state.reload # Ensure we have the persisted state

    # Randomly select first player
    first_player = game_room.players.sample 
    return false unless first_player

    game_room.update!(
      status: 'in_progress',
      turn_player: first_player,
      current_color: nil # No starting card, so no initial color
    )
    
    # No handle_first_card_special_effects call, as discard pile is empty.
    
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "UnoGameService Start Game Error: #{e.message} - #{e.record.errors.full_messages.join(', ')}"
    false
  end
  
  def play_card(player, card_data, chosen_color = nil)
    return { success: false, error: "Not your turn" } unless player == game_room.turn_player
    return { success: false, error: "Game not in progress" } unless game_room.in_progress?
    
    card_to_play = Card.find_by(card_data)
    return { success: false, error: "Card not found" } unless card_to_play
    return { success: false, error: "Card not in hand" } unless player_has_card?(player, card_to_play)
    
    is_first_play = game_state.discard_pile.empty?

    unless is_first_play || valid_play?(card_to_play)
      return { success: false, error: "Invalid play" }
    end
    
    player.remove_card(card_to_play)
    game_state.add_to_discard_pile(card_to_play)
    
    new_current_color = card_to_play.color
    if card_to_play.wild?
      return { success: false, error: "Must choose a color for Wild card" } unless chosen_color
      new_current_color = chosen_color
    end
    game_room.update!(current_color: new_current_color)
    
    if player.has_won?
      game_room.update!(status: 'finished', winner_player_id: player.id)
      
      # Record win/loss stats
      winner_user = player.user
      winner_user.increment!(:wins)
      
      game_room.players.where.not(id: player.id).each do |losing_player|
        losing_player.user.increment!(:losses)
      end
      
      return { success: true, game_finished: true } # Winner info will be in game_state now
    end
    
    apply_special_card_effects(card_to_play, player)
    
    { success: true, card_played: card_to_play }
  end
  
  def draw_card(player)
    return { success: false, error: "Not your turn" } unless player == game_room.turn_player
    return { success: false, error: "Game not in progress" } unless game_room.in_progress?

    # Check if player has any playable card in hand
    if player.hand_cards.any? { |card_in_hand| valid_play?(card_in_hand) }
      return { success: false, error: "You have a playable card. You cannot draw." }
    end
    
    game_state.ensure_draw_pile_has_cards
    drawn_card = game_state.draw_card
    
    return { success: false, error: "No cards to draw" } unless drawn_card
    
    player.add_card(drawn_card)
    
    # Player can play the drawn card if it's valid.
    # The turn does NOT automatically advance here. It only advances when a card is played.
    if valid_play?(drawn_card)
      { success: true, card_drawn: drawn_card, can_play: true }
    else
      # advance_turn # REMOVED: Turn does not advance if drawn card is not playable.
      { success: true, card_drawn: drawn_card, can_play: false }
    end
  end
  
  def valid_play?(card)
    # If discard pile is empty, any card is a valid first play.
    return true if game_state.discard_pile.empty? 

    top_card = game_state.top_card
    return false unless top_card # Should not be nil if not empty discard pile
    
    card.can_play_on?(top_card, game_room.current_color)
  end
  
  def current_game_state
    winner_data = nil
    if game_room.finished? && game_room.winner_player
      winner_data = player_data_for_game_state(game_room.winner_player)
    end

    {
      game_room: {
        id: game_room.id,
        status: game_room.status,
        direction: game_room.direction,
        current_color: game_room.current_color,
        turn_player_id: game_room.turn_player_id
      },
      players: game_room.players.order(:position).map do |player|
        player_data_for_game_state(player).merge(hand: player.hand) # Ensure hand is included for current player
      end,
      top_card: @game_state&.top_card&.to_hash, # Use @game_state here
      draw_pile_size: @game_state&.cards_remaining_in_draw_pile, # Use @game_state here
      winner: winner_data
    }
  end
  
  private
  
  def player_data_for_game_state(player)
    {
      id: player.id,
      user_id: player.user.id, # Ensure we get user_id from user object
      username: player.user.username,
      position: player.position,
      hand_size: player.hand_size
      # Note: hand is added separately for the full player list if needed by current player
    }
  end
  
  def player_has_card?(player, card)
    player.hand.any? do |hand_card|
      hand_card['color'] == card.color &&
      hand_card['value'] == card.value &&
      hand_card['card_type'] == card.card_type
    end
  end
  
  # handle_first_card_special_effects is no longer needed and can be removed or left commented out
  # def handle_first_card_special_effects(starting_player)
  # ... 
  # end
  
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