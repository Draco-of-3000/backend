# UNO Online - Frontend

A real-time multiplayer UNO card game built with React.js and Rails Action Cable.

## Features

- **Real-time Multiplayer**: 2-4 players can play simultaneously via WebSocket connections
- **Complete UNO Rules**: All standard UNO cards and rules implemented
- **Responsive Design**: Works on desktop and mobile devices
- **Beautiful UI**: Modern, animated interface with smooth card interactions
- **Live Game Updates**: Real-time updates for card plays, draws, and game state changes

## Tech Stack

- **Frontend**: React.js 18 with Hooks
- **Animations**: Framer Motion for smooth animations
- **WebSocket**: Rails Action Cable for real-time communication
- **HTTP Client**: Axios for API requests
- **Styling**: Custom CSS with responsive design

## Game Components

### Core Components
- **UnoCard**: Reusable card component with animations and interactions
- **PlayerHand**: Manages player's cards with playability indicators
- **GameTable**: Main game interface showing all players and game state
- **ColorPicker**: Modal for choosing colors when playing wild cards

### Screen Components
- **Lobby**: Username entry and game room management
- **GameRoom**: Waiting room for players before game starts
- **GameTable**: Active game interface

## Installation & Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Environment Configuration**
   The app is configured to connect to:
   - Rails API: `http://localhost:3001`
   - WebSocket: `ws://localhost:3001/cable`

3. **Start Development Server**
   ```bash
   # Start React frontend only
   npm start
   
   # Start both Rails backend and React frontend
   npm run start:dev
   ```

## Game Flow

1. **Enter Username**: Players enter their username to join
2. **Lobby**: View available game rooms or create a new one
3. **Waiting Room**: Players join and wait for game to start (2-4 players)
4. **Game Play**: Real-time UNO game with full rule implementation
5. **Game End**: Winner announcement and option to play again

## UNO Rules Implemented

- **Number Cards**: 0-9 in four colors (red, blue, green, yellow)
- **Special Cards**:
  - **Skip**: Skip next player's turn
  - **Reverse**: Reverse turn direction
  - **Draw Two**: Next player draws 2 cards and loses turn
  - **Wild**: Change color, can be played anytime
  - **Wild Draw Four**: Change color and next player draws 4 cards

## Real-time Features

- Player joins/leaves notifications
- Live card play updates
- Turn indicators
- Game state synchronization
- Connection status indicators

## Responsive Design

- **Desktop**: Full game table layout with players arranged around the table
- **Mobile**: Stacked layout optimized for touch interactions
- **Adaptive Cards**: Card sizes adjust based on screen size

## API Integration

The frontend communicates with the Rails backend via:
- **REST API**: User management, game room operations, card actions
- **WebSocket**: Real-time game updates and player interactions

## Development

### Project Structure
```
src/
├── components/          # React components
├── services/           # API and WebSocket services
├── utils/              # Utility functions (card logic)
├── styles/             # CSS styles
└── App.js              # Main application component
```

### Key Services
- **apiService**: HTTP requests to Rails API
- **webSocketService**: WebSocket connection management
- **cardUtils**: Card validation and utility functions

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge

## Performance

- Optimized animations with Framer Motion
- Efficient WebSocket message handling
- Responsive image loading
- Minimal re-renders with React hooks

## Future Enhancements

- Sound effects for card plays
- Player avatars
- Game statistics
- Tournament mode
- Spectator mode
