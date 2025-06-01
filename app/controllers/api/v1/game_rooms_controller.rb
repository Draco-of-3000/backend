class Api::V1::GameRoomsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_game_room, only: [:show, :join, :start_game, :state, :play_card, :draw_card]
  before_action :set_player, only: [:play_card, :draw_card]
  
  def index
    game_rooms = GameRoom.available.includes(:players, :users)
    render_success({ game_rooms: game_rooms.map { |room| game_room_data(room) } })
  end
  
  def create
    game_room = GameRoom.new
    
    if game_room.save
      # Add creator as first player
      player = game_room.players.create!(
        user: current_user,
        position: 0,
        hand: []
      )
      
      render_success({ game_room: game_room_data(game_room) }, 'Game room created successfully')
    else
      render_error(game_room.errors.full_messages.join(', '))
    end
  end
  
  def show
    render_success({ game_room: game_room_data(@game_room) })
  end
  
  def join
    if @game_room.full?
      return render_error('Game room is full')
    end
    
    if @game_room.in_progress? || @game_room.finished?
      return render_error('Game is already in progress or has finished. Cannot join.')
    end
    
    if @game_room.players.exists?(user: current_user)
      return render_error('You are already in this game room')
    end
    
    next_position = @game_room.players.maximum(:position).to_i + 1
    player = @game_room.players.create!(
      user: current_user,
      position: next_position,
      hand: []
    )
    
    # Broadcast to game room channel
    ActionCable.server.broadcast(
      "game_room_#{@game_room.id}",
      {
        type: 'player_joined',
        player: player_data(player),
        game_room: game_room_data(@game_room)
      }
    )
    
    render_success({ game_room: game_room_data(@game_room) }, 'Joined game room successfully')
  end
  
  def start_game
    unless @game_room.can_start?
      return render_error('Cannot start game. Need 2-4 players and game must be waiting.')
    end
    
    # Check if current user is in the game
    unless @game_room.players.exists?(user: current_user)
      return render_error('You must be in the game to start it')
    end
    
    game_service = UnoGameService.new(@game_room)
    
    if game_service.start_game
      # Broadcast game start to all players
      ActionCable.server.broadcast(
        "game_room_#{@game_room.id}",
        {
          type: 'game_started',
          game_state: game_service.current_game_state
        }
      )
      
      render_success({ game_state: game_service.current_game_state }, 'Game started successfully')
    else
      render_error('Failed to start game')
    end
  end
  
  def state
    if @game_room.game_state
      game_service = UnoGameService.new(@game_room)
      render_success({ game_state: game_service.current_game_state })
    else
      render_success({ game_room: game_room_data(@game_room) })
    end
  end
  
  def play_card
    card_data = params.require(:card).permit(:color, :value, :card_type)
    chosen_color = params[:chosen_color]
    
    game_service = UnoGameService.new(@game_room)
    result = game_service.play_card(@player, card_data, chosen_color)
    
    if result[:success]
      if result[:game_finished]
        ActionCable.server.broadcast(
          "game_room_#{@game_room.id}",
          {
            type: 'game_over',
            game_state: game_service.current_game_state
          }
        )
      else
        ActionCable.server.broadcast(
          "game_room_#{@game_room.id}",
          {
            type: 'card_played',
            player_id: @player.id,
            card: result[:card_played]&.to_hash,
            game_state: game_service.current_game_state
          }
        )
      end
      render_success({ card_played: result[:card_played]&.to_hash, game_finished: result[:game_finished] })
    else
      render_error(result[:error])
    end
  end
  
  def draw_card
    game_service = UnoGameService.new(@game_room)
    result = game_service.draw_card(@player)
    
    if result[:success]
      # Broadcast the draw to all players
      ActionCable.server.broadcast(
        "game_room_#{@game_room.id}",
        {
          type: 'card_drawn',
          player_id: @player.id,
          can_play: result[:can_play],
          game_state: game_service.current_game_state
        }
      )
      
      render_success(result)
    else
      render_error(result[:error])
    end
  end
  
  private
  
  def set_game_room
    @game_room = GameRoom.find_by(id: params[:id])
    render_error('Game room not found', :not_found) unless @game_room
  end
  
  def set_player
    @player = @game_room.players.find_by(user: current_user)
    render_error('You are not in this game', :forbidden) unless @player
  end
  
  def game_room_data(game_room)
    {
      id: game_room.id,
      status: game_room.status,
      direction: game_room.direction,
      current_color: game_room.current_color,
      turn_player_id: game_room.turn_player_id,
      player_count: game_room.players.count,
      players: game_room.players.order(:position).map { |player| player_data(player) },
      can_start: game_room.can_start?,
      is_full: game_room.full?,
      created_at: game_room.created_at
    }
  end
  
  def player_data(player)
    {
      id: player.id,
      user_id: player.user_id,
      username: player.user.username,
      position: player.position,
      hand_size: player.hand_size
    }
  end
end 