import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

class ApiService {
  constructor() {
    this.client = axios.create({
      baseURL: `${API_BASE_URL}/api/v1`,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add request interceptor to include user ID
    this.client.interceptors.request.use((config) => {
      const userId = localStorage.getItem('userId');
      if (userId) {
        config.headers['X-User-ID'] = userId;
      }
      return config;
    });

    // Add response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        console.error('API Error:', error.response?.data || error.message);
        return Promise.reject(error);
      }
    );
  }

  // User endpoints
  async createUser(username) {
    const response = await this.client.post('/users', {
      user: { username }
    });
    return response.data;
  }

  async getUser(userId) {
    const response = await this.client.get(`/users/${userId}`);
    return response.data;
  }

  // Game room endpoints
  async getGameRooms() {
    const response = await this.client.get('/game_rooms');
    return response.data;
  }

  async createGameRoom() {
    const response = await this.client.post('/game_rooms');
    return response.data;
  }

  async getGameRoom(roomId) {
    const response = await this.client.get(`/game_rooms/${roomId}`);
    return response.data;
  }

  async joinGameRoom(roomId) {
    const response = await this.client.post(`/game_rooms/${roomId}/join`);
    return response.data;
  }

  async startGame(roomId) {
    const response = await this.client.post(`/game_rooms/${roomId}/start_game`);
    return response.data;
  }

  async getGameState(roomId) {
    const response = await this.client.get(`/game_rooms/${roomId}/state`);
    return response.data;
  }

  // Game action endpoints
  async playCard(roomId, card, chosenColor = null) {
    const payload = { card };
    if (chosenColor) {
      payload.chosen_color = chosenColor;
    }
    const response = await this.client.post(`/game_rooms/${roomId}/play_card`, payload);
    return response.data;
  }

  async drawCard(roomId) {
    const response = await this.client.post(`/game_rooms/${roomId}/draw_card`);
    return response.data;
  }
}

export default new ApiService(); 