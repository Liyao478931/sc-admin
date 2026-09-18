-- 202_add_salary_standard_score_and_profile_position.sql
-- 1) salary_standard 增加工分单价字段（分/元）
-- 2) employee_profiles 增加岗位等级字段（position_level 关联 salary_standard.position_code）
-- 幂等写法，可重复执行

-- ========== 一、salary_standard 增加工分单价 ==========
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'salary_standard' AND COLUMN_NAME = 'score_price');
SET @sql := IF(@exist = 0, 'ALTER TABLE `salary_standard` ADD COLUMN `score_price` decimal(10,2) DEFAULT 0 COMMENT ''工分单价（分/元）'' AFTER `daily_assessment`', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========== 二、employee_profiles 增加岗位等级字段 ==========
SET @exist2 := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employee_profiles' AND COLUMN_NAME = 'position_level');
SET @sql2 := IF(@exist2 = 0, 'ALTER TABLE `employee_profiles` ADD COLUMN `position_level` varchar(20) DEFAULT NULL COMMENT ''岗位等级编码（关联salary_standard.position_code）'' AFTER `rank_id`', 'SELECT 1');
PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;
