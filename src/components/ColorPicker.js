import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CARD_COLORS, COLOR_NAMES } from '../utils/cardUtils';

const ColorPicker = ({ isOpen, onColorSelect, onClose }) => {
  const colors = ['red', 'blue', 'green', 'yellow'];

  const handleColorSelect = (color) => {
    onColorSelect(color);
    onClose();
  };

  const handleOverlayClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleOverlayClick}
          />
          <motion.div
            className="color-picker"
            initial={{ opacity: 0, scale: 0.8, y: -50 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.8, y: -50 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
          >
            <h3>Choose a Color</h3>
            <div className="color-options">
              {colors.map((color) => (
                <motion.div
                  key={color}
                  className="color-option"
                  style={{ backgroundColor: CARD_COLORS[color] }}
                  onClick={() => handleColorSelect(color)}
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  initial={{ opacity: 0, scale: 0 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: colors.indexOf(color) * 0.1 }}
                >
                  {COLOR_NAMES[color]}
                </motion.div>
              ))}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};

export default ColorPicker; 