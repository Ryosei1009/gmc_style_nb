-- Style N&B Magazine Database Schema
-- FiveM QBCore Photo Magazine App

-- 雑誌マスタテーブル
CREATE TABLE IF NOT EXISTS `style_magazines` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(100) NOT NULL COMMENT '雑誌タイトル',
  `description` TEXT COMMENT '雑誌説明文',
  `cover_image` VARCHAR(500) NOT NULL COMMENT '表紙画像URL',
  `price` INT NOT NULL DEFAULT 0 COMMENT '販売価格',
  `is_public` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '公開状態(1=公開,0=非公開)',
  `purchase_password` VARCHAR(100) NULL COMMENT '購入時に必要なパスワード',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 雑誌写真テーブル
CREATE TABLE IF NOT EXISTS `style_magazine_photos` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `magazine_id` INT NOT NULL COMMENT '雑誌ID',
  `image_url` VARCHAR(500) NOT NULL COMMENT '画像URL',
  `caption` VARCHAR(200) COMMENT 'キャプション/説明文',
  `page_order` INT NOT NULL DEFAULT 0 COMMENT '表示順序',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`magazine_id`) REFERENCES `style_magazines`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 購入記録テーブル
CREATE TABLE IF NOT EXISTS `style_purchased_magazines` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `magazine_id` INT NOT NULL COMMENT '雑誌ID',
  `citizenid` VARCHAR(50) NOT NULL COMMENT '市民ID',
  `purchased_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`magazine_id`) REFERENCES `style_magazines`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `unique_purchase` (`magazine_id`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
