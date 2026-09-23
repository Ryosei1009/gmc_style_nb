import React from 'react';

const MagazineList = ({ magazines, onMagazineClick, onEdit, isPhoto }) => {
  return (
    <div className="magazine-list">
      {magazines.length === 0 ? (
        <div className="empty-state">
          <p className="empty-text">雑誌がありません</p>
        </div>
      ) : (
        <div className="magazine-grid">
          {magazines.map((magazine) => (
            <div
              key={magazine.id}
              className="magazine-card"
              onClick={() => onMagazineClick(magazine)}
            >
              <div className="magazine-cover">
                <img
                  src={magazine.cover_image}
                  alt={magazine.title}
                  className="cover-image"
                />
                {magazine.purchased && (
                  <div className="purchased-badge">読む</div>
                )}
                {Number(magazine.is_public) === 0 && (
                  <div className="purchased-badge" style={{ top: '38px', backgroundColor: '#333' }}>非公開</div>
                )}
                {magazine.requires_password && (
                  <div className="purchased-badge" style={{ top: '66px', backgroundColor: '#7a1f1f' }}>PW必須</div>
                )}
              </div>
              <div className="magazine-info">
                <h3 className="magazine-title">{magazine.title}</h3>
                <p className="magazine-description">{magazine.description}</p>
                <div className="magazine-footer">
                  {magazine.purchased ? (
                    <span className="purchased-label">購入済み</span>
                  ) : (
                    <span className="price-label">${magazine.price}</span>
                  )}
                  {isPhoto && magazine.purchase_count !== undefined && (
                    <span className="purchase-count-label">購入数: {magazine.purchase_count}</span>
                  )}
                  {isPhoto && (
                    <button
                      className="edit-button"
                      onClick={(e) => {
                        e.stopPropagation();
                        onEdit(magazine.id);
                      }}
                    >
                      編集
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default MagazineList;
