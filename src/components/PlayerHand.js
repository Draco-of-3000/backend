import React, { useState } from 'react';
import { motion } from 'framer-motion';
import UnoCard from './UnoCard';
import ColorPicker from './ColorPicker';
import { sortCards, getPlayableCards, isWildCard } from '../utils/cardUtils';

const PlayerHand = ({ 
  cards = [], 
  topCard, 
  currentColor, 
  isMyTurn, 
  onCardPlay, 
  onDrawCard,
  canDraw = true 
}) => {
  const [selectedCard, setSelectedCard] = useState(null);
  const [showColorPicker, setShowColorPicker] = useState(false);

  const sortedCards = sortCards(cards);
  const playableCards = getPlayableCards(cards, topCard, currentColor);

  const handleCardClick = (card) => {
    if (!isMyTurn) return;

    const isPlayable = playableCards.some(
      pc => pc.color === card.color && 
            pc.value === card.value && 
            pc.card_type === card.card_type
    );

    if (!isPlayable) return;

    setSelectedCard(card);

    if (isWildCard(card)) {
      setShowColorPicker(true);
    } else {
      playCard(card);
    }
  };

  const playCard = (card, chosenColor = null) => {
    if (onCardPlay) {
      onCardPlay(card, chosenColor);
    }
    setSelectedCard(null);
  };

  const handleColorSelect = (color) => {
    if (selectedCard) {
      playCard(selectedCard, color);
    }
    setShowColorPicker(false);
  };

  const handleDrawCard = () => {
    if (isMyTurn && canDraw && onDrawCard) {
      onDrawCard();
    }
  };

  return (
    <div className="player-hand-container">
      <div className="player-hand">
        {sortedCards.map((card, index) => {
          const isPlayable = playableCards.some(
            pc => pc.color === card.color && 
                  pc.value === card.value && 
                  pc.card_type === card.card_type
          );
          const isSelected = selectedCard && 
            selectedCard.color === card.color && 
            selectedCard.value === card.value && 
            selectedCard.card_type === card.card_type;

          return (
            <motion.div
              key={`${card.color}-${card.value}-${card.card_type}-${index}`}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <UnoCard
                card={card}
                onClick={handleCardClick}
                isPlayable={isMyTurn && isPlayable}
                isSelected={isSelected}
              />
            </motion.div>
          );
        })}
      </div>

      {isMyTurn && playableCards.length === 0 && canDraw && (
        <div style={{ textAlign: 'center', marginTop: '20px' }}>
          <motion.button
            className="btn btn-primary"
            onClick={handleDrawCard}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            Draw Card
          </motion.button>
        </div>
      )}

      {!isMyTurn && (
        <div style={{ textAlign: 'center', marginTop: '20px', color: 'white' }}>
          <p>Waiting for other players...</p>
        </div>
      )}

      <ColorPicker
        isOpen={showColorPicker}
        onColorSelect={handleColorSelect}
        onClose={() => {
          setShowColorPicker(false);
          setSelectedCard(null);
        }}
      />
    </div>
  );
};

export default PlayerHand; 