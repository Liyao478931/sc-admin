-- =====================================================
-- 044_exam_score_complete.sql 成绩管理模块（幂等可重复执行）
-- 仅菜单（数据复用 exam_record/exam_answer；权限复用 safety:training:exam:*）
-- =====================================================
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'成绩管理','/safety/training/exam/score','el-icon-s-data','safety:training:exam:list',4,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:training:exam:list' AND m.`path`='/safety/training/exam' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:training:exam:list' AND x.`path`='/safety/training/exam/score' AND x.`deleted_at` IS NULL);
