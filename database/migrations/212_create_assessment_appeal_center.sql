-- 212_create_assessment_appeal_center.sql
-- 申诉处理中心（人事管理 -> 绩效考核 -> 申诉处理中心）
-- 仅新增权限 + 菜单，复用 assessment_appeals 表
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='assessment:appeal:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('assessment:appeal:export','assessment:appeal:statistics'));
--   DELETE FROM permissions WHERE code IN ('assessment:appeal:export','assessment:appeal:statistics');

-- ========== 权限（2 个，幂等） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '导出申诉记录','assessment:appeal:export',2,0,'hr',NULL,NULL,NULL,330,1,1,'导出申诉记录',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:appeal:export');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '查看申诉统计','assessment:appeal:statistics',2,0,'hr',NULL,NULL,NULL,331,1,1,'查看申诉统计',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:appeal:statistics');

INSERT INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` IN ('assessment:appeal:export','assessment:appeal:statistics')
AND NOT EXISTS (SELECT 1 FROM `role_permissions` rp WHERE rp.role_id=r.`id` AND rp.permission_id=p.`id`);

-- ========== 菜单链：绩效考核目录 -> 申诉处理中心（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:assessment' AND deleted_at IS NULL LIMIT 1), '申诉处理中心', '/hr/assessment/appeal', 'el-icon-message', 'assessment:appeal:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='assessment:appeal:view' AND deleted_at IS NULL);
