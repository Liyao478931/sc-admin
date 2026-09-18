-- =====================================================
-- 031_create_safety_training.sql
-- 安全培训模块：培训类型 + 讲师 + 课件 + 计划 四表 + 字典 + 参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、培训类型表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_type` (
  `id`               int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type_code`        varchar(30)  NOT NULL COMMENT '类型编码 INDUCTION/REGULAR/SPECIAL/EMERGENCY',
  `type_name`        varchar(50)  NOT NULL COMMENT '类型名称',
  `default_mode`     varchar(20)  DEFAULT NULL COMMENT '默认培训方式 online/offline/mixed',
  `default_duration` int(11)      DEFAULT NULL COMMENT '默认培训时长（小时）',
  `description`      varchar(255) DEFAULT NULL COMMENT '描述说明',
  `sort`             int(11)      NOT NULL DEFAULT 0 COMMENT '排序',
  `status`           tinyint(1)   NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `create_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_code` (`type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全培训类型';

-- ========== 二、培训讲师表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_teacher` (
  `id`           int(11) unsigned NOT NULL AUTO_INCREMENT,
  `teacher_code` varchar(50)  NOT NULL COMMENT '讲师编号 TCH-YYYYMMDD-XXXX',
  `teacher_name` varchar(50)  NOT NULL COMMENT '讲师姓名',
  `department`   varchar(100) DEFAULT NULL COMMENT '所属部门',
  `expertise`    varchar(255) DEFAULT NULL COMMENT '擅长领域',
  `phone`        varchar(20)  DEFAULT NULL COMMENT '联系电话',
  `intro`        text         DEFAULT NULL COMMENT '讲师简介',
  `avatar`       varchar(255) DEFAULT NULL COMMENT '头像图片路径',
  `sort`         int(11)      NOT NULL DEFAULT 0 COMMENT '排序',
  `status`       tinyint(1)   NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `create_time`  datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`  datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_teacher_code` (`teacher_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全培训讲师';

-- ========== 三、培训课件表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_courseware` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `courseware_code` varchar(50)  NOT NULL COMMENT '课件编号 CW-YYYYMMDD-XXXX',
  `courseware_name` varchar(100) NOT NULL COMMENT '课件名称',
  `file_type`       varchar(20)  NOT NULL COMMENT '文件类型 pdf/ppt/word/video/other',
  `file_path`       varchar(255) NOT NULL COMMENT '文件路径',
  `file_size`       int(11)      DEFAULT NULL COMMENT '文件大小（KB）',
  `description`     varchar(255) DEFAULT NULL COMMENT '描述说明',
  `uploader_id`     int(11)      DEFAULT NULL COMMENT '上传人ID',
  `uploader_name`   varchar(50)  DEFAULT NULL COMMENT '上传人姓名',
  `status`          tinyint(1)   NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `create_time`     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_courseware_code` (`courseware_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全培训课件';

-- ========== 四、培训计划表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_plan` (
  `id`               int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_code`        varchar(50)  NOT NULL COMMENT '计划编号 STP-YYYYMMDD-XXXX',
  `plan_name`        varchar(100) NOT NULL COMMENT '计划名称',
  `training_type_id` int(11)      NOT NULL COMMENT '培训类型ID',
  `training_mode`    varchar(20)  NOT NULL COMMENT '培训方式 online/offline/mixed',
  `location`         varchar(200) DEFAULT NULL COMMENT '培训地点',
  `content`          text         DEFAULT NULL COMMENT '培训内容',
  `target_type`      varchar(20)  NOT NULL DEFAULT 'all' COMMENT '培训对象类型 all/department/position/user',
  `target_ids`       varchar(500) DEFAULT NULL COMMENT '培训对象ID列表（部门/岗位/用户ID，逗号分隔）',
  `target_count`     int(11)      NOT NULL DEFAULT 0 COMMENT '计划培训人数',
  `completed_count`  int(11)      NOT NULL DEFAULT 0 COMMENT '已完成培训人数',
  `teacher_ids`      varchar(500) DEFAULT NULL COMMENT '讲师ID列表，逗号分隔',
  `courseware_ids`   varchar(500) DEFAULT NULL COMMENT '课件ID列表，逗号分隔',
  `plan_start_date`  date         DEFAULT NULL COMMENT '计划开始日期',
  `plan_end_date`    date         DEFAULT NULL COMMENT '计划结束日期',
  `actual_start_date` date        DEFAULT NULL COMMENT '实际开始日期',
  `actual_end_date`  date         DEFAULT NULL COMMENT '实际结束日期',
  `responsible_id`   int(11)      DEFAULT NULL COMMENT '负责人ID',
  `responsible_name` varchar(50)  DEFAULT NULL COMMENT '负责人姓名',
  `duration_hours`   int(11)      NOT NULL DEFAULT 0 COMMENT '计划培训时长（小时）',
  `status`           varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态 pending待执行/in_progress执行中/completed已完成/cancelled已取消',
  `cancel_reason`    varchar(255) DEFAULT NULL COMMENT '取消原因',
  `remark`           text         DEFAULT NULL COMMENT '备注',
  `create_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`      datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`),
  KEY `idx_training_type_id` (`training_type_id`),
  KEY `idx_status` (`status`),
  KEY `idx_plan_start_date` (`plan_start_date`),
  KEY `idx_responsible_id` (`responsible_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全培训计划';

-- ========== 五、预置培训类型 ==========
INSERT IGNORE INTO `safety_training_type` (`type_code`,`type_name`,`default_mode`,`default_duration`,`description`,`sort`,`status`) VALUES
('INDUCTION', '入职培训', 'online', 4,   '新员工入职安全培训', 1, 1),
('REGULAR',   '定期培训', 'offline', 2,  '定期安全教育培训', 2, 1),
('SPECIAL',   '专项培训', 'mixed',   8,  '专项安全技能培训', 3, 1),
('EMERGENCY', '应急演练', 'offline', 2,  '应急疏散与演练', 4, 1);

-- ========== 六、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('培训计划状态','training_plan_status','培训计划状态',76,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='training_plan_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'待执行','pending',1,'primary',1,NOW(),NOW()),
(@dt1,'执行中','in_progress',2,'warning',1,NOW(),NOW()),
(@dt1,'已完成','completed',3,'success',1,NOW(),NOW()),
(@dt1,'已取消','cancelled',4,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('培训方式','training_mode','培训方式',77,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='training_mode');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'线上','online',1,'primary',1,NOW(),NOW()),
(@dt2,'线下','offline',2,'success',1,NOW(),NOW()),
(@dt2,'混合','mixed',3,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('培训对象类型','training_target_type','培训对象类型',78,1,NOW(),NOW());
SET @dt3=(SELECT id FROM dictionary_types WHERE code='training_target_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt3,'全体人员','all',1,'primary',1,NOW(),NOW()),
(@dt3,'指定部门','department',2,'success',1,NOW(),NOW()),
(@dt3,'指定岗位','position',3,'warning',1,NOW(),NOW()),
(@dt3,'指定人员','user',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('课件文件类型','training_file_type','课件文件类型',79,1,NOW(),NOW());
SET @dt4=(SELECT id FROM dictionary_types WHERE code='training_file_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt4,'PDF','pdf',1,'danger',1,NOW(),NOW()),
(@dt4,'PPT','ppt',2,'warning',1,NOW(),NOW()),
(@dt4,'Word','word',3,'primary',1,NOW(),NOW()),
(@dt4,'视频','video',4,'success',1,NOW(),NOW()),
(@dt4,'其他','other',5,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 七、系统参数 ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('training_plan_code_prefix',      'STP', NOW(), NOW()),
('training_teacher_code_prefix',   'TCH', NOW(), NOW()),
('training_courseware_code_prefix','CW',  NOW(), NOW()),
('training_max_file_size',         '50',  NOW(), NOW()),
('training_allowed_file_types',    'pdf,ppt,pptx,doc,docx,mp4,avi,mov', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('training_plan_code_prefix',       'STP', '培训计划编号前缀', 'safety', 'string', '培训计划编号前缀（STP-YYYYMMDD-XXXX）', 50, 0, 1, NOW(), NOW()),
('training_teacher_code_prefix',    'TCH', '讲师编号前缀',     'safety', 'string', '讲师编号前缀（TCH-YYYYMMDD-XXXX）', 51, 0, 1, NOW(), NOW()),
('training_courseware_code_prefix', 'CW',  '课件编号前缀',     'safety', 'string', '课件编号前缀（CW-YYYYMMDD-XXXX）', 52, 0, 1, NOW(), NOW()),
('training_max_file_size',          '50',  '课件最大文件大小（MB）', 'safety', 'number', '课件最大文件大小（MB）', 53, 0, 1, NOW(), NOW()),
('training_allowed_file_types',     'pdf,ppt,pptx,doc,docx,mp4,avi,mov', '允许上传的课件文件类型', 'safety', 'string', '允许上传的课件文件类型（逗号分隔）', 54, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 八、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('培训计划查看', 'safety:training:plan:list',   1, 0, '安全培训', '/safety/training/plan', 'el-icon-reading', NULL, 70, 1, 1, '查看培训计划', NOW(), NOW()),
('培训计划详情', 'safety:training:plan:query',  2, 0, '安全培训', '/safety/training/plan', NULL, NULL, 71, 1, 1, '查看培训计划详情', NOW(), NOW()),
('培训计划新增', 'safety:training:plan:add',    2, 0, '安全培训', '/safety/training/plan', NULL, NULL, 72, 1, 1, '新增培训计划', NOW(), NOW()),
('培训计划编辑', 'safety:training:plan:edit',   2, 0, '安全培训', '/safety/training/plan', NULL, NULL, 73, 1, 1, '编辑培训计划', NOW(), NOW()),
('培训计划删除', 'safety:training:plan:delete', 2, 0, '安全培训', '/safety/training/plan', NULL, NULL, 74, 1, 1, '删除培训计划', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 九、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:training:plan:list','safety:training:plan:query','safety:training:plan:add',
                   'safety:training:plan:edit','safety:training:plan:delete');

-- ========== 十、侧边栏菜单（安全培训下新增"培训计划"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '培训计划', '/safety/training/plan', 'el-icon-reading', 'safety:training:plan:list', 1, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:plan:list' AND x.`deleted_at` IS NULL);
