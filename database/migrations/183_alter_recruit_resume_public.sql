-- 183_alter_recruit_resume_public.sql
-- 招聘投递 H5：recruit_resume 增加 2 列（期望薪资 / 自荐语），幂等可重复执行
-- 回滚 down：
--   ALTER TABLE recruit_resume DROP COLUMN expected_salary, DROP COLUMN self_introduction;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='recruit_resume' AND COLUMN_NAME='expected_salary');
SET @sql := IF(@cnt=0, 'ALTER TABLE `recruit_resume` ADD COLUMN `expected_salary` varchar(50) DEFAULT NULL COMMENT ''期望薪资（H5投递选填）'' AFTER `work_experience`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='recruit_resume' AND COLUMN_NAME='self_introduction');
SET @sql := IF(@cnt=0, 'ALTER TABLE `recruit_resume` ADD COLUMN `self_introduction` varchar(500) DEFAULT NULL COMMENT ''自荐语/备注（H5投递选填）'' AFTER `expected_salary`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
