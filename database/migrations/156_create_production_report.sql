-- 156_create_production_report.sql
-- 生产报工（生产管理 -> 生产执行 -> 生产报工）：3 表 + 6 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('production:report:view','production:execute');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'production:report:%');
--   DELETE FROM permissions WHERE code LIKE 'production:report:%';
--   DROP TABLE IF EXISTS production_report_log;
--   DROP TABLE IF EXISTS production_report_item;
--   DROP TABLE IF EXISTS production_report;

-- ========== 一、报工主表 ==========
CREATE TABLE IF NOT EXISTS `production_report` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `report_no` varchar(50) NOT NULL DEFAULT '' COMMENT '报工单编号 PR+YYYYMMDD+4位流水',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单ID',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号（冗余）',
  `report_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '报工模式：1个人报工 2团队协作',
  `task_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '任务类型：1拆解 2焊接 3维修 4组装 5喷漆 6质检 7其他',
  `task_description` varchar(500) DEFAULT NULL COMMENT '任务描述',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '部门ID',
  `department_name` varchar(50) NOT NULL DEFAULT '' COMMENT '部门名称（冗余）',
  `reporter_id` int(11) NOT NULL DEFAULT 0 COMMENT '报工人ID',
  `reporter_name` varchar(50) NOT NULL DEFAULT '' COMMENT '报工人姓名（冗余）',
  `report_date` date DEFAULT NULL COMMENT '报工日期',
  `total_score` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '总工分数',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审核 2已通过 3已驳回 4已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `auditor_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审核人姓名（冗余）',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_no` (`report_no`),
  KEY `idx_work_order_id` (`work_order_id`),
  KEY `idx_status` (`status`),
  KEY `idx_report_date` (`report_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='生产报工主表';

-- ========== 二、报工明细/分配表 ==========
CREATE TABLE IF NOT EXISTS `production_report_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `report_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联报工主表ID',
  `worker_id` int(11) NOT NULL DEFAULT 0 COMMENT '工人ID',
  `worker_name` varchar(50) NOT NULL DEFAULT '' COMMENT '工人姓名（冗余）',
  `allocated_score` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '分配工分数',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报工分配明细表';

-- ========== 三、报工审核日志表 ==========
CREATE TABLE IF NOT EXISTS `production_report_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `report_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联报工主表ID',
  `action` tinyint(1) NOT NULL DEFAULT 1 COMMENT '操作类型：1提交 2审核通过 3审核驳回 4撤销',
  `action_label` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `before_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作前状态',
  `after_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作后状态',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报工审核日志表';

-- ========== 四、权限（6 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('生产报工','production:report:view',2,0,'production','/production/report/list','el-icon-edit-outline',NULL,220,1,1,'生产报工-查看（菜单）',NOW(),NOW()),
('新增报工','production:report:add',2,0,'production',NULL,NULL,NULL,221,1,1,'新增报工',NOW(),NOW()),
('编辑报工','production:report:edit',2,0,'production',NULL,NULL,NULL,222,1,1,'编辑报工',NOW(),NOW()),
('删除报工','production:report:delete',2,0,'production',NULL,NULL,NULL,223,1,1,'删除报工',NOW(),NOW()),
('报工审核','production:report:audit',2,0,'production',NULL,NULL,NULL,224,1,1,'报工审核（通过/驳回）',NOW(),NOW()),
('导出报工','production:report:export',2,0,'production',NULL,NULL,NULL,225,1,1,'导出报工列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'production:report:%';

-- ========== 五、菜单链：生产管理 -> 生产执行 -> 生产报工 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:view' AND deleted_at IS NULL LIMIT 1), '生产执行', '', 'el-icon-cpu', 'production:execute', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:execute' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:execute' AND deleted_at IS NULL LIMIT 1), '生产报工', '/production/report/list', 'el-icon-edit-outline', 'production:report:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:report:view' AND deleted_at IS NULL);
