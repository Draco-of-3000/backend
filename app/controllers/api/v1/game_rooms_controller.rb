class Api::V1::GameRoomsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_game_room, only: [:show, :join, :start_game, :state, :play_card, :draw_card]
  before_action :set_player, only: [:play_card, :draw_card]
  
  def index
    game_rooms = GameRoom.available.includes(:players, :users)
    render_success({ game_rooms: game_rooms.map { |room| game_room_data(room) } })
  end
  
  def create
    game_room = GameRoom.new(
      status: 'waiting',      # Default status
      direction: 'clockwise'  # Default direction
    )
    
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
    
    # Use transaction to ensure atomicity
    Player.transaction do
      # In production with Supabase, bypass Rails 8.0 insert_all optimization completely
      # by using raw SQL to avoid unique index detection issues
      if Rails.env.production?
        Rails.logger.info "Using raw SQL insert for Player creation to avoid Rails 8.0 + Supabase issues"
        # Use raw SQL insert to bypass Rails 8.0 insert_all optimization
        # Using parameterized query to prevent SQL injection
        result = ActiveRecord::Base.connection.exec_query(
          "INSERT INTO players (user_id, game_room_id, position, hand, created_at, updated_at) " \
          "VALUES ($1, $2, $3, $4, NOW(), NOW()) RETURNING id",
          "Player Insert",
          [current_user.id, @game_room.id, next_position, '[]']
        )
        
        player_id = result.first['id']
        player = Player.find(player_id)
        Rails.logger.info "Successfully created player #{player_id} using raw SQL"
      else
        Rails.logger.debug "Using standard Rails approach for Player creation in #{Rails.env}"
        # Use normal Rails approach in development/test
        player = Player.new(
          user: current_user,
          game_room: @game_room,
          position: next_position,
          hand: []
        )
        player.save!
      end
      
      # Broadcast to game room channel
      Rails.logger.info "About to broadcast player_joined event"
      begin
        player_data_result = player_data(player)
        Rails.logger.info "Successfully generated player_data"
      rescue => e
        Rails.logger.error "Error in player_data: #{e.class} - #{e.message}"
        raise e
      end
      
      begin
        game_room_data_result = game_room_data(@game_room)
        Rails.logger.info "Successfully generated game_room_data"
      rescue => e
        Rails.logger.error "Error in game_room_data: #{e.class} - #{e.message}"
        raise e
      end
      
      # TEST BROADCAST (DIAGNOSTIC)
      begin
        Rails.logger.info "Attempting TEST broadcast with static data to room: game_room_#{@game_room.code}"
        ActionCable.server.broadcast("game_room_#{@game_room.code}", { type: 'test_event', message: 'Hello world', timestamp: Time.now.to_i })
        Rails.logger.info "TEST broadcast with static data SUCCEEDED"
      rescue => e
        Rails.logger.error "TEST broadcast with static data FAILED: #{e.class} - #{e.message}"
        Rails.logger.error "TEST broadcast Backtrace: #{e.backtrace.join('\n')}" # Log full backtrace for test
        # Do not re-raise yet, let the main broadcast attempt proceed to see if it also fails
      end
      # END TEST BROADCAST

      # Prepare payload for main broadcast
      Rails.logger.info "Preparing payload for MAIN broadcast..."
      raw_payload_player_data = deep_to_plain_object(player_data_result.as_json)
      raw_payload_game_room_data = deep_to_plain_object(game_room_data_result.as_json)
      
      # Aggressively ensure plain Ruby hash by converting to JSON string and back
      stringified_payload = { 
        type: 'player_joined',
        player: raw_payload_player_data,
        game_room: raw_payload_game_room_data
      }.to_json
      
      final_payload = JSON.parse(stringified_payload)
      Rails.logger.info "Payload for MAIN broadcast PREPARED (json stringified/parsed). Data: #{final_payload.inspect[0..500]}..."

      # DIAGNOSTIC BROADCAST - Player part only
      begin
        Rails.logger.info "Attempting DIAGNOSTIC broadcast with PLAYER part only to room: game_room_#{@game_room.code}"
        ActionCable.server.broadcast("game_room_#{@game_room.code}", { type: 'diagnostic_player_only', player: final_payload[:player] })
        Rails.logger.info "DIAGNOSTIC broadcast with PLAYER part only SUCCEEDED"
      rescue => e
        Rails.logger.error "DIAGNOSTIC broadcast with PLAYER part only FAILED: #{e.class} - #{e.message}"
        # Do not re-raise, continue to next diagnostic
      end

      # DIAGNOSTIC BROADCAST - GameRoom part only
      begin
        Rails.logger.info "Attempting DIAGNOSTIC broadcast with GAMEROOM part only to room: game_room_#{@game_room.code}"
        ActionCable.server.broadcast("game_room_#{@game_room.code}", { type: 'diagnostic_gameroom_only', game_room: final_payload[:game_room] })
        Rails.logger.info "DIAGNOSTIC broadcast with GAMEROOM part only SUCCEEDED"
      rescue => e
        Rails.logger.error "DIAGNOSTIC broadcast with GAMEROOM part only FAILED: #{e.class} - #{e.message}"
        # Do not re-raise, continue to main broadcast attempt
      end

      # DIAGNOSTIC BROADCAST - GameRoom part MINUS Players Array
      begin
        game_room_minus_players = final_payload[:game_room].except(:players)
        Rails.logger.info "Attempting DIAGNOSTIC broadcast with GAMEROOM part (NO PLAYERS ARRAY) to room: game_room_#{@game_room.code}"
        ActionCable.server.broadcast("game_room_#{@game_room.code}", { type: 'diagnostic_gameroom_no_players_array', game_room_details: game_room_minus_players })
        Rails.logger.info "DIAGNOSTIC broadcast with GAMEROOM part (NO PLAYERS ARRAY) SUCCEEDED"
      rescue => e
        Rails.logger.error "DIGNOSTIC broadcast with GAMEROOM part (NO PLAYERS ARRAY) FAILED: #{e.class} - #{e.message}"
      end

      # DIAGNOSTIC BROADCAST - Players Array ONLY
      begin
        players_array_only = final_payload[:game_room][:players]
        Rails.logger.info "Attempting DIAGNOSTIC broadcast with PLAYERS ARRAY ONLY (key: :p_data) to room: game_room_#{@game_room.code}"
        # Using a generic key like :p_data instead of :players
        ActionCable.server.broadcast("game_room_#{@game_room.code}", { type: 'diagnostic_p_data_array_only', p_data: players_array_only })
        Rails.logger.info "DIAGNOSTIC broadcast with PLAYERS ARRAY ONLY (key: :p_data) SUCCEEDED"
      rescue => e
        Rails.logger.error "DIAGNOSTIC broadcast with PLAYERS ARRAY ONLY (key: :p_data) FAILED: #{e.class} - #{e.message}"
      end

      # Prepare final payload for ACTUAL broadcast, renaming :players key in game_room
      actual_broadcast_payload = final_payload.deep_dup # Ensure we don't modify final_payload if used elsewhere
      if actual_broadcast_payload[:game_room] && actual_broadcast_payload[:game_room].key?(:players)
        Rails.logger.info "Renaming :players key to :player_list in game_room data for broadcast."
        actual_broadcast_payload[:game_room][:player_list] = actual_broadcast_payload[:game_room].delete(:players)
      end

      Rails.logger.info "Broadcasting ACTUAL player_joined event with modified payload: #{actual_broadcast_payload.inspect[0..500]}..."
      ActionCable.server.broadcast(
        "game_room_#{@game_room.code}",
        actual_broadcast_payload # This is the payload with game_room.players renamed
      )
      Rails.logger.info "Successfully broadcasted player_joined event"
      
      Rails.logger.info "About to render success response"
      render_success({ game_room: game_room_data_result }, 'Joined game room successfully')
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Validation error creating player: #{e.message}"
    render_error("Failed to join game room: #{e.record.errors.full_messages.join(', ')}")
  rescue => e
    Rails.logger.error "Unexpected error in join: #{e.class} - #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(10).join('\n')}"
    render_error('Failed to join game room. Please try again.')
  end
  
  def start_game
    Rails.logger.info "Attempting to start game: Room ID: #{@game_room.id}, Code: #{@game_room.code}, Current Status: #{@game_room.status}, Player Count: #{@game_room.players.count}"
    Rails.logger.info "can_start? evaluates to: #{@game_room.can_start?}"

    unless @game_room.can_start?
      Rails.logger.error "Start game check failed: Room ID: #{@game_room.id}, Status: #{@game_room.status}, Players: #{@game_room.players.count}"
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
        "game_room_#{@game_room.code}",
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
          "game_room_#{@game_room.code}",
          {
            type: 'game_over',
            game_state: game_service.current_game_state
          }
        )
      else
      ActionCable.server.broadcast(
          "game_room_#{@game_room.code}",
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
        "game_room_#{@game_room.code}",
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
    @game_room = GameRoom.find_by(code: params[:code])
    render_error('Game room not found', :not_found) unless @game_room
  end
  
  def set_player
    @player = @game_room.players.find_by(user: current_user)
    render_error('You are not in this game', :forbidden) unless @player
  end
  
  def game_room_data(game_room)
    # In production, use raw SQL for players query to avoid Rails 8.0 insert_all optimization issues
    if Rails.env.production?
      Rails.logger.debug "Using raw SQL for players query in game_room_data"
      # Use raw SQL to get players data to avoid Rails 8.0 optimization issues
      players_data = ActiveRecord::Base.connection.exec_query(
        "SELECT p.id, p.user_id, p.position, p.hand, u.username " \
        "FROM players p JOIN users u ON p.user_id = u.id " \
        "WHERE p.game_room_id = $1 ORDER BY p.position",
        "Players Query",
        [game_room.id]
      ).map do |row|
        {
          id: row['id'],
          user_id: row['user_id'],
          username: row['username'],
          position: row['position'],
          hand_size: JSON.parse(row['hand'] || '[]').size
        }
      end
    else
      Rails.logger.debug "Using standard Rails approach for players query in #{Rails.env}"
      players_data = game_room.players.order(:position).map { |player| player_data(player) }
    end
    
    {
      id: game_room.id,
      code: game_room.code,
      status: game_room.status,
      direction: game_room.direction,
      current_color: game_room.current_color,
      turn_player_id: game_room.turn_player_id,
      player_count: Rails.env.production? ? players_data.length : game_room.players.count,
      players: players_data,
      can_start: Rails.env.production? ? (players_data.length >= 2 && game_room.status == 'waiting') : game_room.can_start?,
      is_full: Rails.env.production? ? (players_data.length >= 4) : game_room.full?,
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