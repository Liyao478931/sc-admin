-- =====================================================
-- 091_security_policy_password.sql
-- 安全策略 → 密码策略完整生效所需结构：
--   1. users 表增加 password_changed_at（最近一次密码修改时间，空=未自行改密）
--   2. user_password_histories 表（密码历史，用于 password_history_count）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、users 增加密码修改时间字段 ==========
SET @has_col = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'password_changed_at');
SET @ddl = IF(@has_col = 0,
  'ALTER TABLE `users` ADD COLUMN `password_changed_at` datetime DEFAULT NULL COMMENT ''最近一次密码修改时间（空=未自行修改）'' AFTER `last_login_ip`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========== 二、密码历史表 ==========
CREATE TABLE IF NOT EXISTS `user_password_histories` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT 0 COMMENT '用户ID',
  `password_hash` varchar(255) NOT NULL DEFAULT '' COMMENT '历史密码哈希',
  `created_at` datetime DEFAULT NULL COMMENT '记录时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户密码历史表（安全策略-密码历史限制）';
