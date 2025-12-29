import React, { useState, useEffect } from 'react';
import './App.css';
import MagazineList from './components/MagazineList';
import MagazineViewer from './components/MagazineViewer';
import Editor from './components/Editor';
import PurchaseDialog from './components/PurchaseDialog';

const devMode = !window.invokeNative;

function App() {
  // 画面状態管理
  const [screen, setScreen] = useState('list'); // list | viewer | editor | purchase
  const [magazines, setMagazines] = useState([]);
  const [selectedMagazine, setSelectedMagazine] = useState(null);
  const [isPhoto, setIsPhoto] = useState(false);
  const [editingMagazine, setEditingMagazine] = useState(null); // null = 新規作成

  useEffect(() => {
  }, []);

  useEffect(() => {
    if (devMode) {
      // 開発モードでは表示を有効化
      document.body.style.display = 'block';
      setIsPhoto(true);
    }

    fetchMagazines();
    fetchPlayerJob();
    const handleMessage = (e) => {
      if (e.data === 'componentsLoaded') {
        document.body.style.display = 'block';
      }
    };

    window.addEventListener('message', handleMessage);

    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // 雑誌一覧取得
  const fetchMagazines = async () => {
    try {
      if (devMode) {
        // デバッグ用ダミーデータ
        setMagazines([
          { id: 1, title: "Street Snap Vol.1", description: "街角の素敵なスナップ写真集", cover_image: "https://picsum.photos/300/400?random=1", price: 500, purchased: "YC12345" },
          { id: 2, title: "Gravition Collection", description: "グラビアフォトブック", cover_image: "https://picsum.photos/300/400?random=2", price: 1000, purchased: "" },
          { id: 3, title: "Car Life", description: "愛車のフォトブック", cover_image: "https://picsum.photos/300/400?random=3", price: 800, purchased: "" },
        ]);
      } else {
        const response = await fetch('https://gmc_style_nb/getMagazines', { method: 'POST' });
        const result = await response.json();
        if (result.success) {
          setMagazines(result.magazines);
        }
      }
    } catch (error) {
      console.error('Fetch error:', error);
    }
  };

  // プレイヤージョブ取得
  const fetchPlayerJob = async () => {
    try {
      if (!devMode) {
        const response = await fetch('https://gmc_style_nb/getPlayerJob', { method: 'POST' });
        const result = await response.json();
        if (result.job === 'photo') {
          setIsPhoto(true);
        }
      }
    } catch (error) {
      console.error('Error fetching player job:', error);
    }
  };

  // 雑誌をタップ（購入済みなら閲覧、未購入なら購入ダイアログ）
  const handleMagazineClick = (magazine) => {
    setSelectedMagazine(magazine);
    if (magazine.purchased || isPhoto) {
      openViewer(magazine.id);
    } else {
      setScreen('purchase');
    }
  };

  // 閲覧画面を開く
  const openViewer = async (magazineId) => {
    try {
      if (devMode) {
        // デバッグ用
        setScreen('viewer');
      } else {
        const response = await fetch('https://gmc_style_nb/getMagazineDetail', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: magazineId })
        });
        const result = await response.json();
        if (result.success && result.magazine) {
          setSelectedMagazine(result.magazine);
          setScreen('viewer');
        }
      }
    } catch (error) {
      console.error('Error fetching magazine detail:', error);
    }
  };

  // 新規作成画面を開く
  const handleCreateNew = () => {
    setEditingMagazine(null);
    setScreen('editor');
  };

  // 編集画面を開く
  const handleEdit = (magazineId) => {
    openEditor(magazineId);
  };

  // 編集画面を開く（詳細取得付き）
  const openEditor = async (magazineId) => {
    try {
      if (devMode) {
        setEditingMagazine({ id: magazineId, title: 'Test', photos: [] });
        setScreen('editor');
      } else {
        const response = await fetch('https://gmc_style_nb/getMagazineDetail', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: magazineId })
        });
        const result = await response.json();
        if (result.success && result.magazine) {
          setEditingMagazine(result.magazine);
          setScreen('editor');
        }
      }
    } catch (error) {
      console.error('Error fetching magazine for edit:', error);
    }
  };

  // 一覧に戻る
  const handleBackToList = () => {
    setScreen('list');
    setSelectedMagazine(null);
    setEditingMagazine(null);
    fetchMagazines();
  };

  // 購入完了後閲覧画面へ
  const handlePurchaseComplete = () => {
    setScreen('viewer');
    openViewer(selectedMagazine.id);
  };

  return (
    <div className="app-container mt-12 p-4">
      {/* ヘッダー */}
      <header className="app-header pt-12">
        <div className="header-content">
          <h1 className="app-title">Style N&B</h1>
          {isPhoto && screen === 'list' && (
            <button className="header-button" onClick={handleCreateNew}>
              <span className="plus-icon">+</span> 新規作成
            </button>
          )}
        </div>
      </header>

      {/* メインコンテンツ */}
      <main className="app-main">
        {screen === 'list' && (
          <MagazineList
            magazines={magazines}
            onMagazineClick={handleMagazineClick}
            onEdit={handleEdit}
            isPhoto={isPhoto}
          />
        )}

        {screen === 'viewer' && selectedMagazine && (
          <MagazineViewer
            magazine={selectedMagazine}
            onBack={handleBackToList}
            onEdit={handleEdit}
            isPhoto={isPhoto}
          />
        )}

        {screen === 'editor' && (
          <Editor
            magazine={editingMagazine}
            onSave={() => {
              handleBackToList();
            }}
            onCancel={handleBackToList}
          />
        )}

        {screen === 'purchase' && selectedMagazine && (
          <PurchaseDialog
            magazine={selectedMagazine}
            onConfirm={handlePurchaseComplete}
            onCancel={handleBackToList}
          />
        )}
      </main>
    </div>
  );
}

export default App;
