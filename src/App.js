import React, { useState } from 'react';
import './styles/global.css';

function App() {
  const [username, setUsername] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    alert('Hello ' + username + '! React is working!');
  };

  return (
    <div style={{
      padding: '50px', 
      textAlign: 'center', 
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', 
      minHeight: '100vh', 
      color: 'white',
      fontFamily: 'Arial, sans-serif'
    }}>
      <h1>🎮 UNO Online - TEST</h1>
      <p>React is working!</p>
      
      <div style={{
        background: 'white',
        color: 'black',
        padding: '30px',
        borderRadius: '10px',
        maxWidth: '400px',
        margin: '20px auto',
        boxShadow: '0 4px 8px rgba(0,0,0,0.1)'
      }}>
        <h2>Enter Your Username</h2>
        <form onSubmit={handleSubmit}>
          <input 
            type="text" 
            placeholder="Enter username..." 
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            style={{
              padding: '12px', 
              margin: '10px',
              width: '250px',
              borderRadius: '5px',
              border: '2px solid #ccc',
              fontSize: '16px'
            }}
          />
          <br />
          <button 
            type="submit"
            style={{
              padding: '12px 24px', 
              margin: '10px',
              background: '#3498db',
              color: 'white',
              border: 'none',
              borderRadius: '5px',
              cursor: 'pointer',
              fontSize: '16px',
              fontWeight: 'bold'
            }}
          >
            Test Button
          </button>
        </form>
        <p style={{ marginTop: '15px', fontSize: '14px', color: '#666' }}>
          Type a username and click the button to test React functionality
        </p>
      </div>
    </div>
  );
}

export default App; 