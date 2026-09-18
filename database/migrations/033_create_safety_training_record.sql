-- =====================================================
-- 033_create_safety_training_record.sql
-- 安全培训记录模块：记录表 + 参训人员表 + 字典 + 参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、培训记录表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_record` (
  `id`                   int(11) unsigned NOT NULL AUTO_INCREMENT,
  `record_code`          varchar(50)  NOT NULL COMMENT '记录编号 STR-YYYYMMDD-XXXX',
  `plan_id`              int(11)      NOT NULL COMMENT '培训计划ID',
  `plan_name`            varchar(100) NOT NULL COMMENT '计划名称（冗余）',
  `training_type_id`     int(11)      NOT NULL COMMENT '培训类型ID',
  `training_type_name`   varchar(50)  DEFAULT NULL COMMENT '培训类型名称（冗余）',
  `training_mode`        varchar(20)  NOT NULL COMMENT '培训方式 online/offline/mixed',
  `location`             varchar(200) DEFAULT NULL COMMENT '培训地点',
  `content`              text         DEFAULT NULL COMMENT '培训内容',
  `teacher_ids`          varchar(500) DEFAULT NULL COMMENT '讲师ID列表，逗号分隔',
  `teacher_names`        varchar(500) DEFAULT NULL COMMENT '讲师姓名列表（冗余）',
  `courseware_ids`       varchar(500) DEFAULT NULL COMMENT '课件ID列表，逗号分隔',
  `courseware_names`     varchar(500) DEFAULT NULL COMMENT '课件名称列表（冗余）',
  `plan_count`           int(11)      NOT NULL DEFAULT 0 COMMENT '计划培训人数（冗余）',
  `actual_count`         int(11)      NOT NULL DEFAULT 0 COMMENT '实际参训人数',
  `training_date`        date         DEFAULT NULL COMMENT '培训日期',
  `training_start_time`  datetime     DEFAULT NULL COMMENT '培训开始时间',
  `training_end_time`    datetime     DEFAULT NULL COMMENT '培训结束时间',
  `duration_hours`       decimal(5,1) NOT NULL DEFAULT 0 COMMENT '培训时长（小时）',
  `responsible_id`       int(11)      DEFAULT NULL COMMENT '负责人ID',
  `responsible_name`     varchar(50)  DEFAULT NULL COMMENT '负责人姓名（冗余）',
  `evaluation_score`     int(11)      DEFAULT NULL COMMENT '评估得分 0-100',
  `evaluation_level`     varchar(20)  DEFAULT NULL COMMENT '评估等级 excellent/good/general/poor',
  `evaluation_opinion`   varchar(500) DEFAULT NULL COMMENT '评估意见',
  `summary`              text         DEFAULT NULL COMMENT '培训总结',
  `status`               varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态 pending待执行/completed已完成',
  `remark`               text         DEFAULT NULL COMMENT '备注',
  `create_time`          datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`          datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_record_code` (`record_code`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_training_type_id` (`training_type_id`),
  KEY `idx_training_date` (`training_date`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全培训记录';

-- ========== 二、培训参训人员表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_attendee` (
  `id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `record_id`      int(11)      NOT NULL COMMENT '培训记录ID',
  `user_id`        int(11)      NOT NULL COMMENT '用户ID',
  `user_name`      varchar(50)  NOT NULL COMMENT '用户姓名（冗余）',
  `department`     varchar(100) DEFAULT NULL COMMENT '所属部门（冗余）',
  `position`       varchar(100) DEFAULT NULL COMMENT '岗位（冗余）',
  `checkin_status` varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '签到状态 pending未签到/signed已签到',
  `checkin_time`   datetime     DEFAULT NULL COMMENT '签到时间',
  `signout_time`   datetime     DEFAULT NULL COMMENT '签退时间',
  `remark`         varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time`    datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_record_id` (`record_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_checkin_status` (`checkin_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训参训人员';

-- ========== 三、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('培训记录状态','training_record_status','培训记录状态',80,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='training_record_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'待执行','pending',1,'primary',1,NOW(),NOW()),
(@dt1,'已完成','completed',2,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('培训评估等级','evaluation_level','培训评估等级',81,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='evaluation_level');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'优秀','excellent',1,'success',1,NOW(),NOW()),
(@dt2,'良好','good',2,'primary',1,NOW(),NOW()),
(@dt2,'一般','general',3,'warning',1,NOW(),NOW()),
(@dt2,'差','poor',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('签到状态','checkin_status','培训签到状态',82,1,NOW(),NOW());
SET @dt3=(SELECT id FROM dictionary_types WHERE code='checkin_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt3,'未签到','pending',1,'info',1,NOW(),NOW()),
(@dt3,'已签到','signed',2,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 四、系统参数 ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('training_record_code_prefix', 'STR', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('training_record_code_prefix', 'STR', '培训记录编号前缀', 'safety', 'string', '培训记录编号前缀（STR-YYYYMMDD-XXXX）', 55, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('培训记录查看',   'safety:training:record:list',     1, 0, '安全培训', '/safety/training/record', 'el-icon-document-copy', NULL, 80, 1, 1, '查看培训记录', NOW(), NOW()),
('培训记录详情',   'safety:training:record:query',    2, 0, '安全培训', '/safety/training/record', NULL, NULL, 81, 1, 1, '查看培训记录详情', NOW(), NOW()),
('生成培训记录',   'safety:training:record:add',      2, 0, '安全培训', '/safety/training/record', NULL, NULL, 82, 1, 1, '从计划生成培训记录', NOW(), NOW()),
('培训记录编辑',   'safety:training:record:edit',     2, 0, '安全培训', '/safety/training/record', NULL, NULL, 83, 1, 1, '更新执行信息/签到', NOW(), NOW()),
('培训记录评估',   'safety:training:record:evaluate', 2, 0, '安全培训', '/safety/training/record', NULL, NULL, 84, 1, 1, '提交培训评估', NOW(), NOW()),
('导出培训记录',   'safety:training:record:export',   2, 0, '安全培训', '/safety/training/record', NULL, NULL, 85, 1, 1, '导出培训记录/签到表', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 六、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:training:record:list','safety:training:record:query','safety:training:record:add',
                   'safety:training:record:edit','safety:training:record:evaluate','safety:training:record:export');

-- ========== 七、侧边栏菜单（安全培训下新增"培训记录"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '培训记录', '/safety/training/record', 'el-icon-document-copy', 'safety:training:record:list', 2, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:record:list' AND x.`deleted_at` IS NULL);
