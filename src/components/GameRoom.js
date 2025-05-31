import React, { useState } from 'react';
import { motion } from 'framer-motion';
import apiService from '../services/api';

const GameRoom = ({ 
  gameRoom, 
  currentUser, 
  onGameStart, 
  onLeaveRoom 
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleStartGame = async () => {
    if (gameRoom.player_count < 2) {
      setError('Need at least 2 players to start the game');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await apiService.startGame(gameRoom.id);
      if (response.success) {
        onGameStart(response.data.game_state);
      } else {
        setError(response.error || 'Failed to start game');
      }
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to start game');
    } finally {
      setLoading(false);
    }
  };

  const handleLeaveRoom = () => {
    if (onLeaveRoom) {
      onLeaveRoom();
    }
  };

  return (
    <div className="container">
      <motion.div
        className="card"
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5 }}
        style={{ maxWidth: '600px', margin: '40px auto' }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
          <h1>Game Room #{gameRoom.id}</h1>
          <button
            className="btn btn-secondary"
            onClick={handleLeaveRoom}
          >
            Leave Room
          </button>
        </div>

        <div style={{ marginBottom: '30px' }}>
          <h3>Players ({gameRoom.player_count}/4)</h3>
          <div style={{ display: 'grid', gap: '12px', marginTop: '16px' }}>
            {gameRoom.players.map((player, index) => (
              <motion.div
                key={player.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  padding: '12px 16px',
                  background: player.user_id === currentUser.id ? '#e8f5e8' : '#f8f9fa',
                  borderRadius: '8px',
                  border: player.user_id === currentUser.id ? '2px solid #2ecc71' : '1px solid #ddd'
                }}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
              >
                <div
                  style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: '#2ecc71',
                    marginRight: '12px'
                  }}
                />
                <span style={{ fontWeight: 'bold' }}>
                  {player.username}
                  {player.user_id === currentUser.id && ' (You)'}
                </span>
                <span style={{ marginLeft: 'auto', fontSize: '14px', color: '#666' }}>
                  Position {player.position + 1}
                </span>
              </motion.div>
            ))}
            
            {/* Empty slots */}
            {Array.from({ length: 4 - gameRoom.player_count }).map((_, index) => (
              <motion.div
                key={`empty-${index}`}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  padding: '12px 16px',
                  background: '#f8f9fa',
                  borderRadius: '8px',
                  border: '1px dashed #ccc'
                }}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: (gameRoom.player_count + index) * 0.1 }}
              >
                <div
                  style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: '#bdc3c7',
                    marginRight: '12px'
                  }}
                />
                <span style={{ color: '#666', fontStyle: 'italic' }}>
                  Waiting for player...
                </span>
              </motion.div>
            ))}
          </div>
        </div>

        {error && (
          <motion.div
            style={{ 
              color: '#e74c3c', 
              marginBottom: '20px', 
              textAlign: 'center',
              padding: '12px',
              background: '#fdf2f2',
              borderRadius: '8px',
              border: '1px solid #f5c6cb'
            }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            {error}
          </motion.div>
        )}

        <div style={{ textAlign: 'center' }}>
          {gameRoom.can_start ? (
            <motion.button
              className="btn btn-success"
              onClick={handleStartGame}
              disabled={loading}
              style={{ fontSize: '18px', padding: '16px 32px' }}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {loading ? 'Starting Game...' : 'Start Game'}
            </motion.button>
          ) : (
            <div>
              <p style={{ color: '#666', marginBottom: '16px' }}>
                {gameRoom.player_count < 2 
                  ? 'Waiting for more players to join...' 
                  : 'Ready to start!'}
              </p>
              {gameRoom.player_count < 2 && (
                <motion.div
                  style={{
                    display: 'inline-block',
                    padding: '8px 16px',
                    background: '#fff3cd',
                    border: '1px solid #ffeaa7',
                    borderRadius: '8px',
                    color: '#856404'
                  }}
                  animate={{ scale: [1, 1.02, 1] }}
                  transition={{ repeat: Infinity, duration: 2 }}
                >
                  Need at least 2 players to start
                </motion.div>
              )}
            </div>
          )}
        </div>

        <div style={{ marginTop: '30px', padding: '16px', background: '#f8f9fa', borderRadius: '8px' }}>
          <h4 style={{ marginBottom: '12px' }}>Game Rules:</h4>
          <ul style={{ margin: 0, paddingLeft: '20px', color: '#666' }}>
            <li>Match the color or number/symbol of the top card</li>
            <li>Wild cards can be played anytime and let you choose the color</li>
            <li>Special cards: Skip, Reverse, Draw Two, Wild Draw Four</li>
            <li>First player to empty their hand wins!</li>
          </ul>
        </div>
      </motion.div>
    </div>
  );
};

export default GameRoom; 