-- 205_add_holiday_work_type.sql
-- 节假日配置增加工作日类型（周末调休工作日配置）
-- work_type: 0=默认(按星期) 1=工作日 2=休息日 3=法定节假日
-- 幂等写法，可重复执行

-- ========== 一、holiday_config 增加 work_type 字段 ==========
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'holiday_config' AND COLUMN_NAME = 'work_type');
SET @sql := IF(@exist = 0, 'ALTER TABLE `holiday_config` ADD COLUMN `work_type` tinyint(1) DEFAULT 0 COMMENT ''0=默认(按星期) 1=工作日 2=休息日 3=法定节假日'' AFTER `holiday_type`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ========== 二、历史数据迁移 ==========
-- 已有的法定节假日（holiday_type=1）→ work_type=3
UPDATE `holiday_config` SET `work_type` = 3 WHERE `holiday_type` = 1 AND `work_type` = 0;
-- 已有的调休日（holiday_type=2）→ work_type=2
UPDATE `holiday_config` SET `work_type` = 2 WHERE `holiday_type` = 2 AND `work_type` = 0;
