-- =====================================================
-- 045_exam_score_fix.sql 补 safety_exam_record.pass_score 列（幂等可重复执行）
-- 根因：042 建表未冗余 pass_score，导致成绩筛选 SQL 报 1054、合格判定恒真
-- =====================================================
SET @c = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_record' AND column_name='pass_score');
SET @s = IF(@c=0,
  'ALTER TABLE `safety_exam_record` ADD COLUMN `pass_score` int(11) NOT NULL DEFAULT 60 COMMENT ''及格分数(冗余自试卷)'' AFTER `paper_name`',
  'SET @s_skip = 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- 回填历史考试记录的及格分数（从试卷表冗余）
UPDATE `safety_exam_record` r
JOIN `safety_exam_paper` p ON r.`paper_id` = p.`id`
SET r.`pass_score` = p.`pass_score`;
