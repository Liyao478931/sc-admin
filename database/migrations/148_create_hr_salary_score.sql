-- 148_create_hr_salary_score.sql
-- 工分汇总（人事管理 -> 薪酬管理 -> 工资核算 -> 工分汇总）：报工基础表 + 2 权限 + 菜单链
-- 说明：hr_rank.score_price、users.rank_id 字段由执行器（信息架构检查）幂等添加
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('hr:salary:score:view','hr:salary:calculate','hr:salary');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:salary:score:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:salary:score:%';
--   DROP TABLE IF EXISTS work_report;

-- ========== 一、报工记录表 ==========
CREATE TABLE IF NOT EXISTS `work_report` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '报工人ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '报工人姓名（冗余）',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '部门名称（冗余）',
  `report_date` date DEFAULT NULL COMMENT '报工日期',
  `task_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '任务类型：1拆解 2焊接 3组装 4喷漆 5质检 6其他',
  `task_desc` varchar(500) DEFAULT NULL COMMENT '任务描述',
  `score` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '报工工分',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审核状态：1待审核 2已通过 3已驳回',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `auditor_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审核人姓名（冗余）',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_report_date` (`report_date`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报工记录表';

-- ========== 二、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工分汇总','hr:salary:score:view',2,0,'hr','/hr/salary/calculate/score','el-icon-star-on',NULL,181,1,1,'工分汇总-查看（菜单）',NOW(),NOW()),
('工分汇总导出','hr:salary:score:export',2,0,'hr',NULL,NULL,NULL,182,1,1,'导出工分汇总报表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin','employee') AND p.`code` LIKE 'hr:salary:score:%';

-- ========== 三、菜单链：人事管理(21) -> 薪酬管理 -> 工资核算 -> 工分汇总 ==========
-- 薪酬管理目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 21, '薪酬管理', '', 'el-icon-money', 'hr:salary', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21);

-- 工资核算目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21 LIMIT 1), '工资核算', '', 'el-icon-calculator', 'hr:salary:calculate', 10, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:calculate' AND deleted_at IS NULL);

-- 工分汇总（叶子）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary:calculate' AND deleted_at IS NULL LIMIT 1), '工分汇总', '/hr/salary/calculate/score', 'el-icon-star-on', 'hr:salary:score:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:score:view' AND deleted_at IS NULL);
