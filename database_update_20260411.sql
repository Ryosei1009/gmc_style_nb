-- Style N&B Database Update
-- Date: 2026-04-11
-- Purpose:
-- 1) Add public/private flag to magazines
-- 2) Add purchase password to magazines
-- 3) Add helper indexes for visibility and purchase checks

START TRANSACTION;

ALTER TABLE `style_magazines`
  ADD COLUMN IF NOT EXISTS `is_public` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '公開状態(1=公開,0=非公開)';

ALTER TABLE `style_magazines`
  ADD COLUMN IF NOT EXISTS `purchase_password` VARCHAR(100) NULL COMMENT '購入時に必要なパスワード';

-- Optional indexes for query performance
ALTER TABLE `style_magazines`
  ADD INDEX IF NOT EXISTS `idx_style_magazines_is_public` (`is_public`);

ALTER TABLE `style_purchased_magazines`
  ADD INDEX IF NOT EXISTS `idx_style_purchased_magazines_magazine_citizen` (`magazine_id`, `citizenid`);

COMMIT;

-- If your MySQL/MariaDB version does not support IF NOT EXISTS for ADD COLUMN/ADD INDEX,
-- run equivalent guarded checks using INFORMATION_SCHEMA before ALTER TABLE.
