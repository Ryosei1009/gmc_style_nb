import React from 'react';

const FullScreenModal = ({ imageUrl, onClose }) => {
  return (
    <div className="fullscreen-modal" onClick={onClose}>
      <div className="fullscreen-content" onClick={(e) => e.stopPropagation()}>
        <button className="fullscreen-close" onClick={onClose}>
          ×
        </button>
        <img src={imageUrl} alt="Full screen" className="fullscreen-image" />
      </div>
    </div>
  );
};

export default FullScreenModal;
