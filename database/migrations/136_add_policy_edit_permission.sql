-- 136_add_policy_edit_permission.sql
-- 更新策略配置：新增编辑权限 settings:version:policy:edit
-- 查看权限 settings:version:policy:view 已于 135 创建
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='settings:version:policy:edit');
--   DELETE FROM permissions WHERE code='settings:version:policy:edit';

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('更新策略编辑','settings:version:policy:edit',2,0,'version',NULL,NULL,NULL,18,1,1,'编辑保存版本更新策略配置',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='settings:version:policy:edit';
