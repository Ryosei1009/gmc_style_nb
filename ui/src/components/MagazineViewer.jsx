import React, { useState } from 'react';
import ConfirmDialog from './ConfirmDialog';

const MagazineViewer = ({ magazine, onBack, onEdit, isPhoto }) => {
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteMessage, setDeleteMessage] = useState(null);

  // 表紙を含めた全画像を取得
  const allImages = [
    { url: magazine.cover_image, caption: magazine.title || '表紙', isCover: true },
    ...(magazine.photos || []).map(p => ({ url: p.image_url, caption: p.caption }))
  ];

  const handleImageClick = (imageUrl) => {
    // クライアントイベントを発火して画像をゲーム画面全体に表示
    fetch('https://gmc_style_nb/showImage', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ imageUrl })
    });
  };

  const handleDeleteClick = () => {
    setShowDeleteDialog(true);
    setDeleteMessage(null);
  };

  const handleDeleteConfirm = async () => {
    setIsDeleting(true);
    setDeleteMessage(null);

    try {
      const response = await fetch('https://gmc_style_nb/deleteMagazine', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: magazine.id })
      });
      const result = await response.json();
      if (result.success) {
        setDeleteMessage('削除しました！');
        setTimeout(() => {
          setShowDeleteDialog(false);
          onBack();
        }, 500);
      } else {
        setDeleteMessage('削除に失敗しました');
        setIsDeleting(false);
      }
    } catch (error) {
      console.error('Error deleting magazine:', error);
      setDeleteMessage('エラーが発生しました');
      setIsDeleting(false);
    }
  };

  return (
    <div className="magazine-viewer">
      {/* ナビゲーションヘッダー */}
      <div className="viewer-nav">
        <button className="nav-button back-button" onClick={onBack}>
          <span className="nav-icon">←</span> 戻る
        </button>
        <h2 className="viewer-title">{magazine.title}</h2>
        {isPhoto && (
          <div className="viewer-actions">
            <button className="nav-button" onClick={() => onEdit(magazine.id)}>
              編集
            </button>
            <button className="nav-button delete-button" onClick={handleDeleteClick}>
              削除
            </button>
          </div>
        )}
      </div>

      {/* 雑誌説明 */}
      {magazine.description && (
        <div className="magazine-desc">{magazine.description}</div>
      )}

      {/* 写真ギャラリー（縦スクロール） */}
      <div className="photo-gallery">
        {allImages.map((image, index) => (
          <div key={index} className="photo-item">
            <div
              className="photo-container"
              onClick={() => handleImageClick(image.url)}
            >
              <img
                src={image.url}
                alt={image.caption || `Photo ${index + 1}`}
                className="photo-image"
              />
              <div className="photo-tap-hint">タップで拡大</div>
            </div>
            {image.caption && (
              <div className="photo-caption">{image.caption}</div>
            )}
          </div>
        ))}
      </div>

      {/* 削除確認ダイアログ */}
      {showDeleteDialog && (
        <ConfirmDialog
          title="削除確認"
          message={`${magazine.title} を削除しますか？`}
          onConfirm={handleDeleteConfirm}
          onCancel={() => setShowDeleteDialog(false)}
          confirmText="削除"
          cancelText="キャンセル"
          isProcessing={isDeleting}
          resultMessage={deleteMessage}
        />
      )}
    </div>
  );
};

export default MagazineViewer;
