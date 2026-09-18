-- 151_create_hr_salary_slip.sql
-- 生成工资条（人事管理 -> 薪酬管理 -> 工资条 -> 生成工资条）：1 表 + 4 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('hr:salary:slip:generate:view','hr:salary:slip');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:salary:slip:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:salary:slip:%';
--   DROP TABLE IF EXISTS hr_salary_slip;

-- ========== 一、工资条表 ==========
CREATE TABLE IF NOT EXISTS `hr_salary_slip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `slip_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工资条编号 SL+YYYYMMDD+4位流水',
  `calc_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工资计算主表ID',
  `calc_month` varchar(7) NOT NULL DEFAULT '' COMMENT '工资月份 YYYY-MM',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '员工ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '员工姓名',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '部门名称',
  `rank_id` int(11) NOT NULL DEFAULT 0 COMMENT '职级ID',
  `rank_name` varchar(50) NOT NULL DEFAULT '' COMMENT '职级名称',
  `employee_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '员工类型：1车间岗位工 2科员',
  `base_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '基本工资',
  `piecework_score` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '工分（仅车间岗位工）',
  `piecework_price` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工分单价（仅车间岗位工）',
  `piecework_wage` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '计件工资（仅车间岗位工）',
  `allowance_json` json DEFAULT NULL COMMENT '津贴明细JSON',
  `allowance_total` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '津贴合计',
  `deduction_json` json DEFAULT NULL COMMENT '扣款明细JSON',
  `deduction_total` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '扣款合计',
  `gross_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '应发工资',
  `net_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '实发工资',
  `slip_data` json DEFAULT NULL COMMENT '工资条完整数据快照',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1已生成 2已发送 3已签收',
  `generated_at` datetime DEFAULT NULL COMMENT '生成时间',
  `sent_at` datetime DEFAULT NULL COMMENT '发送时间',
  `signed_at` datetime DEFAULT NULL COMMENT '签收时间',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_month` (`calc_month`,`user_id`),
  KEY `idx_calc_id` (`calc_id`),
  KEY `idx_status` (`status`),
  KEY `idx_department` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资条表';

-- ========== 二、权限（4 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('生成工资条','hr:salary:slip:generate:view',2,0,'hr','/hr/salary/slip/generate','el-icon-tickets',NULL,195,1,1,'生成工资条-查看（菜单）',NOW(),NOW()),
('生成工资条操作','hr:salary:slip:generate',2,0,'hr',NULL,NULL,NULL,196,1,1,'生成工资条（批量/单个/重新生成）',NOW(),NOW()),
('工资条发送通知','hr:salary:slip:send',2,0,'hr',NULL,NULL,NULL,197,1,1,'发送工资条通知',NOW(),NOW()),
('工资条查看','hr:salary:slip:view',2,0,'hr',NULL,NULL,NULL,198,1,1,'查看工资条（预览/移动端）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- 超管/管理员：全部工资条权限；员工角色：仅查看（移动端）
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'hr:salary:slip:%';

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('employee') AND p.`code` IN ('hr:salary:slip:view');

-- ========== 三、菜单链：薪酬管理（hr:salary）-> 工资条（目录）-> 生成工资条 ==========
-- 工资条目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21 LIMIT 1), '工资条', '', 'el-icon-tickets', 'hr:salary:slip', 40, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:slip' AND deleted_at IS NULL);

-- 生成工资条（叶子）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary:slip' AND deleted_at IS NULL LIMIT 1), '生成工资条', '/hr/salary/slip/generate', 'el-icon-tickets', 'hr:salary:slip:generate:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:slip:generate:view' AND deleted_at IS NULL);
