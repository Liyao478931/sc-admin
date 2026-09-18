-- 168_create_approval.sql
-- 统一审批管理（我的待办）：7 表 + 6 权限 + 2 菜单 + 流程定义 + 示例数据
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('approval:view','approval:task:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'approval:%');
--   DELETE FROM permissions WHERE code LIKE 'approval:%';
--   DROP TABLE IF EXISTS approval_common_phrase;
--   DROP TABLE IF EXISTS approval_notify_config;
--   DROP TABLE IF EXISTS approval_urge_log;
--   DROP TABLE IF EXISTS approval_history;
--   DROP TABLE IF EXISTS approval_node;
--   DROP TABLE IF EXISTS approval_instance;
--   DROP TABLE IF EXISTS approval_flow;

-- ========== 一、审批流程定义表 ==========
CREATE TABLE IF NOT EXISTS `approval_flow` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `biz_type` varchar(50) NOT NULL DEFAULT '' COMMENT '业务类型编码（purchase_request/purchase_order/contract/leave/hazard/report）',
  `biz_name` varchar(50) NOT NULL DEFAULT '' COMMENT '业务类型名称',
  `approval_mode` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审批模式：1单人 2会签 3或签 4依次',
  `timeout_hours` int(11) NOT NULL DEFAULT 24 COMMENT '审批时限（小时）',
  `node_config` text COMMENT '节点配置JSON：[{"name":"部门审批"},{"name":"经理审批"}]',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_biz_type` (`biz_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批流程定义表';

-- ========== 二、审批实例表 ==========
CREATE TABLE IF NOT EXISTS `approval_instance` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `instance_no` varchar(32) NOT NULL DEFAULT '' COMMENT '审批实例编号 AP+YYYYMMDD+4位流水',
  `flow_id` int(11) NOT NULL DEFAULT 0 COMMENT '流程定义ID',
  `biz_type` varchar(50) NOT NULL DEFAULT '' COMMENT '业务类型',
  `biz_id` int(11) NOT NULL DEFAULT 0 COMMENT '业务单据ID（0=演示数据）',
  `business_no` varchar(50) NOT NULL DEFAULT '' COMMENT '业务编号',
  `business_title` varchar(255) NOT NULL DEFAULT '' COMMENT '业务标题',
  `applicant_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请人ID',
  `applicant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '申请人姓名（冗余）',
  `current_node_index` int(11) NOT NULL DEFAULT 0 COMMENT '当前节点序号（从0开始）',
  `current_node_name` varchar(50) NOT NULL DEFAULT '' COMMENT '当前节点名称',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1审批中 2已通过 3已驳回 4已撤销',
  `approval_mode` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审批模式：1单人 2会签 3或签 4依次',
  `mode_label` varchar(20) NOT NULL DEFAULT '' COMMENT '审批模式标签',
  `urgent` tinyint(1) NOT NULL DEFAULT 0 COMMENT '紧急程度：0普通 1紧急 2特急',
  `submit_time` datetime DEFAULT NULL COMMENT '提交时间',
  `timeout_at` datetime DEFAULT NULL COMMENT '审批时限（超时判定）',
  `finish_time` datetime DEFAULT NULL COMMENT '完成时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_instance_no` (`instance_no`),
  KEY `idx_status` (`status`),
  KEY `idx_biz_type` (`biz_type`),
  KEY `idx_applicant` (`applicant_id`),
  KEY `idx_timeout` (`timeout_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批实例表';

-- ========== 三、审批节点表（实例执行记录） ==========
CREATE TABLE IF NOT EXISTS `approval_node` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `instance_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批实例ID',
  `node_index` int(11) NOT NULL DEFAULT 0 COMMENT '节点序号',
  `node_name` varchar(50) NOT NULL DEFAULT '' COMMENT '节点名称',
  `approver_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批人ID',
  `approver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审批人姓名（冗余）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0待审 1已通过 2已驳回',
  `pass_count` int(11) NOT NULL DEFAULT 0 COMMENT '会签已通过人数',
  `approve_time` datetime DEFAULT NULL COMMENT '审批时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '节点备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_instance` (`instance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批节点执行表';

-- ========== 四、审批历史表 ==========
CREATE TABLE IF NOT EXISTS `approval_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `instance_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批实例ID',
  `node_index` int(11) NOT NULL DEFAULT 0 COMMENT '节点序号',
  `action` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型：submit/approve/reject/transfer/urge/batch',
  `action_label` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `result` varchar(20) NOT NULL DEFAULT '' COMMENT '操作结果：pass/reject/transfer/urge',
  `comment` text COMMENT '审批意见',
  `notify_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '通知状态：0未发送 1已发送',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_instance` (`instance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批历史表';

-- ========== 五、催办日志表 ==========
CREATE TABLE IF NOT EXISTS `approval_urge_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `instance_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批实例ID',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '催办发起人ID',
  `target_id` int(11) NOT NULL DEFAULT 0 COMMENT '被催办人ID',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_instance_user` (`instance_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='催办日志表';

-- ========== 六、通知配置表 ==========
CREATE TABLE IF NOT EXISTS `approval_notify_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '用户ID',
  `inmail` tinyint(1) NOT NULL DEFAULT 1 COMMENT '站内信通知（默认开启，不可关）',
  `email_switch` tinyint(1) NOT NULL DEFAULT 0 COMMENT '邮件通知开关',
  `email` varchar(100) DEFAULT NULL COMMENT '邮件地址',
  `sms_switch` tinyint(1) NOT NULL DEFAULT 0 COMMENT '短信通知开关',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号码',
  `scenes` varchar(255) NOT NULL DEFAULT 'todo,urge,approve,reject,transfer,timeout' COMMENT '通知场景（逗号分隔）',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批通知配置表';

-- ========== 七、常用语表 ==========
CREATE TABLE IF NOT EXISTS `approval_common_phrase` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '用户ID（0=系统默认）',
  `content` varchar(255) NOT NULL DEFAULT '' COMMENT '常用语内容',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批常用语表';

-- ========== 八、权限（6 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('统一审批','approval:view',1,0,'approval',NULL,'el-icon-finished',NULL,300,1,1,'统一审批（目录）',NOW(),NOW()),
('我的待办','approval:task:view',2,0,'approval','/approval/my-tasks','el-icon-tickets',NULL,301,1,1,'我的待办-查看（菜单）',NOW(),NOW()),
('审批操作','approval:task:approve',2,0,'approval',NULL,NULL,NULL,302,1,1,'执行审批操作（通过/驳回）',NOW(),NOW()),
('审批转办','approval:task:transfer',2,0,'approval',NULL,NULL,NULL,303,1,1,'转办审批任务',NOW(),NOW()),
('审批催办','approval:task:urge',2,0,'approval',NULL,NULL,NULL,304,1,1,'催办审批任务',NOW(),NOW()),
('批量审批','approval:task:batch',2,0,'approval',NULL,NULL,NULL,305,1,1,'批量审批通过',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'approval:%';

-- ========== 九、菜单（目录 + 叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '统一审批', NULL, 'el-icon-finished', 'approval:view', 300, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='approval:view' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='approval:view' AND deleted_at IS NULL LIMIT 1), '我的待办', '/approval/my-tasks', 'el-icon-tickets', 'approval:task:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='approval:task:view' AND deleted_at IS NULL);

-- ========== 十、流程定义初始数据（6 个业务类型，默认单人审批） ==========
INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('purchase_request','采购申请',1,24,'[{"name":"部门审批"},{"name":"经理审批"}]',1,'采购申请审批',NOW(),NOW()),
('purchase_order','采购订单',1,24,'[{"name":"部门审批"},{"name":"经理审批"}]',1,'采购订单审批',NOW(),NOW()),
('contract','合同审批',1,48,'[{"name":"法务审批"},{"name":"总经理审批"}]',1,'合同审批',NOW(),NOW()),
('leave','假勤申请',1,24,'[{"name":"部门审批"}]',1,'假勤申请审批',NOW(),NOW()),
('hazard','隐患整改',1,24,'[{"name":"安全主管审批"}]',1,'隐患整改审批',NOW(),NOW()),
('report','报工审核',1,24,'[{"name":"部门审批"},{"name":"经理审批"}]',1,'报工审核审批',NOW(),NOW());

-- ========== 十一、示例审批实例（动态取真实用户，便于立即可验收） ==========
-- 实例1：待审批（采购申请）
INSERT INTO `approval_instance` (`instance_no`,`flow_id`,`biz_type`,`biz_id`,`business_no`,`business_title`,`applicant_id`,`applicant_name`,`current_node_index`,`current_node_name`,`status`,`approval_mode`,`mode_label`,`urgent`,`submit_time`,`timeout_at`,`created_at`,`updated_at`)
SELECT 'AP-DEMO-001', f.id, 'purchase_request', 0, 'PR-20260816-001', '采购申请示例-生产原料采购',
       u1.id, u1.real_name, 0, '部门审批', 1, 1, '单人审批', 0, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 23 HOUR), NOW(), NOW()
FROM approval_flow f,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1) u1,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1 OFFSET 1) u2
WHERE f.biz_type='purchase_request'
  AND NOT EXISTS (SELECT 1 FROM approval_instance WHERE instance_no='AP-DEMO-001');

-- 实例1 节点
INSERT INTO `approval_node` (`instance_id`,`node_index`,`node_name`,`approver_id`,`approver_name`,`status`,`created_at`,`updated_at`)
SELECT i.id, 0, '部门审批', u2.id, u2.real_name, 0, NOW(), NOW()
FROM approval_instance i,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1 OFFSET 1) u2
WHERE i.instance_no='AP-DEMO-001'
  AND NOT EXISTS (SELECT 1 FROM approval_node WHERE instance_id=i.id AND node_index=0);

-- 实例1 历史（提交）
INSERT INTO `approval_history` (`instance_id`,`node_index`,`action`,`action_label`,`operator_id`,`operator_name`,`result`,`comment`,`notify_status`,`created_at`)
SELECT i.id, 0, 'submit', '提交申请', i.applicant_id, i.applicant_name, 'pass', '发起审批申请', 1, DATE_SUB(NOW(), INTERVAL 1 HOUR)
FROM approval_instance i
WHERE i.instance_no='AP-DEMO-001'
  AND NOT EXISTS (SELECT 1 FROM approval_history WHERE instance_id=i.id AND action='submit');

-- 实例2：今日待审（报工审核，紧急）
INSERT INTO `approval_instance` (`instance_no`,`flow_id`,`biz_type`,`biz_id`,`business_no`,`business_title`,`applicant_id`,`applicant_name`,`current_node_index`,`current_node_name`,`status`,`approval_mode`,`mode_label`,`urgent`,`submit_time`,`timeout_at`,`created_at`,`updated_at`)
SELECT 'AP-DEMO-002', f.id, 'report', 0, 'PR-20260816-002', '报工审核示例-第3工段焊接报工',
       u1.id, u1.real_name, 0, '部门审批', 1, 1, '单人审批', 1, NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR), NOW(), NOW()
FROM approval_flow f,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1) u1,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1 OFFSET 1) u2
WHERE f.biz_type='report'
  AND NOT EXISTS (SELECT 1 FROM approval_instance WHERE instance_no='AP-DEMO-002');

INSERT INTO `approval_node` (`instance_id`,`node_index`,`node_name`,`approver_id`,`approver_name`,`status`,`created_at`,`updated_at`)
SELECT i.id, 0, '部门审批', u2.id, u2.real_name, 0, NOW(), NOW()
FROM approval_instance i,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1 OFFSET 1) u2
WHERE i.instance_no='AP-DEMO-002'
  AND NOT EXISTS (SELECT 1 FROM approval_node WHERE instance_id=i.id AND node_index=0);

-- 实例3：已超时（合同审批，特急，仍在审批中）
INSERT INTO `approval_instance` (`instance_no`,`flow_id`,`biz_type`,`biz_id`,`business_no`,`business_title`,`applicant_id`,`applicant_name`,`current_node_index`,`current_node_name`,`status`,`approval_mode`,`mode_label`,`urgent`,`submit_time`,`timeout_at`,`created_at`,`updated_at`)
SELECT 'AP-DEMO-003', f.id, 'contract', 0, 'HT-20260815-001', '合同审批示例-设备采购合同',
       u1.id, u1.real_name, 0, '法务审批', 1, 1, '单人审批', 2, DATE_SUB(NOW(), INTERVAL 25 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR), NOW(), NOW()
FROM approval_flow f,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1) u1,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1 OFFSET 1) u2
WHERE f.biz_type='contract'
  AND NOT EXISTS (SELECT 1 FROM approval_instance WHERE instance_no='AP-DEMO-003');

INSERT INTO `approval_node` (`instance_id`,`node_index`,`node_name`,`approver_id`,`approver_name`,`status`,`created_at`,`updated_at`)
SELECT i.id, 0, '法务审批', u2.id, u2.real_name, 0, NOW(), NOW()
FROM approval_instance i,
     (SELECT id, real_name FROM users WHERE deleted_at IS NULL ORDER BY id LIMIT 1 OFFSET 1) u2
WHERE i.instance_no='AP-DEMO-003'
  AND NOT EXISTS (SELECT 1 FROM approval_node WHERE instance_id=i.id AND node_index=0);

-- ========== 十二、系统默认常用语 ==========
INSERT IGNORE INTO `approval_common_phrase` (`user_id`,`content`,`sort`,`status`,`created_at`,`updated_at`) VALUES
(0,'同意，请按流程执行。',1,1,NOW(),NOW()),
(0,'经核实情况属实，同意审批。',2,1,NOW(),NOW()),
(0,'资料齐全，符合要求，同意。',3,1,NOW(),NOW()),
(0,'请补充相关说明后再提交。',4,1,NOW(),NOW());
