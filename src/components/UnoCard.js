import React from 'react';
import { motion } from 'framer-motion';
import { getCardColor, getCardSymbol, getCardDisplayName, isWildCard } from '../utils/cardUtils';

const UnoCard = ({ 
  card, 
  onClick, 
  isPlayable = false, 
  isSelected = false, 
  isLarge = false, 
  isBack = false,
  className = '',
  ...props 
}) => {
  const handleClick = () => {
    if (onClick && !isBack) {
      onClick(card);
    }
  };

  const cardStyle = {
    backgroundColor: isBack ? undefined : getCardColor(card),
    color: isBack ? 'white' : (card?.color === 'yellow' ? '#333' : 'white'),
  };

  const cardClasses = [
    'uno-card',
    isLarge && 'large',
    isBack && 'back',
    isPlayable && 'playable',
    isSelected && 'selected',
    className
  ].filter(Boolean).join(' ');

  if (isBack) {
    return (
      <motion.div
        className={cardClasses}
        style={cardStyle}
        onClick={handleClick}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        {...props}
      >
        <div className="card-symbol">UNO</div>
        <div className="card-text">DRAW</div>
      </motion.div>
    );
  }

  if (!card) {
    return (
      <div className={`uno-card ${className}`}>
        <div className="card-symbol">?</div>
      </div>
    );
  }

  return (
    <motion.div
      className={cardClasses}
      style={cardStyle}
      onClick={handleClick}
      whileHover={onClick ? { scale: 1.05, y: -4 } : {}}
      whileTap={onClick ? { scale: 0.95 } : {}}
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
      {...props}
    >
      <div className="card-symbol">
        {getCardSymbol(card)}
      </div>
      <div className="card-text">
        {isWildCard(card) ? card.card_type.replace('_', ' ').toUpperCase() : ''}
      </div>
      
      {/* Corner indicators for non-wild cards */}
      {!isWildCard(card) && (
        <>
          <div 
            style={{
              position: 'absolute',
              top: '4px',
              left: '4px',
              fontSize: isLarge ? '12px' : '8px',
              fontWeight: 'bold'
            }}
          >
            {getCardSymbol(card)}
          </div>
          <div 
            style={{
              position: 'absolute',
              bottom: '4px',
              right: '4px',
              fontSize: isLarge ? '12px' : '8px',
              fontWeight: 'bold',
              transform: 'rotate(180deg)'
            }}
          >
            {getCardSymbol(card)}
          </div>
        </>
      )}
    </motion.div>
  );
};

export default UnoCard; 