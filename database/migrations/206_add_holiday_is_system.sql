-- 206_add_holiday_is_system.sql
-- holiday_config 增加 is_system 字段（区分系统预置/用户配置）
-- 幂等写法，可重复执行

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'holiday_config' AND COLUMN_NAME = 'is_system');
SET @sql := IF(@exist = 0, 'ALTER TABLE `holiday_config` ADD COLUMN `is_system` tinyint(1) DEFAULT 0 COMMENT ''0=用户配置 1=系统预置'' AFTER `year`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
