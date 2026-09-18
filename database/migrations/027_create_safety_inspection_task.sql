-- =====================================================
-- 027_create_safety_inspection_task.sql
-- 安全检查任务模块：任务表 + 问题记录表 + 数据字典 + 系统参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、检查任务表 ==========
CREATE TABLE IF NOT EXISTS `safety_inspection_task` (
  `id`                    int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_code`             varchar(50)  NOT NULL COMMENT '任务编号 SIT-YYYYMMDD-XXXX',
  `plan_id`               int(11)      NOT NULL COMMENT '检查计划ID',
  `plan_name`             varchar(100) DEFAULT NULL COMMENT '计划名称（冗余）',
  `inspection_type_id`    int(11)      NOT NULL COMMENT '检查类型ID',
  `inspection_type_name`  varchar(50)  DEFAULT NULL COMMENT '检查类型名称（冗余）',
  `area`                  varchar(100) DEFAULT NULL COMMENT '检查区域',
  `template_id`           int(11)      DEFAULT NULL COMMENT '检查标准模板ID',
  `leader_id`             int(11)      DEFAULT NULL COMMENT '负责人ID（users.id）',
  `leader_name`           varchar(50)  DEFAULT NULL COMMENT '负责人姓名',
  `executor_id`           int(11)      DEFAULT NULL COMMENT '执行人ID（users.id）',
  `executor_name`         varchar(50)  DEFAULT NULL COMMENT '执行人姓名',
  `plan_execute_date`     date         NOT NULL COMMENT '计划执行日期',
  `actual_execute_date`   datetime     DEFAULT NULL COMMENT '实际执行日期',
  `status`                varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending待执行 in_progress执行中 completed已完成 overdue已逾期 cancelled已取消',
  `execute_start_time`    datetime     DEFAULT NULL COMMENT '执行开始时间',
  `execute_end_time`      datetime     DEFAULT NULL COMMENT '执行结束时间',
  `execute_duration`      int(11)      DEFAULT NULL COMMENT '执行耗时（分钟）',
  `result`                json         DEFAULT NULL COMMENT '检查项目执行结果 [{item_name,result,remark}]',
  `summary`               text         DEFAULT NULL COMMENT '检查总结',
  `issue_count`           int(11)      NOT NULL DEFAULT 0 COMMENT '问题数量',
  `is_notified`           tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否已发送到期提醒',
  `remind_count`          int(11)      NOT NULL DEFAULT 0 COMMENT '提醒次数',
  `cancel_reason`         varchar(255) DEFAULT NULL COMMENT '取消原因',
  `remark`                text         DEFAULT NULL COMMENT '备注',
  `create_time`           datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`           datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`           datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_code` (`task_code`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_executor_id` (`executor_id`),
  KEY `idx_status` (`status`),
  KEY `idx_plan_execute_date` (`plan_execute_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全检查任务';

-- ========== 二、检查问题记录表 ==========
CREATE TABLE IF NOT EXISTS `safety_inspection_issue` (
  `id`                int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id`           int(11)      NOT NULL COMMENT '检查任务ID',
  `plan_id`           int(11)      DEFAULT NULL COMMENT '检查计划ID',
  `item_name`         varchar(100) NOT NULL COMMENT '检查项目名称',
  `issue_description` text         NOT NULL COMMENT '问题描述',
  `suggest`           text         DEFAULT NULL COMMENT '整改建议',
  `severity`          varchar(20)  NOT NULL DEFAULT 'minor' COMMENT '严重程度：minor一般 major严重 critical紧急',
  `hazard_id`         int(11)      DEFAULT NULL COMMENT '关联隐患ID（safety_hazards.id）',
  `status`            varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending待处理 resolved已处理',
  `create_time`       datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`       datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全检查问题记录';

-- ========== 三、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('检查任务状态','inspection_task_status','检查任务状态',74,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='inspection_task_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'待执行','pending',1,'primary',1,NOW(),NOW()),
(@dt1,'执行中','in_progress',2,'warning',1,NOW(),NOW()),
(@dt1,'已完成','completed',3,'success',1,NOW(),NOW()),
(@dt1,'逾期','overdue',4,'danger',1,NOW(),NOW()),
(@dt1,'已取消','cancelled',5,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('问题严重程度','inspection_issue_severity','检查问题严重程度',75,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='inspection_issue_severity');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'一般','minor',1,'info',1,NOW(),NOW()),
(@dt2,'严重','major',2,'warning',1,NOW(),NOW()),
(@dt2,'紧急','critical',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 四、系统参数 ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('inspection_task_code_prefix',     'SIT', NOW(), NOW()),
('inspection_remind_days',          '1',   NOW(), NOW()),
('inspection_auto_generate_time',   '02:00', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('inspection_task_code_prefix',     'SIT',   '检查任务编号前缀',   'safety', 'string', '检查任务编号前缀（SIT-YYYYMMDD-XXXX）', 43, 0, 1, NOW(), NOW()),
('inspection_task_advance_days',    '1',     '任务提前生成天数',   'safety', 'number', '检查任务提前生成天数',                   44, 0, 1, NOW(), NOW()),
('inspection_remind_days',          '1',     '检查到期提醒天数',   'safety', 'number', '任务到期前提前提醒执行人的天数',         45, 0, 1, NOW(), NOW()),
('inspection_auto_generate_time',   '02:00', '自动生成任务时间',   'safety', 'string', '每日自动生成任务的时间（HH:MM）',        46, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('检查任务查看',   'safety:inspection:task:list',    1, 0, '安全检查', '/safety/inspection/task', 'el-icon-s-order', NULL, 50, 1, 1, '查看检查任务列表', NOW(), NOW()),
('检查任务详情',   'safety:inspection:task:query',   2, 0, '安全检查', '/safety/inspection/task', NULL, NULL, 51, 1, 1, '查看检查任务详情', NOW(), NOW()),
('分配执行人',     'safety:inspection:task:assign',  2, 0, '安全检查', '/safety/inspection/task', NULL, NULL, 52, 1, 1, '分配/更换任务执行人', NOW(), NOW()),
('取消检查任务',   'safety:inspection:task:edit',    2, 0, '安全检查', '/safety/inspection/task', NULL, NULL, 53, 1, 1, '取消任务/发送提醒', NOW(), NOW()),
('手动生成任务',   'safety:inspection:task:add',     2, 0, '安全检查', '/safety/inspection/task', NULL, NULL, 54, 1, 1, '手动生成检查任务', NOW(), NOW()),
('执行检查任务',   'safety:inspection:task:execute', 2, 0, '安全检查', '/safety/inspection/task', NULL, NULL, 55, 1, 1, '开始执行/提交检查结果', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 六、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:inspection:task:list','safety:inspection:task:query','safety:inspection:task:assign',
                   'safety:inspection:task:edit','safety:inspection:task:add','safety:inspection:task:execute');

-- ========== 七、侧边栏菜单（安全检查下新增"检查任务"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '检查任务', '/safety/inspection/task', 'el-icon-s-order', 'safety:inspection:task:list', 2, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:inspection:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:inspection:task:list' AND x.`deleted_at` IS NULL);
