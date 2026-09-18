-- 146_create_hr_leave.sql
-- 假勤申请（人事管理 -> 考勤管理 -> 假勤申请）：3 表 + 6 权限 + 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:attendance:leave:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:attendance:leave:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:attendance:leave:%';
--   DROP TABLE IF EXISTS hr_leave_approval_log;
--   DROP TABLE IF EXISTS hr_leave_request_detail;
--   DROP TABLE IF EXISTS hr_leave_request;

-- ========== 一、假勤申请表 ==========
CREATE TABLE IF NOT EXISTS `hr_leave_request` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_no` varchar(30) NOT NULL DEFAULT '' COMMENT '申请编号 LQ+YYYYMMDD+XXXX',
  `applicant_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请人ID',
  `applicant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '申请人姓名（冗余）',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '申请部门名称（冗余）',
  `leave_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '假勤类型：1年假 2事假 3病假 4调休 5加班 6出差 7婚假 8丧假 9产假 10其他',
  `start_date` date DEFAULT NULL COMMENT '开始日期',
  `end_date` date DEFAULT NULL COMMENT '结束日期',
  `start_time` varchar(5) DEFAULT NULL COMMENT '开始时间（半天申请 HH:mm）',
  `end_time` varchar(5) DEFAULT NULL COMMENT '结束时间（半天申请 HH:mm）',
  `total_days` decimal(5,1) NOT NULL DEFAULT 1.0 COMMENT '申请总天数（支持半天0.5）',
  `reason` varchar(500) DEFAULT NULL COMMENT '申请事由',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审批 2已通过 3已驳回 4已撤销',
  `approver_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批人ID',
  `approver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审批人姓名（冗余）',
  `approve_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approve_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_request_no` (`request_no`),
  KEY `idx_applicant` (`applicant_id`),
  KEY `idx_status` (`status`),
  KEY `idx_leave_type` (`leave_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='假勤申请表';

-- ========== 二、假勤申请附件表 ==========
CREATE TABLE IF NOT EXISTS `hr_leave_request_detail` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联假勤申请ID',
  `attachment_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '附件类型：1证明文件 2病历单 3出差单 4其他',
  `file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '文件名',
  `file_path` varchar(500) NOT NULL DEFAULT '' COMMENT '文件路径',
  `file_size` int(11) NOT NULL DEFAULT 0 COMMENT '文件大小（字节）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='假勤申请附件表';

-- ========== 三、假勤审批日志表 ==========
CREATE TABLE IF NOT EXISTS `hr_leave_approval_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联假勤申请ID',
  `action` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1提交 2通过 3驳回 4撤销 5催办',
  `action_label` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `before_status` tinyint(1) DEFAULT NULL COMMENT '操作前状态',
  `after_status` tinyint(1) DEFAULT NULL COMMENT '操作后状态',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='假勤审批日志表';

-- ========== 四、权限（6 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('假勤申请','hr:attendance:leave:view',2,0,'hr','/hr/attendance/leave','el-icon-date',NULL,172,1,1,'假勤申请-查看（菜单）',NOW(),NOW()),
('假勤申请新增','hr:attendance:leave:add',2,0,'hr',NULL,NULL,NULL,173,1,1,'新增假勤申请',NOW(),NOW()),
('假勤申请编辑','hr:attendance:leave:edit',2,0,'hr',NULL,NULL,NULL,174,1,1,'编辑假勤申请',NOW(),NOW()),
('假勤申请删除','hr:attendance:leave:delete',2,0,'hr',NULL,NULL,NULL,175,1,1,'删除假勤申请',NOW(),NOW()),
('假勤申请审批','hr:attendance:leave:approve',2,0,'hr',NULL,NULL,NULL,176,1,1,'审批假勤申请（通过/驳回）',NOW(),NOW()),
('假勤申请导出','hr:attendance:leave:export',2,0,'hr',NULL,NULL,NULL,177,1,1,'导出假勤申请',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'hr:attendance:leave:%';

-- ========== 五、菜单：考勤管理（人事管理 id=21 下）-> 假勤申请 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='考勤管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '假勤申请', '/hr/attendance/leave', 'el-icon-date', 'hr:attendance:leave:view', 5, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:attendance:leave:view' AND deleted_at IS NULL);
