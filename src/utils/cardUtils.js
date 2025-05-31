// Card color mappings
export const CARD_COLORS = {
  red: '#e74c3c',
  blue: '#3498db',
  green: '#2ecc71',
  yellow: '#f1c40f',
  wild: '#34495e'
};

export const COLOR_NAMES = {
  red: 'Red',
  blue: 'Blue',
  green: 'Green',
  yellow: 'Yellow',
  wild: 'Wild'
};

// Card type mappings
export const CARD_TYPES = {
  number: 'Number',
  skip: 'Skip',
  reverse: 'Reverse',
  draw_two: 'Draw Two',
  wild: 'Wild',
  wild_draw_four: 'Wild Draw Four'
};

// Get display name for a card
export const getCardDisplayName = (card) => {
  if (!card) return '';
  
  if (card.card_type === 'wild' || card.card_type === 'wild_draw_four') {
    return CARD_TYPES[card.card_type];
  }
  
  if (card.card_type === 'number') {
    return `${COLOR_NAMES[card.color]} ${card.value}`;
  }
  
  return `${COLOR_NAMES[card.color]} ${CARD_TYPES[card.card_type]}`;
};

// Get card color for styling
export const getCardColor = (card) => {
  return CARD_COLORS[card.color] || CARD_COLORS.wild;
};

// Check if a card is playable on another card
export const canPlayCard = (card, topCard, currentColor) => {
  if (!card || !topCard) return false;
  
  // Wild cards can always be played
  if (card.card_type === 'wild' || card.card_type === 'wild_draw_four') {
    return true;
  }
  
  // Same color
  if (card.color === topCard.color) {
    return true;
  }
  
  // Same value/type
  if (card.value === topCard.value && card.card_type === topCard.card_type) {
    return true;
  }
  
  // Current color (for wild cards)
  if (currentColor && card.color === currentColor) {
    return true;
  }
  
  return false;
};

// Check if a card is a special card
export const isSpecialCard = (card) => {
  return card.card_type !== 'number';
};

// Check if a card is a wild card
export const isWildCard = (card) => {
  return card.card_type === 'wild' || card.card_type === 'wild_draw_four';
};

// Get card symbol/icon
export const getCardSymbol = (card) => {
  switch (card.card_type) {
    case 'skip':
      return '⊘';
    case 'reverse':
      return '↻';
    case 'draw_two':
      return '+2';
    case 'wild':
      return '🌈';
    case 'wild_draw_four':
      return '+4';
    default:
      return card.value;
  }
};

// Sort cards by color and value
export const sortCards = (cards) => {
  const colorOrder = ['red', 'blue', 'green', 'yellow', 'wild'];
  const typeOrder = ['number', 'skip', 'reverse', 'draw_two', 'wild', 'wild_draw_four'];
  
  return [...cards].sort((a, b) => {
    // Sort by color first
    const colorDiff = colorOrder.indexOf(a.color) - colorOrder.indexOf(b.color);
    if (colorDiff !== 0) return colorDiff;
    
    // Then by type
    const typeDiff = typeOrder.indexOf(a.card_type) - typeOrder.indexOf(b.card_type);
    if (typeDiff !== 0) return typeDiff;
    
    // Finally by value (for number cards)
    if (a.card_type === 'number' && b.card_type === 'number') {
      return parseInt(a.value) - parseInt(b.value);
    }
    
    return 0;
  });
};

// Get playable cards from hand
export const getPlayableCards = (hand, topCard, currentColor) => {
  return hand.filter(card => canPlayCard(card, topCard, currentColor));
}; 