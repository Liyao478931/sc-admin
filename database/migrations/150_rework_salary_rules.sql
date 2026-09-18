-- 150_rework_salary_rules.sql
-- 工资配置/计算按新规则重构：hr_rank.employee_type + hr_salary_config.rank_id/employee_type + 权限/菜单
-- 核心规则：科员无工分、工资按职级配置、计算区分车间岗位工/科员
-- 说明：hr_rank.employee_type、hr_salary_config.rank_id/rank_name/employee_type 列由执行器（信息架构检查）幂等添加
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:salary:config:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:salary:config:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:salary:config:%';

-- ========== 一、权限（hr:salary:config:* 4 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工资配置','hr:salary:config:view',2,0,'hr','/hr/salary/config','el-icon-set-up',NULL,191,1,1,'工资配置-查看（菜单）',NOW(),NOW()),
('工资配置新增','hr:salary:config:add',2,0,'hr',NULL,NULL,NULL,192,1,1,'新增工资配置',NOW(),NOW()),
('工资配置编辑','hr:salary:config:edit',2,0,'hr',NULL,NULL,NULL,193,1,1,'编辑工资配置',NOW(),NOW()),
('工资配置删除','hr:salary:config:delete',2,0,'hr',NULL,NULL,NULL,194,1,1,'删除工资配置',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'hr:salary:config:%';

-- ========== 二、菜单：薪酬管理（hr:salary）-> 工资配置（独立） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21 LIMIT 1), '工资配置', '/hr/salary/config', 'el-icon-set-up', 'hr:salary:config:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:config:view' AND deleted_at IS NULL);
