-- 181_create_employee_transfer.sql
-- 人事管理「员工异动」：2 表 + 6 权限 + 2 菜单 + 统一审批流程
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:transfer:view' OR (name='员工异动' AND parent_id=21);
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:transfer:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:transfer:%';
--   DELETE FROM approval_flow WHERE biz_type='employee_transfer';
--   DROP TABLE IF EXISTS employee_transfer_attachment;
--   DROP TABLE IF EXISTS employee_transfer;

-- ========== 一、员工异动主表 ==========
CREATE TABLE IF NOT EXISTS `employee_transfer` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `transfer_no` varchar(50) NOT NULL DEFAULT '' COMMENT '异动编号 TR+YYYYMMDD+4位流水',
  `employee_id` int(11) NOT NULL DEFAULT 0 COMMENT '员工ID（employee_profiles.id）',
  `employee_name` varchar(50) NOT NULL DEFAULT '' COMMENT '员工姓名（冗余）',
  `employee_no` varchar(50) NOT NULL DEFAULT '' COMMENT '员工工号（冗余）',
  `transfer_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '异动类型：1转正 2调岗 3晋升 4降职 5离职 6复职',
  `transfer_type_label` varchar(20) NOT NULL DEFAULT '' COMMENT '异动类型标签',
  `before_department_id` int(11) NOT NULL DEFAULT 0 COMMENT '原部门ID',
  `before_department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '原部门名称',
  `before_position_id` int(11) NOT NULL DEFAULT 0 COMMENT '原岗位ID',
  `before_position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '原岗位名称',
  `before_rank_id` int(11) NOT NULL DEFAULT 0 COMMENT '原职级ID',
  `before_rank_name` varchar(50) NOT NULL DEFAULT '' COMMENT '原职级名称',
  `before_salary` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '原薪资（元/月）',
  `after_department_id` int(11) NOT NULL DEFAULT 0 COMMENT '新部门ID',
  `after_department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '新部门名称',
  `after_position_id` int(11) NOT NULL DEFAULT 0 COMMENT '新岗位ID',
  `after_position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '新岗位名称',
  `after_rank_id` int(11) NOT NULL DEFAULT 0 COMMENT '新职级ID',
  `after_rank_name` varchar(50) NOT NULL DEFAULT '' COMMENT '新职级名称',
  `after_salary` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '新薪资（元/月）',
  `transfer_reason` varchar(500) DEFAULT NULL COMMENT '异动原因',
  `transfer_date` date DEFAULT NULL COMMENT '异动生效日期',
  `apply_date` date DEFAULT NULL COMMENT '申请日期',
  `approval_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审批状态：0草稿 1待审批 2已通过 3已驳回 4已撤销',
  `approval_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联统一审批实例ID',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `approver_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批人ID（本模块冗余，供统一审批待办）',
  `approver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审批人姓名',
  `leave_type` tinyint(1) DEFAULT NULL COMMENT '离职类型：1主动辞职 2协商解除 3辞退 4合同到期不续签（仅离职）',
  `last_work_date` date DEFAULT NULL COMMENT '最后工作日（仅离职）',
  `handover_person_id` int(11) NOT NULL DEFAULT 0 COMMENT '交接人ID（仅离职）',
  `handover_person_name` varchar(50) NOT NULL DEFAULT '' COMMENT '交接人姓名（仅离职）',
  `handover_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '交接状态：0待交接 1交接中 2已完成（仅离职）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '异动状态：0草稿 1待生效 2已生效 3已取消',
  `effective_time` datetime DEFAULT NULL COMMENT '实际生效时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_transfer_no` (`transfer_no`),
  KEY `idx_employee` (`employee_id`),
  KEY `idx_status` (`status`),
  KEY `idx_approval_status` (`approval_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工异动主表';

-- ========== 二、异动附件表 ==========
CREATE TABLE IF NOT EXISTS `employee_transfer_attachment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `transfer_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联异动主表ID',
  `file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '文件名',
  `file_path` varchar(500) NOT NULL DEFAULT '' COMMENT '文件路径',
  `file_size` int(11) NOT NULL DEFAULT 0 COMMENT '文件大小（字节）',
  `file_type` varchar(50) NOT NULL DEFAULT '' COMMENT '文件类型（如 application/pdf、image/jpeg）',
  `attachment_type` tinyint(1) NOT NULL DEFAULT 4 COMMENT '附件类型：1转正评估表 2调岗申请单 3离职交接单 4其他',
  `upload_by` int(11) NOT NULL DEFAULT 0 COMMENT '上传人ID',
  `upload_time` datetime DEFAULT NULL COMMENT '上传时间',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_transfer_id` (`transfer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工异动附件表';

-- ========== 三、权限（6 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('员工异动','hr:transfer:view',2,0,'hr','/hr/transfer/list','el-icon-switch-button',NULL,190,1,1,'员工异动-查看（菜单）',NOW(),NOW()),
('新增异动','hr:transfer:add',2,0,'hr',NULL,NULL,NULL,191,1,1,'新增员工异动',NOW(),NOW()),
('编辑异动','hr:transfer:edit',2,0,'hr',NULL,NULL,NULL,192,1,1,'编辑员工异动',NOW(),NOW()),
('删除异动','hr:transfer:delete',2,0,'hr',NULL,NULL,NULL,193,1,1,'删除员工异动',NOW(),NOW()),
('异动确认生效','hr:transfer:approve',2,0,'hr',NULL,NULL,NULL,194,1,1,'确认异动生效',NOW(),NOW()),
('导出异动','hr:transfer:export',2,0,'hr',NULL,NULL,NULL,195,1,1,'导出异动列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'hr:transfer:%';

-- ========== 四、菜单：人事管理（id=21）-> 员工异动（目录）-> 异动列表（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 21, '员工异动', NULL, 'el-icon-switch-button', '', 40, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='员工异动' AND parent_id=21 AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='员工异动' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '异动列表', '/hr/transfer/list', 'el-icon-document', 'hr:transfer:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/hr/transfer/list' AND deleted_at IS NULL);

-- ========== 五、统一审批流程（employee_transfer） ==========
INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`module_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('employee_transfer', '员工异动', '人事管理', 1, 48, '[{"node_name":"人事管理员审批","approver_type":"role","approver_value":"super_admin","approver_name":"管理员","timeout_hours":48,"timeout_action":"remind"}]', 1, '员工异动审批', NOW(), NOW());
