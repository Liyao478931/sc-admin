-- 210_create_assessment_task.sql
-- 考核任务管理（人事管理 -> 绩效考核 -> 考核任务管理）
-- 4 张表：assessment_tasks / assessment_deductions / assessment_appeals / assessment_auto_deduct_log
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('assessment:task:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'assessment:%' AND code NOT LIKE 'assessment:template:%' AND code NOT LIKE 'assessment:indicator:%');
--   DELETE FROM permissions WHERE code IN ('assessment:task:view','assessment:task:generate','assessment:task:auto_deduct','assessment:task:manual_deduct','assessment:task:confirm','assessment:task:approve','assessment:appeal:view','assessment:appeal:handle','assessment:export','assessment:warning:view');
--   DROP TABLE IF EXISTS assessment_auto_deduct_log;
--   DROP TABLE IF EXISTS assessment_appeals;
--   DROP TABLE IF EXISTS assessment_deductions;
--   DROP TABLE IF EXISTS assessment_tasks;

-- ========== 一、考核任务主表 ==========
CREATE TABLE IF NOT EXISTS `assessment_tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源模板ID',
  `period` varchar(20) NOT NULL COMMENT '考核周期，如 2026-08',
  `employee_id` int(11) NOT NULL DEFAULT 0 COMMENT '被考核人ID(employee_profiles.id)',
  `department_id` int(11) DEFAULT NULL COMMENT '所属部门ID',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0待评分 1待确认 2已确认 3已审批 4已结束',
  `total_score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '最终得分(百分制)',
  `grade` varchar(10) DEFAULT NULL COMMENT '等级 A/B/C/D',
  `deduction_amount` decimal(15,2) NOT NULL DEFAULT 0.00 COMMENT '考核扣款金额',
  `reward_amount` decimal(15,2) NOT NULL DEFAULT 0.00 COMMENT '考核奖励金额',
  `evaluator_id` int(11) DEFAULT NULL COMMENT '考核人ID(班组长/车间主任)',
  `approver_id` int(11) DEFAULT NULL COMMENT '审批人ID',
  `remark` varchar(500) DEFAULT NULL COMMENT '评语/备注',
  `snapshot` text COMMENT '指标快照(JSON，从模板复制)',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_employee_period` (`employee_id`,`period`),
  KEY `idx_period` (`period`),
  KEY `idx_status` (`status`),
  KEY `idx_template` (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考核任务主表';

-- ========== 二、考核扣分明细表 ==========
CREATE TABLE IF NOT EXISTS `assessment_deductions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT 0 COMMENT '考核任务ID',
  `indicator_id` int(11) NOT NULL DEFAULT 0 COMMENT '指标ID(快照中的ID)',
  `employee_id` int(11) NOT NULL DEFAULT 0 COMMENT '被考核人ID',
  `deduct_score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '本次扣分分值',
  `reason` varchar(255) NOT NULL COMMENT '扣分原因',
  `data_source_type` tinyint(1) NOT NULL DEFAULT 2 COMMENT '1系统自动 2手动录入',
  `data_source_detail` varchar(255) DEFAULT NULL COMMENT '数据来源明细，如工单号/考勤日期',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0待确认 1已确认 2已申诉 3已驳回',
  `confirm_time` datetime DEFAULT NULL COMMENT '员工确认时间',
  `attachments` varchar(500) DEFAULT NULL COMMENT '附件(JSON数组)',
  `created_by` int(11) DEFAULT NULL COMMENT '录入人ID(手动录入时)',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_employee` (`employee_id`),
  KEY `idx_indicator` (`indicator_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考核扣分明细表';

-- ========== 三、考核申诉记录表 ==========
CREATE TABLE IF NOT EXISTS `assessment_appeals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `deduction_id` int(11) NOT NULL DEFAULT 0 COMMENT '扣分明细ID',
  `employee_id` int(11) NOT NULL DEFAULT 0 COMMENT '申诉人ID',
  `appeal_reason` text COMMENT '申诉理由',
  `attachments` varchar(500) DEFAULT NULL COMMENT '附件',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0待处理 1已通过 2已驳回',
  `handler_id` int(11) DEFAULT NULL COMMENT '处理人ID',
  `handler_reply` text COMMENT '处理意见',
  `created_at` datetime DEFAULT NULL,
  `handled_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_deduction` (`deduction_id`),
  KEY `idx_employee` (`employee_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考核申诉记录表';

-- ========== 四、自动扣分执行日志表 ==========
CREATE TABLE IF NOT EXISTS `assessment_auto_deduct_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT 0 COMMENT '考核任务ID',
  `indicator_id` int(11) NOT NULL DEFAULT 0 COMMENT '指标ID',
  `employee_id` int(11) NOT NULL DEFAULT 0 COMMENT '员工ID',
  `executed_at` datetime DEFAULT NULL COMMENT '执行时间',
  `source_count` int(11) NOT NULL DEFAULT 0 COMMENT '违规次数/异常条数',
  `deduct_score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '本次扣分',
  `source_detail` text COMMENT '具体来源记录(JSON)',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1成功 0失败',
  `error_msg` varchar(255) DEFAULT NULL COMMENT '错误信息',
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_employee` (`employee_id`),
  KEY `idx_indicator` (`indicator_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自动扣分执行日志表';

-- ========== 五、权限（10 个，幂等） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核任务管理','assessment:task:view',2,0,'hr','/hr/assessment/task','el-icon-tickets',NULL,310,1,1,'考核任务管理-查看（菜单）',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:task:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '生成考核任务','assessment:task:generate',2,0,'hr',NULL,NULL,NULL,311,1,1,'生成考核任务',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:task:generate');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '执行自动扣分','assessment:task:auto_deduct',2,0,'hr',NULL,NULL,NULL,312,1,1,'执行自动扣分',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:task:auto_deduct');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '手动录入扣分','assessment:task:manual_deduct',2,0,'hr',NULL,NULL,NULL,313,1,1,'手动录入扣分',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:task:manual_deduct');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '确认考核任务','assessment:task:confirm',2,0,'hr',NULL,NULL,NULL,314,1,1,'确认考核任务',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:task:confirm');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '审批考核任务','assessment:task:approve',2,0,'hr',NULL,NULL,NULL,315,1,1,'审批考核任务',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:task:approve');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '查看考核申诉','assessment:appeal:view',2,0,'hr',NULL,NULL,NULL,316,1,1,'查看考核申诉',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:appeal:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '处理考核申诉','assessment:appeal:handle',2,0,'hr',NULL,NULL,NULL,317,1,1,'处理考核申诉',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:appeal:handle');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '导出考核报表','assessment:export',2,0,'hr',NULL,NULL,NULL,318,1,1,'导出考核报表',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:export');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '查看预警看板','assessment:warning:view',2,0,'hr',NULL,NULL,NULL,319,1,1,'查看预警看板',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:warning:view');

INSERT INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` IN ('assessment:task:view','assessment:task:generate','assessment:task:auto_deduct','assessment:task:manual_deduct','assessment:task:confirm','assessment:task:approve','assessment:appeal:view','assessment:appeal:handle','assessment:export','assessment:warning:view')
AND NOT EXISTS (SELECT 1 FROM `role_permissions` rp WHERE rp.role_id=r.`id` AND rp.permission_id=p.`id`);

-- ========== 六、菜单链：绩效考核目录 -> 考核任务管理（叶子） ==========
-- 确保绩效考核目录存在
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '绩效考核', '/hr/assessment', 'el-icon-data-analysis', 'hr:assessment', 60, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:assessment' AND deleted_at IS NULL);

-- 考核任务管理叶子（挂在绩效考核下）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:assessment' AND deleted_at IS NULL LIMIT 1), '考核任务管理', '/hr/assessment/task', 'el-icon-tickets', 'assessment:task:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='assessment:task:view' AND deleted_at IS NULL);
