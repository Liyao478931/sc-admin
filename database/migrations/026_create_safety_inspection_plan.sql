-- =====================================================
-- 026_create_safety_inspection_plan.sql
-- 安全检查模块：检查类型表 + 检查标准模板表 + 检查计划表 + 数据字典 + 系统参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、检查类型表 ==========
CREATE TABLE IF NOT EXISTS `safety_inspection_type` (
  `id`                  int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type_code`           varchar(30)  NOT NULL COMMENT '类型编码，如 DAILY/SPECIAL/HOLIDAY',
  `type_name`           varchar(50)  NOT NULL COMMENT '类型名称，如日常检查/专项检查/节假日检查',
  `default_cycle_type`  varchar(20)  DEFAULT NULL COMMENT '默认周期类型：day/week/month/quarter/year',
  `default_cycle_value` int(11)      DEFAULT NULL COMMENT '默认周期值',
  `default_leader_role` varchar(50)  DEFAULT NULL COMMENT '默认负责人角色',
  `description`         varchar(255) DEFAULT NULL COMMENT '描述说明',
  `sort`                int(11)      NOT NULL DEFAULT 0 COMMENT '排序',
  `status`              tinyint(1)   NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `create_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_code` (`type_code`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全检查类型';

-- ========== 二、检查标准模板表 ==========
CREATE TABLE IF NOT EXISTS `safety_inspection_template` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_code`      varchar(50)  NOT NULL COMMENT '模板编号 TPL-YYYYMMDD-XXXX',
  `template_name`      varchar(100) NOT NULL COMMENT '模板名称',
  `inspection_type_id` int(11)      DEFAULT NULL COMMENT '适用检查类型ID',
  `items`              json         NOT NULL COMMENT '检查项目列表[{item_name,check_standard,check_method,is_required,deduct_score,sort}]',
  `status`             varchar(20)  NOT NULL DEFAULT 'active' COMMENT '状态：active启用 inactive停用',
  `create_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`        datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`),
  KEY `idx_inspection_type_id` (`inspection_type_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='检查标准模板';

-- ========== 三、检查计划表 ==========
CREATE TABLE IF NOT EXISTS `safety_inspection_plan` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_code`          varchar(50)  NOT NULL COMMENT '计划编号 SIP-YYYYMMDD-XXXX',
  `plan_name`          varchar(100) NOT NULL COMMENT '计划名称',
  `inspection_type_id` int(11)      NOT NULL COMMENT '检查类型ID',
  `area`               varchar(100) DEFAULT NULL COMMENT '检查区域',
  `template_id`        int(11)      DEFAULT NULL COMMENT '模板ID',
  `cycle_type`         varchar(20)  NOT NULL COMMENT '周期类型：day/week/month/quarter/year',
  `cycle_value`        int(11)      NOT NULL COMMENT '周期值',
  `start_date`         date         DEFAULT NULL COMMENT '计划开始日期',
  `end_date`           date         DEFAULT NULL COMMENT '计划结束日期',
  `last_execute_date`  date         DEFAULT NULL COMMENT '上次执行日期',
  `next_execute_date`  date         DEFAULT NULL COMMENT '下次执行日期',
  `leader_id`          int(11)      DEFAULT NULL COMMENT '负责人ID',
  `leader_name`        varchar(50)  DEFAULT NULL COMMENT '负责人姓名',
  `executor_ids`       varchar(500) DEFAULT NULL COMMENT '执行人ID列表，逗号分隔',
  `status`             varchar(20)  NOT NULL DEFAULT 'active' COMMENT '状态：active启用 inactive停用 expired过期',
  `remark`             text         DEFAULT NULL COMMENT '备注',
  `create_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`        datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`),
  KEY `idx_inspection_type_id` (`inspection_type_id`),
  KEY `idx_status` (`status`),
  KEY `idx_next_execute_date` (`next_execute_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全检查计划';

-- ========== 四、预置检查类型 ==========
INSERT IGNORE INTO `safety_inspection_type` (`type_code`,`type_name`,`default_cycle_type`,`default_cycle_value`,`default_leader_role`,`description`,`sort`,`status`) VALUES
('DAILY',   '日常检查',   'day',   1, '班组长',     '由班组长负责，每日执行', 1, 1),
('SPECIAL', '专项检查',   'month', 1, '安全工程师', '由安全工程师负责，按需执行', 2, 1),
('HOLIDAY', '节假日检查', 'year',  1, '安全主管',   '由安全主管负责，节前执行', 3, 1);

-- ========== 五、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('检查计划状态','inspection_plan_status','检查计划状态',72,1,NOW(),NOW());
SET @d1=(SELECT id FROM dictionary_types WHERE code='inspection_plan_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d1,'启用','active',1,'success',1,NOW(),NOW()),
(@d1,'停用','inactive',2,'info',1,NOW(),NOW()),
(@d1,'过期','expired',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('检查周期类型','inspection_cycle_type','检查周期类型',73,1,NOW(),NOW());
SET @d2=(SELECT id FROM dictionary_types WHERE code='inspection_cycle_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d2,'每日','day',1,'primary',1,NOW(),NOW()),
(@d2,'每周','week',2,'primary',1,NOW(),NOW()),
(@d2,'每月','month',3,'primary',1,NOW(),NOW()),
(@d2,'每季','quarter',4,'primary',1,NOW(),NOW()),
(@d2,'每年','year',5,'primary',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 六、系统参数 ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('inspection_plan_code_prefix',       'SIP', NOW(), NOW()),
('inspection_template_code_prefix',   'TPL', NOW(), NOW()),
('inspection_task_advance_days',      '1',   NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('inspection_plan_code_prefix',      'SIP', '检查计划编号前缀', 'safety', 'string', '检查计划编号前缀（SIP-YYYYMMDD-XXXX）', 40, 0, 1, NOW(), NOW()),
('inspection_template_code_prefix',  'TPL', '检查模板编号前缀', 'safety', 'string', '检查模板编号前缀（TPL-YYYYMMDD-XXXX）', 41, 0, 1, NOW(), NOW()),
('inspection_task_advance_days',     '1',   '任务提前生成天数', 'safety', 'number', '检查任务提前生成天数', 42, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 七、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('检查计划查看', 'safety:inspection:plan:list',   1, 0, '安全检查', '/safety/inspection/plan', 'el-icon-document', NULL, 40, 1, 1, '查看检查计划', NOW(), NOW()),
('检查计划新增', 'safety:inspection:plan:add',    2, 0, '安全检查', '/safety/inspection/plan', NULL, NULL, 41, 1, 1, '新增检查计划', NOW(), NOW()),
('检查计划编辑', 'safety:inspection:plan:edit',   2, 0, '安全检查', '/safety/inspection/plan', NULL, NULL, 42, 1, 1, '编辑检查计划', NOW(), NOW()),
('检查计划删除', 'safety:inspection:plan:delete', 2, 0, '安全检查', '/safety/inspection/plan', NULL, NULL, 43, 1, 1, '删除检查计划', NOW(), NOW()),
('检查计划详情', 'safety:inspection:plan:query',  2, 0, '安全检查', '/safety/inspection/plan', NULL, NULL, 44, 1, 1, '查看检查计划详情', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 八、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:inspection:plan:list','safety:inspection:plan:add','safety:inspection:plan:edit','safety:inspection:plan:delete','safety:inspection:plan:query');

-- ========== 九、侧边栏菜单（安全检查下新增"检查计划"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '检查计划', '/safety/inspection/plan', 'el-icon-document', 'safety:inspection:plan:list', 1, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:inspection:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:inspection:plan:list' AND x.`deleted_at` IS NULL);
