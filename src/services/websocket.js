import { createConsumer } from '@rails/actioncable';

const WS_URL = process.env.REACT_APP_WS_URL || 'ws://localhost:3001/cable';

class WebSocketService {
  constructor() {
    this.consumer = null;
    this.subscription = null;
    this.callbacks = {};
  }

  connect(userId) {
    if (this.consumer) {
      this.disconnect();
    }

    this.consumer = createConsumer(`${WS_URL}?user_id=${userId}`);
    console.log('WebSocket connected for user:', userId);
  }

  subscribeToGameRoom(gameRoomId, callbacks = {}) {
    if (!this.consumer) {
      console.error('WebSocket not connected. Call connect() first.');
      return;
    }

    // Unsubscribe from previous room if any
    if (this.subscription) {
      this.subscription.unsubscribe();
    }

    this.callbacks = callbacks;

    this.subscription = this.consumer.subscriptions.create(
      {
        channel: 'GameRoomChannel',
        game_room_id: gameRoomId
      },
      {
        connected: () => {
          console.log('Subscribed to game room:', gameRoomId);
          if (this.callbacks.onConnected) {
            this.callbacks.onConnected();
          }
        },

        disconnected: () => {
          console.log('Disconnected from game room:', gameRoomId);
          if (this.callbacks.onDisconnected) {
            this.callbacks.onDisconnected();
          }
        },

        received: (data) => {
          console.log('Received WebSocket message:', data);
          this.handleMessage(data);
        }
      }
    );
  }

  handleMessage(data) {
    const { type } = data;

    switch (type) {
      case 'player_joined':
        if (this.callbacks.onPlayerJoined) {
          this.callbacks.onPlayerJoined(data);
        }
        break;

      case 'player_connected':
        if (this.callbacks.onPlayerConnected) {
          this.callbacks.onPlayerConnected(data);
        }
        break;

      case 'player_disconnected':
        if (this.callbacks.onPlayerDisconnected) {
          this.callbacks.onPlayerDisconnected(data);
        }
        break;

      case 'game_started':
        if (this.callbacks.onGameStarted) {
          this.callbacks.onGameStarted(data);
        }
        break;

      case 'card_played':
        if (this.callbacks.onCardPlayed) {
          this.callbacks.onCardPlayed(data);
        }
        break;

      case 'card_drawn':
        if (this.callbacks.onCardDrawn) {
          this.callbacks.onCardDrawn(data);
        }
        break;

      case 'game_state_update':
        if (this.callbacks.onGameStateUpdate) {
          this.callbacks.onGameStateUpdate(data);
        }
        break;

      case 'pong':
        // Handle ping/pong for connection health
        break;

      default:
        console.log('Unknown message type:', type, data);
    }
  }

  sendMessage(action, data = {}) {
    if (this.subscription) {
      this.subscription.send({ action, ...data });
    }
  }

  requestGameState() {
    this.sendMessage('request_game_state');
  }

  ping() {
    this.sendMessage('ping');
  }

  unsubscribeFromGameRoom() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
  }

  disconnect() {
    this.unsubscribeFromGameRoom();
    if (this.consumer) {
      this.consumer.disconnect();
      this.consumer = null;
    }
    this.callbacks = {};
  }
}

export default new WebSocketService(); 