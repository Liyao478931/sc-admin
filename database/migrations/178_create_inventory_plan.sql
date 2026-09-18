-- 178_create_inventory_plan.sql
-- 仓储管理「库存盘点 - 盘点计划」：3 表 + 7 权限 + 2 菜单 + 统一审批流程
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/warehouse/check/plan' OR permission='warehouse:check:plan:module';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:check:plan:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:check:plan:%';
--   DELETE FROM approval_flow WHERE biz_type='inventory_plan';
--   DROP TABLE IF EXISTS inventory_result;
--   DROP TABLE IF EXISTS inventory_task;
--   DROP TABLE IF EXISTS inventory_plan;

-- ========== 一、盘点计划表 ==========
CREATE TABLE IF NOT EXISTS `inventory_plan` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_no` varchar(50) NOT NULL DEFAULT '' COMMENT '计划编号 PD+YYYYMMDD+4位流水',
  `plan_name` varchar(100) NOT NULL DEFAULT '' COMMENT '计划名称',
  `plan_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '盘点类型：1全盘 2抽盘 3循环盘点',
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '盘点仓库ID',
  `warehouse_name` varchar(50) NOT NULL DEFAULT '' COMMENT '仓库名称（冗余）',
  `scope_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '范围类型：1全仓 2按货位 3按物料分类 4按物料',
  `scope_value` varchar(500) DEFAULT NULL COMMENT '范围值 JSON（货位/分类/物料ID列表）',
  `inventory_method` tinyint(1) NOT NULL DEFAULT 1 COMMENT '盘点方式：1明盘 2暗盘',
  `plan_start_date` date DEFAULT NULL COMMENT '计划开始日期',
  `plan_end_date` date DEFAULT NULL COMMENT '计划结束日期',
  `expected_duration` decimal(6,1) NOT NULL DEFAULT 1.0 COMMENT '预计耗时（小时）',
  `responsible_person_id` int(11) NOT NULL DEFAULT 0 COMMENT '负责人ID',
  `responsible_person_name` varchar(50) NOT NULL DEFAULT '' COMMENT '负责人姓名',
  `participants` json DEFAULT NULL COMMENT '参与人员ID列表',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '计划状态：0草稿 1待审核 2已审核 3执行中 4已完成 5已取消',
  `approval_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审批状态：0未提交 1待审批 2已通过 3已驳回',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `actual_start_time` datetime DEFAULT NULL COMMENT '实际开始时间',
  `actual_end_time` datetime DEFAULT NULL COMMENT '实际结束时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_no` (`plan_no`),
  KEY `idx_status` (`status`),
  KEY `idx_warehouse` (`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='盘点计划表';

-- ========== 二、盘点任务表 ==========
CREATE TABLE IF NOT EXISTS `inventory_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_no` varchar(50) NOT NULL DEFAULT '' COMMENT '任务编号',
  `plan_id` int(11) NOT NULL DEFAULT 0 COMMENT '盘点计划ID',
  `plan_no` varchar(50) NOT NULL DEFAULT '' COMMENT '计划编号（冗余）',
  `assignee_id` int(11) NOT NULL DEFAULT 0 COMMENT '被分配人ID',
  `assignee_name` varchar(50) NOT NULL DEFAULT '' COMMENT '被分配人姓名',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '货位ID',
  `location_name` varchar(100) NOT NULL DEFAULT '' COMMENT '货位名称',
  `material_ids` json DEFAULT NULL COMMENT '物料ID列表',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '任务状态：0待执行 1执行中 2已完成 3已逾期',
  `expected_start_time` datetime DEFAULT NULL COMMENT '预计开始时间',
  `expected_end_time` datetime DEFAULT NULL COMMENT '预计结束时间',
  `actual_start_time` datetime DEFAULT NULL COMMENT '实际开始时间',
  `actual_end_time` datetime DEFAULT NULL COMMENT '实际结束时间',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_plan` (`plan_id`),
  KEY `idx_assignee` (`assignee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='盘点任务表';

-- ========== 三、盘点结果表 ==========
CREATE TABLE IF NOT EXISTS `inventory_result` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` int(11) NOT NULL DEFAULT 0 COMMENT '盘点计划ID',
  `task_id` int(11) NOT NULL DEFAULT 0 COMMENT '盘点任务ID',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID',
  `material_code` varchar(50) NOT NULL DEFAULT '' COMMENT '物料编码（冗余）',
  `material_name` varchar(100) NOT NULL DEFAULT '' COMMENT '物料名称（冗余）',
  `specification` varchar(100) DEFAULT NULL COMMENT '规格型号（冗余）',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位（冗余）',
  `system_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '系统账面库存数量',
  `actual_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '实际盘点数量',
  `difference_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '差异数量',
  `difference_type` tinyint(1) NOT NULL DEFAULT 3 COMMENT '差异类型：1盘盈 2盘亏 3无差异',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '货位ID',
  `location_name` varchar(100) DEFAULT NULL COMMENT '货位名称（冗余）',
  `batch_no` varchar(50) DEFAULT NULL COMMENT '批次号',
  `scanned_by` int(11) NOT NULL DEFAULT 0 COMMENT '扫码人ID',
  `scanned_at` datetime DEFAULT NULL COMMENT '扫码时间',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '结果状态：0待确认 1已确认 2已调整',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_plan` (`plan_id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_material` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='盘点结果表';

-- ========== 四、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('库存盘点','warehouse:check:plan:module',1,0,'warehouse',NULL,'el-icon-menu',NULL,46,1,1,'库存盘点（目录）',NOW(),NOW()),
('盘点计划','warehouse:check:plan:view',2,0,'warehouse','/warehouse/check/plan','el-icon-notebook-2',NULL,50,1,1,'盘点计划-查看（菜单）',NOW(),NOW()),
('新增盘点计划','warehouse:check:plan:add',2,0,'warehouse',NULL,NULL,NULL,51,1,1,'新增盘点计划',NOW(),NOW()),
('编辑盘点计划','warehouse:check:plan:edit',2,0,'warehouse',NULL,NULL,NULL,52,1,1,'编辑盘点计划',NOW(),NOW()),
('删除盘点计划','warehouse:check:plan:delete',2,0,'warehouse',NULL,NULL,NULL,53,1,1,'删除盘点计划',NOW(),NOW()),
('审核盘点计划','warehouse:check:plan:audit',2,0,'warehouse',NULL,NULL,NULL,54,1,1,'审核盘点计划（统一审批）',NOW(),NOW()),
('执行盘点计划','warehouse:check:plan:execute',2,0,'warehouse',NULL,NULL,NULL,55,1,1,'执行/完成盘点计划',NOW(),NOW()),
('导出盘点计划','warehouse:check:plan:export',2,0,'warehouse',NULL,NULL,NULL,56,1,1,'导出盘点计划',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'warehouse:check:plan:%';

-- ========== 五、菜单（仓储管理 -> 库存盘点（目录） -> 盘点计划（叶子）） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL LIMIT 1), '库存盘点', NULL, 'el-icon-menu', 'warehouse:check:plan:module', 60, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:check:plan:module' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:check:plan:module' AND deleted_at IS NULL LIMIT 1), '盘点计划', '/warehouse/check/plan', 'el-icon-notebook-2', 'warehouse:check:plan:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/warehouse/check/plan' AND deleted_at IS NULL);

-- ========== 六、统一审批流程（inventory_plan） ==========
INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`module_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('inventory_plan', '盘点计划', '仓储管理', 1, 48, '[{"node_name":"仓管经理审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管经理","timeout_hours":48,"timeout_action":"remind"}]', 1, '盘点计划审批', NOW(), NOW());
