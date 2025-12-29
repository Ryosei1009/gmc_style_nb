import React from 'react';

const ConfirmDialog = ({
  title,
  message,
  onConfirm,
  onCancel,
  confirmText = 'はい',
  cancelText = 'いいえ',
  isProcessing = false,
  resultMessage = null
}) => {
  return (
    <div className="dialog-overlay">
      <div className="dialog-container">
        <div className="dialog-header">
          <h2 className="dialog-title">{title}</h2>
        </div>

        <div className="dialog-body">
          <p className="dialog-message-text">{message}</p>

          {resultMessage && (
            <div className={`dialog-message ${resultMessage.includes('失敗') || resultMessage.includes('エラー') ? 'error' : 'success'}`}>
              {resultMessage}
            </div>
          )}
        </div>

        <div className="dialog-footer">
          <button
            className="dialog-button cancel-button"
            onClick={onCancel}
            disabled={isProcessing}
          >
            {cancelText}
          </button>
          <button
            className="dialog-button confirm-button"
            onClick={onConfirm}
            disabled={isProcessing}
          >
            {isProcessing ? '処理中...' : confirmText}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
