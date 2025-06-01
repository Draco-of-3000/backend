class GameRoomChannel < ApplicationCable::Channel
  def subscribed
    # Find game room by code instead of ID
    @game_room = GameRoom.find_by(code: params[:room_code])
    
    if @game_room && current_user
      stream_from "game_room_#{@game_room.code}" # Stream using the code

      # Add user to players list if not already present (e.g., on reconnect)
      player = @game_room.players.find_or_create_by(user: current_user) do |p|
        # If creating, assign next available position. This might need more robust logic
        # for rejoining vs. initial join, but for subscription it ensures player record exists.
        p.position = (@game_room.players.maximum(:position) || -1) + 1 
        p.hand = [] # Initialize hand if new player record for this room
      end

      # Consider broadcasting a player_reconnected type event if needed
      # For now, just ensuring the player is associated and stream is active.
      # current_game_state might be broadcast by controller on join/create actions.
      # Transmit current state to this subscriber only upon connection could be an option:
      # transmit({ type: 'connection_ack', game_state: UnoGameService.new(@game_room).current_game_state })

    else
      reject # Reject subscription if room not found or no user
    end
  end

  def unsubscribed
    # Any cleanup needed when a user unsubscribes from this specific room
    # e.g., broadcast player disconnected, update game room status if it was in progress, etc.
    if @game_room && current_user
      player = @game_room.players.find_by(user: current_user)
      
      if player
        # Check if the game was in progress
        game_was_in_progress = @game_room.in_progress?

        # Perform player removal and check if room should be destroyed
        # This needs to be atomic to avoid race conditions
        @game_room.with_lock do
          player.destroy # Remove the player from the game

          # If the game was in progress and the player leaving makes it unplayable or is the last player
          if game_was_in_progress
            # Broadcast that the game is ending due to player leaving
            ActionCable.server.broadcast(
              "game_room_#{@game_room.code}",
              {
                type: 'game_aborted',
                reason: "#{current_user.username} left the game.",
                game_room_code: @game_room.code # For client to confirm room
              }
            )
            # Destroy the game room itself
            # Note: Dependent players and game_state will be destroyed due to `dependent: :destroy` in GameRoom model
            @game_room.destroy 
            puts "Game room #{@game_room.code} destroyed because #{current_user.username} left an in-progress game."
          else
            # If game was 'waiting', just broadcast player left
            # If other players remain, they'll see the updated player list via a 'player_left' type message
            # Or, if the room becomes empty and was 'waiting', it could also be destroyed.
            if @game_room.players.reload.empty? && @game_room.waiting?
              puts "Game room #{@game_room.code} was waiting and is now empty. Destroying."
              @game_room.destroy
            else
              # Broadcast player left for 'waiting' rooms if other players are still there
      ActionCable.server.broadcast(
                "game_room_#{@game_room.code}",
        {
                  type: 'player_left_waiting_room',
          user_id: current_user.id,
                  username: current_user.username,
                  player_id: player.id, # player.id is still valid before destroy completes in this block
                  game_room_code: @game_room.code,
                  # We might need to send the updated player list here, or rely on clients re-fetching/UI updates
                  # For now, a simple notification. Client can GET state or App.js can update based on this.
                  players_remaining_count: @game_room.players.count # count after player.destroy within transaction
        }
      )
    end
  end
        end
      end
    end
    stop_all_streams
  end

  # Example custom action, can be removed if not used
  # def speak(data)
  #   ActionCable.server.broadcast "game_room_#{@game_room.code}", message: data['message'], user: current_user.username
  # end
  
  def receive(data)
    # game_room = GameRoom.find_by(id: @game_room_id) # This was problematic
    # Use the @game_room instance variable that's set in `subscribed`
    return unless @game_room && @game_room.players.exists?(user: current_user)
    
    case data['action']
    when 'ping'
      # Keep connection alive
      transmit({ type: 'pong' })
    when 'request_game_state'
      # Send current game state to requesting player
      if @game_room.game_state
        game_service = UnoGameService.new(@game_room)
        transmit({
          type: 'game_state_update',
          game_state: game_service.current_game_state
        })
      end
    end
  end
end
