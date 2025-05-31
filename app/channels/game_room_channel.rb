class GameRoomChannel < ApplicationCable::Channel
  def subscribed
    @game_room_id = params[:room_id]
    game_room = GameRoom.find_by(id: @game_room_id)
    
    if game_room && game_room.players.exists?(user: current_user)
      stream_from "game_room_#{game_room.id}"
      
      # Broadcast that user connected
      ActionCable.server.broadcast(
        "game_room_#{game_room.id}",
        {
          type: 'player_connected',
          user_id: current_user.id,
          username: current_user.username
        }
      )
    else
      reject
    end
  end

  def unsubscribed
    # Broadcast that user disconnected
    if @game_room_id
      ActionCable.server.broadcast(
        "game_room_#{@game_room_id}",
        {
          type: 'player_disconnected',
          user_id: current_user.id,
          username: current_user.username
        }
      )
    end
  end
  
  def receive(data)
    game_room = GameRoom.find_by(id: @game_room_id)
    return unless game_room && game_room.players.exists?(user: current_user)
    
    case data['action']
    when 'ping'
      # Keep connection alive
      transmit({ type: 'pong' })
    when 'request_game_state'
      # Send current game state to requesting player
      if game_room.game_state
        game_service = UnoGameService.new(game_room)
        transmit({
          type: 'game_state_update',
          game_state: game_service.current_game_state
        })
      end
    end
  end
end
