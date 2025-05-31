import React, { useState } from 'react';

const Lobby = ({ currentUser, onUserCreate }) => {
  const [username, setUsername] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (username.trim()) {
      onUserCreate({ id: Date.now(), username: username.trim() });
    }
  };

  if (!currentUser) {
    return (
      <div className="lobby">
        <h1>🎮 UNO Online</h1>
        <div className="card">
          <h2>Enter Your Username</h2>
          <form onSubmit={handleSubmit}>
            <input 
              type="text" 
              className="input" 
              placeholder="Enter username..." 
              value={username} 
              onChange={(e) => setUsername(e.target.value)} 
            />
            <button type="submit" className="btn btn-primary">
              Join Game
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="lobby">
      <h1>Welcome, {currentUser.username}! 🎮</h1>
      <div className="card">
        <h2>Ready to play!</h2>
        <p>Username form is working!</p>
      </div>
    </div>
  );
};

export default Lobby; 