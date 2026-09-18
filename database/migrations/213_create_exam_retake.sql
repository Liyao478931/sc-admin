-- 213_create_exam_retake.sql
-- 考试补考功能：safety_exam_record 加补考次数；safety_exam_answer 加考试次数
-- 幂等写法，可重复执行
-- 回滚 down：
--   ALTER TABLE safety_exam_answer DROP COLUMN attempt;
--   ALTER TABLE safety_exam_record DROP COLUMN retake_limit;

-- safety_exam_record：允许补考次数（0=不允许）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'safety_exam_record' AND COLUMN_NAME = 'retake_limit');
SET @ddl = IF(@col_exists = 0,
  'ALTER TABLE `safety_exam_record` ADD COLUMN `retake_limit` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''允许补考次数(0=不允许)'' AFTER `pass_score`',
  'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- safety_exam_answer：考试次数（1=首次，2=第1次补考...）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'safety_exam_answer' AND COLUMN_NAME = 'attempt');
SET @ddl = IF(@col_exists = 0,
  'ALTER TABLE `safety_exam_answer` ADD COLUMN `attempt` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''考试次数(1=首次,2=第1次补考)'' AFTER `is_pass`',
  'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
