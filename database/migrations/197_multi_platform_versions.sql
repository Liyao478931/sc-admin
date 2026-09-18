-- 197_multi_platform_versions.sql
-- v1.69.0 多端版本管理：ALTER system_versions + version_publish_logs + platform_active_versions + 数据迁移

-- 第一步：扩展 system_versions（幂等：检查列不存在才加）
SET @has_platform := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'platform');
SET @sql := IF(@has_platform = 0, 'ALTER TABLE `system_versions` ADD COLUMN `platform` varchar(20) NOT NULL DEFAULT ''admin'' COMMENT ''平台：admin/h5/miniprogram/api'' AFTER `id`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_pn := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'platform_name');
SET @sql := IF(@has_pn = 0, 'ALTER TABLE `system_versions` ADD COLUMN `platform_name` varchar(50) DEFAULT NULL COMMENT ''平台显示名称'' AFTER `platform`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_bu := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'build_url');
SET @sql := IF(@has_bu = 0, 'ALTER TABLE `system_versions` ADD COLUMN `build_url` varchar(255) DEFAULT NULL COMMENT ''构建产物地址'' AFTER `release_note`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_bh := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'build_hash');
SET @sql := IF(@has_bh = 0, 'ALTER TABLE `system_versions` ADD COLUMN `build_hash` varchar(40) DEFAULT NULL COMMENT ''Git commit hash'' AFTER `build_url`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fs := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'file_size');
SET @sql := IF(@has_fs = 0, 'ALTER TABLE `system_versions` ADD COLUMN `file_size` bigint DEFAULT NULL COMMENT ''产物大小（字节）'' AFTER `build_hash`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_gr := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'gray_ratio');
SET @sql := IF(@has_gr = 0, 'ALTER TABLE `system_versions` ADD COLUMN `gray_ratio` int(11) DEFAULT 0 COMMENT ''灰度比例 0-100'' AFTER `status`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_ms := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'min_supported_version');
SET @sql := IF(@has_ms = 0, 'ALTER TABLE `system_versions` ADD COLUMN `min_supported_version` varchar(20) DEFAULT NULL COMMENT ''最低兼容版本'' AFTER `gray_ratio`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_fu := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND COLUMN_NAME = 'is_force_update');
SET @sql := IF(@has_fu = 0, 'ALTER TABLE `system_versions` ADD COLUMN `is_force_update` tinyint(1) DEFAULT 0 COMMENT ''是否强制更新'' AFTER `min_supported_version`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_pi := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'system_versions' AND INDEX_NAME = 'idx_platform');
SET @sql := IF(@has_pi = 0, 'ALTER TABLE `system_versions` ADD INDEX `idx_platform` (`platform`)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 第二步：发布日志表
CREATE TABLE IF NOT EXISTS `version_publish_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `version_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联版本ID',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '平台标识',
  `action` varchar(20) NOT NULL DEFAULT '' COMMENT 'publish/gray/rollback/delete',
  `before_status` tinyint(1) DEFAULT NULL,
  `after_status` tinyint(1) DEFAULT NULL,
  `gray_ratio_before` int(11) DEFAULT NULL,
  `gray_ratio_after` int(11) DEFAULT NULL,
  `operator_id` int(11) NOT NULL DEFAULT 0,
  `operator_name` varchar(50) DEFAULT '' COMMENT '操作人',
  `remark` varchar(255) DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_version_id` (`version_id`),
  KEY `idx_platform` (`platform`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='版本发布操作日志表';

-- 第三步：各端当前生效版本表
CREATE TABLE IF NOT EXISTS `platform_active_versions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '平台标识',
  `version_id` int(11) NOT NULL DEFAULT 0 COMMENT '当前生效版本ID',
  `version_code` varchar(20) NOT NULL DEFAULT '' COMMENT '版本号',
  `gray_ratio` int(11) NOT NULL DEFAULT 100 COMMENT '当前灰度比例',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_platform` (`platform`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='各端当前生效版本表';

-- 第四步：数据迁移（现有版本 → admin 平台）
UPDATE `system_versions` SET `platform` = 'admin', `platform_name` = 'PC管理端' WHERE `platform` = 'admin' OR `platform` = '';

-- 初始化 admin 当前生效版本（is_current=1 的最新版本）
INSERT INTO `platform_active_versions` (`platform`, `version_id`, `version_code`, `gray_ratio`, `update_time`)
SELECT 'admin', id, version_no, 100, NOW()
FROM `system_versions`
WHERE `platform` = 'admin' AND `is_current` = 1
ORDER BY `id` DESC LIMIT 1
ON DUPLICATE KEY UPDATE `version_id` = VALUES(`version_id`), `version_code` = VALUES(`version_code`), `gray_ratio` = 100;
