import React from 'react';
import { motion } from 'framer-motion';

const PlayerInfo = ({ 
  player, 
  isCurrentTurn = false, 
  isCurrentPlayer = false,
  position = 'bottom'
}) => {
  const getPositionClass = () => {
    switch (position) {
      case 'top':
        return 'top-player';
      case 'left':
        return 'left-player';
      case 'right':
        return 'right-player';
      default:
        return 'current-player';
    }
  };

  const cardCountText = player.hand_size === 1 ? '1 card' : `${player.hand_size} cards`;

  return (
    <motion.div
      className={`player-info ${isCurrentTurn ? 'current-turn' : ''}`}
      style={{ gridArea: getPositionClass() }}
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
    >
      <div className="player-name">
        {player.username}
        {isCurrentPlayer && ' (You)'}
        {isCurrentTurn && ' 🎯'}
      </div>
      <div className="card-count">
        {cardCountText}
      </div>
      
      {/* Visual indicator for low card count */}
      {player.hand_size === 1 && (
        <motion.div
          style={{
            color: '#e74c3c',
            fontWeight: 'bold',
            fontSize: '12px',
            marginTop: '4px'
          }}
          animate={{ scale: [1, 1.1, 1] }}
          transition={{ repeat: Infinity, duration: 1 }}
        >
          UNO!
        </motion.div>
      )}
      
      {/* Connection status indicator */}
      <div
        style={{
          position: 'absolute',
          top: '8px',
          right: '8px',
          width: '8px',
          height: '8px',
          borderRadius: '50%',
          backgroundColor: '#2ecc71' // Always green for now, can be enhanced later
        }}
        title="Online"
      />
    </motion.div>
  );
};

export default PlayerInfo; 