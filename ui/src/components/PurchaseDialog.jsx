import React, { useState } from 'react';

const PurchaseDialog = ({ magazine, onConfirm, onCancel }) => {
  const [isProcessing, setIsProcessing] = useState(false);
  const [message, setMessage] = useState('');
  const [purchasePassword, setPurchasePassword] = useState('');

  const handlePurchase = async () => {
    setIsProcessing(true);
    setMessage('');

    try {
      const response = await fetch('https://gmc_style_nb/purchaseMagazine', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: magazine.id, price: magazine.price, password: purchasePassword })
      });
      const result = await response.json();

      if (result.success) {
        setMessage('購入しました！');
        setTimeout(() => {
          onConfirm();
        }, 500);
      } else {
        setMessage(result.message || '購入に失敗しました');
        setIsProcessing(false);
      }
    } catch (error) {
      console.error('Purchase error:', error);
      setMessage('エラーが発生しました');
      setIsProcessing(false);
    }
  };

  return (
    <div className="dialog-overlay">
      <div className="dialog-container">
        <div className="dialog-header">
          <h2 className="dialog-title">購入確認</h2>
        </div>

        <div className="dialog-body">
          <div className="purchase-preview">
            <img
              src={magazine.cover_image}
              alt={magazine.title}
              className="purchase-cover"
            />
          </div>
          <h3 className="purchase-magazine-title">{magazine.title}</h3>
          {magazine.description && (
            <p className="purchase-description">{magazine.description}</p>
          )}

          <div className="purchase-price">
            <span className="price-amount">${magazine.price}</span>
          </div>

          {magazine.requires_password && (
            <div className="form-group" style={{ marginTop: '12px' }}>
              <label className="form-label">購入パスワード</label>
              <input
                type="password"
                className="form-input"
                value={purchasePassword}
                onChange={(e) => setPurchasePassword(e.target.value)}
                placeholder="パスワードを入力"
                maxLength={100}
              />
            </div>
          )}

          {message && (
            <div className={`dialog-message ${message.includes('失敗') || message.includes('エラー') || message.includes('足りません') ? 'error' : 'success'}`}>
              {message}
            </div>
          )}
        </div>

        <div className="dialog-footer">
          <button
            className="dialog-button cancel-button"
            onClick={onCancel}
            disabled={isProcessing}
          >
            いいえ
          </button>
          <button
            className="dialog-button confirm-button"
            onClick={handlePurchase}
            disabled={isProcessing}
          >
            {isProcessing ? '処理中...' : 'はい'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default PurchaseDialog;
