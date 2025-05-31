import React from 'react';
import { motion } from 'framer-motion';
import UnoCard from './UnoCard';
import PlayerInfo from './PlayerInfo';
import PlayerHand from './PlayerHand';
import { COLOR_NAMES } from '../utils/cardUtils';

const GameTable = ({ 
  gameState, 
  currentUserId, 
  onCardPlay, 
  onDrawCard 
}) => {
  if (!gameState) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  const { game_room, players, top_card, draw_pile_size } = gameState;
  const currentPlayer = players.find(p => p.user_id === currentUserId);
  const otherPlayers = players.filter(p => p.user_id !== currentUserId);
  
  // Arrange other players around the table
  const arrangedPlayers = [];
  if (otherPlayers.length >= 1) arrangedPlayers.push({ ...otherPlayers[0], position: 'top' });
  if (otherPlayers.length >= 2) arrangedPlayers.push({ ...otherPlayers[1], position: 'left' });
  if (otherPlayers.length >= 3) arrangedPlayers.push({ ...otherPlayers[2], position: 'right' });

  const isMyTurn = currentPlayer && game_room.turn_player_id === currentPlayer.id;

  return (
    <div className="game-table">
      {/* Other players */}
      {arrangedPlayers.map((player) => (
        <PlayerInfo
          key={player.id}
          player={player}
          isCurrentTurn={game_room.turn_player_id === player.id}
          position={player.position}
        />
      ))}

      {/* Game center - discard pile and draw pile */}
      <div className="game-center">
        <div style={{ display: 'flex', gap: '40px', alignItems: 'center' }}>
          {/* Draw pile */}
          <div className="draw-pile">
            <UnoCard
              isBack={true}
              isLarge={true}
              onClick={isMyTurn ? onDrawCard : undefined}
            />
            <div className="pile-info">
              Draw Pile<br />
              {draw_pile_size} cards
            </div>
          </div>

          {/* Direction indicator */}
          <motion.div
            style={{
              fontSize: '2rem',
              color: 'white',
              textShadow: '2px 2px 4px rgba(0, 0, 0, 0.5)'
            }}
            animate={{ rotate: game_room.direction === 'clockwise' ? 0 : 180 }}
            transition={{ duration: 0.5 }}
          >
            ↻
          </motion.div>

          {/* Discard pile */}
          <div className="discard-pile">
            <UnoCard
              card={top_card}
              isLarge={true}
            />
            <div className="pile-info">
              Discard Pile<br />
              {game_room.current_color && (
                <span style={{ 
                  color: game_room.current_color === 'yellow' ? '#f1c40f' : game_room.current_color,
                  fontWeight: 'bold' 
                }}>
                  Current: {COLOR_NAMES[game_room.current_color]}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Game status */}
        <motion.div
          style={{
            color: 'white',
            textAlign: 'center',
            fontSize: '1.2rem',
            fontWeight: 'bold',
            textShadow: '2px 2px 4px rgba(0, 0, 0, 0.5)',
            marginTop: '20px'
          }}
          key={game_room.turn_player_id}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
        >
          {isMyTurn ? "Your Turn!" : `${players.find(p => p.id === game_room.turn_player_id)?.username}'s Turn`}
        </motion.div>
      </div>

      {/* Current player's hand */}
      {currentPlayer && (
        <div style={{ gridArea: 'current-player' }}>
          <PlayerInfo
            player={currentPlayer}
            isCurrentTurn={isMyTurn}
            isCurrentPlayer={true}
            position="bottom"
          />
          <PlayerHand
            cards={currentPlayer.hand || []}
            topCard={top_card}
            currentColor={game_room.current_color}
            isMyTurn={isMyTurn}
            onCardPlay={onCardPlay}
            onDrawCard={onDrawCard}
          />
        </div>
      )}
    </div>
  );
};

export default GameTable; 