import React, { useState, useEffect } from 'react';

const Editor = ({ magazine, onSave, onCancel }) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [coverImage, setCoverImage] = useState('');
  const [photos, setPhotos] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState('');

  const isEdit = magazine !== null;

  useEffect(() => {
    if (magazine) {
      setTitle(magazine.title || '');
      setDescription(magazine.description || '');
      setPrice(magazine.price || '');
      setCoverImage(magazine.cover_image || '');
      // データベースの image_url を imageUrl に変換
      const mappedPhotos = (magazine.photos || []).map(p => ({
        imageUrl: p.image_url || '',
        caption: p.caption || ''
      }));
      setPhotos(mappedPhotos.length > 0 ? mappedPhotos : [{ imageUrl: '', caption: '' }]);
    } else {
      // 新規作成時の初期値
      setPhotos([{ imageUrl: '', caption: '' }]);
    }
  }, [magazine]);

  // 写真を追加
  const addPhoto = () => {
    if (photos.length >= 15) {
      setMessage('写真は最大15枚までです');
      return;
    }
    setPhotos([...photos, { imageUrl: '', caption: '' }]);
  };

  // 写真を削除
  const removePhoto = (index) => {
    const newPhotos = photos.filter((_, i) => i !== index);
    setPhotos(newPhotos);
  };

  // 写真情報更新
  const updatePhoto = (index, field, value) => {
    const newPhotos = [...photos];
    newPhotos[index][field] = value;
    setPhotos(newPhotos);
  };

  // 写真の順序を変更
  const movePhoto = (index, direction) => {
    const newPhotos = [...photos];
    if (direction === 'up' && index > 0) {
      [newPhotos[index - 1], newPhotos[index]] = [newPhotos[index], newPhotos[index - 1]];
    } else if (direction === 'down' && index < photos.length - 1) {
      [newPhotos[index], newPhotos[index + 1]] = [newPhotos[index + 1], newPhotos[index]];
    }
    setPhotos(newPhotos);
  };

  // 保存処理
  const handleSubmit = async () => {
    if (!title.trim()) {
      setMessage('タイトルを入力してください');
      return;
    }
    if (!coverImage.trim()) {
      setMessage('表紙画像URLを入力してください');
      return;
    }
    if (photos.length === 0 || (photos.length === 1 && !photos[0].imageUrl)) {
      setMessage('少なくとも1枚の写真を追加してください');
      return;
    }

    // 有効な写真のみ抽出
    const validPhotos = photos.filter(p => p.imageUrl.trim());
    if (validPhotos.length === 0) {
      setMessage('有効な写真URLを入力してください');
      return;
    }

    setIsSubmitting(true);
    setMessage('');

    const data = {
      title,
      description,
      coverImage,
      price: parseInt(price) || 0,
      photos: validPhotos
    };

    // 編集時はIDを含める
    if (isEdit && magazine.id) {
      data.id = magazine.id;
    }

    try {
      const endpoint = isEdit ? 'updateMagazine' : 'createMagazine';
      const response = await fetch(`https://gmc_style_nb/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      const result = await response.json();

      if (result.success) {
        setMessage(isEdit ? '更新しました！' : '作成しました！');
        setTimeout(() => {
          onSave();
        }, 500);
      } else {
        setMessage(result.message || '保存に失敗しました');
        setIsSubmitting(false);
      }
    } catch (error) {
      console.error('Save error:', error);
      setMessage('エラーが発生しました');
      setIsSubmitting(false);
    }
  };

  return (
    <div className="editor-container">
      <div className="editor-header">
        <h2 className="editor-title">{isEdit ? '雑誌を編集' : '新規雑誌作成'}</h2>
      </div>

      <div className="editor-body">
        {/* 基本情報 */}
        <div className="editor-section">
          <h3 className="section-title">基本情報</h3>

          <div className="form-group">
            <label className="form-label">タイトル *</label>
            <input
              type="text"
              className="form-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="雑誌タイトル"
              maxLength={100}
            />
          </div>

          <div className="form-group">
            <label className="form-label">説明文</label>
            <textarea
              className="form-textarea"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="雑誌の説明"
              rows={2}
            />
          </div>

          <div className="form-group">
            <label className="form-label">価格 ($)</label>
            <input
              type="number"
              className="form-input"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="0"
              min={0}
            />
          </div>

          <div className="form-group">
            <label className="form-label">表紙画像URL *</label>
            <input
              type="text"
              className="form-input"
              value={coverImage}
              onChange={(e) => setCoverImage(e.target.value)}
              placeholder="https://example.com/image.jpg"
            />
            {coverImage && (
              <div className="preview-image-container">
                <img src={coverImage} alt="Cover preview" className="preview-cover" />
              </div>
            )}
          </div>
        </div>

        {/* 写真リスト */}
        <div className="editor-section">
          <div className="section-header">
            <h3 className="section-title">写真 ({photos.length}/15)</h3>
            <button
              className="add-photo-button"
              onClick={addPhoto}
              disabled={photos.length >= 15}
            >
              + 写真を追加
            </button>
          </div>

          <div className="photos-list">
            {photos.map((photo, index) => (
              <div key={index} className="photo-editor-item">
                <div className="photo-editor-header">
                  <span className="photo-number">#{index + 1}</span>
                  <div className="photo-editor-actions">
                    <button
                      className="icon-button"
                      onClick={() => movePhoto(index, 'up')}
                      disabled={index === 0}
                      title="上へ"
                    >
                      ↑
                    </button>
                    <button
                      className="icon-button"
                      onClick={() => movePhoto(index, 'down')}
                      disabled={index === photos.length - 1}
                      title="下へ"
                    >
                      ↓
                    </button>
                    <button
                      className="icon-button delete-button"
                      onClick={() => removePhoto(index)}
                      title="削除"
                    >
                      ×
                    </button>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">画像URL</label>
                  <input
                    type="text"
                    className="form-input"
                    value={photo.imageUrl}
                    onChange={(e) => updatePhoto(index, 'imageUrl', e.target.value)}
                    placeholder="https://example.com/photo.jpg"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">キャプション (200)</label>
                  <input
                    type="text"
                    className="form-input"
                    value={photo.caption}
                    onChange={(e) => updatePhoto(index, 'caption', e.target.value)}
                    placeholder="説明文"
                    maxLength={200}
                  />
                </div>

                {photo.imageUrl && (
                  <div className="preview-image-container small">
                    <img src={photo.imageUrl} alt={`Preview ${index}`} className="preview-photo" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {message && (
          <div className={`editor-message ${message.includes('失敗') || message.includes('エラー') ? 'error' : 'success'}`}>
            {message}
          </div>
        )}
      </div>

      {/* フッターボタン */}
      <div className="editor-footer">
        <button
          className="editor-button cancel-button"
          onClick={onCancel}
          disabled={isSubmitting}
        >
          キャンセル
        </button>
        <button
          className="editor-button save-button"
          onClick={handleSubmit}
          disabled={isSubmitting}
        >
          {isSubmitting ? '保存中...' : (isEdit ? '更新' : '作成')}
        </button>
      </div>
    </div>
  );
};

export default Editor;
