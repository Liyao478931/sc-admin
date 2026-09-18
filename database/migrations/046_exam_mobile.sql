-- =====================================================
-- 046_exam_mobile.sql 员工端在线考试：应用路径 + 功能菜单（幂等可重复执行）
-- =====================================================
-- 1. 应用路径管理（app_paths）
INSERT INTO `app_paths` (`name`,`path`,`page_key`,`platform`,`page_type`,`require_auth`,`status`,`created_at`,`updated_at`) VALUES
('我的考试','/pages/sub/safety/my-exams','safety-my-exams',0,2,1,1,NOW(),NOW()),
('考试详情','/pages/sub/safety/exam-detail','safety-exam-detail',0,2,1,1,NOW(),NOW()),
('在线考试','/pages/sub/safety/exam-do','safety-exam-do',0,2,1,1,NOW(),NOW()),
('考试成绩','/pages/sub/safety/exam-result','safety-exam-result',0,2,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();

-- 2. 员工端功能菜单：在线考试
INSERT INTO `app_functions` (`name`,`code`,`icon`,`path_id`,`permission`,`sort`,`status`,`created_at`,`updated_at`)
SELECT '在线考试','my_exams','el-icon-edit',
       (SELECT id FROM `app_paths` WHERE `path`='/pages/sub/safety/my-exams' AND `deleted_at` IS NULL),
       '',50,1,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `app_functions` WHERE `code`='my_exams');
