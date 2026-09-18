-- =====================================================
-- 037_create_safety_training_archive.sql
-- 培训档案 + 证书：证书表 + 证书模板表 + 字典 + 参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、培训证书表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_certificate` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `certificate_code`   varchar(50)  NOT NULL COMMENT '证书编号 CERT-YYYYMMDD-XXXX',
  `user_id`            int(11)      NOT NULL COMMENT '员工ID',
  `user_name`          varchar(50)  NOT NULL COMMENT '员工姓名（冗余）',
  `record_id`          int(11)      NOT NULL COMMENT '培训记录ID',
  `training_name`      varchar(100) NOT NULL COMMENT '培训名称（冗余）',
  `training_type_id`   int(11)      NOT NULL COMMENT '培训类型ID',
  `training_type_name` varchar(50)  DEFAULT NULL COMMENT '培训类型名称（冗余）',
  `certificate_name`   varchar(100) NOT NULL COMMENT '证书名称',
  `issue_date`         date         NOT NULL COMMENT '颁发日期',
  `expire_date`        date         DEFAULT NULL COMMENT '有效期截止日期（NULL=长期）',
  `validity_years`     int(11)      NOT NULL DEFAULT 0 COMMENT '有效年限，0=长期有效',
  `status`             varchar(20)  NOT NULL DEFAULT 'valid' COMMENT '状态 valid有效 expired过期',
  `certificate_data`   json         DEFAULT NULL COMMENT '证书数据',
  `file_path`          varchar(255) DEFAULT NULL COMMENT '证书文件路径',
  `create_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_certificate_code` (`certificate_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_record_id` (`record_id`),
  KEY `idx_status` (`status`),
  KEY `idx_expire_date` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训证书';

-- ========== 二、证书模板表 ==========
CREATE TABLE IF NOT EXISTS `safety_certificate_template` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_code`      varchar(50)  NOT NULL COMMENT '模板编号 TPL-YYYYMMDD-XXXX',
  `template_name`      varchar(100) NOT NULL COMMENT '模板名称',
  `training_type_id`   int(11)      DEFAULT NULL COMMENT '适用培训类型ID',
  `certificate_name`   varchar(100) NOT NULL COMMENT '证书名称',
  `validity_years`     int(11)      NOT NULL DEFAULT 0 COMMENT '有效年限，0=长期有效',
  `template_data`      json         DEFAULT NULL COMMENT '模板数据（样式配置）',
  `status`             tinyint(1)   NOT NULL DEFAULT 1 COMMENT '状态 1启用 0停用',
  `create_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`),
  KEY `idx_training_type_id` (`training_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='证书模板';

-- ========== 三、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('证书状态','certificate_status','培训证书状态',84,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='certificate_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'有效','valid',1,'success',1,NOW(),NOW()),
(@dt1,'过期','expired',2,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('证书模板状态','certificate_template_status','证书模板状态',85,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='certificate_template_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'启用','active',1,'success',1,NOW(),NOW()),
(@dt2,'停用','inactive',2,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 四、系统参数 ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('certificate_code_prefix',         'CERT', NOW(), NOW()),
('certificate_auto_generate',       'true', NOW(), NOW()),
('certificate_expire_remind_days',  '30',   NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('certificate_code_prefix',        'CERT', '证书编号前缀',          'safety', 'string',  '证书编号前缀（CERT-YYYYMMDD-XXXX）', 60, 0, 1, NOW(), NOW()),
('certificate_auto_generate',      'true', '培训完成自动生成证书',   'safety', 'boolean', '培训完成时自动生成证书',             61, 0, 1, NOW(), NOW()),
('certificate_expire_remind_days', '30',   '证书过期提醒天数',      'safety', 'number',  '证书即将过期提醒天数',               62, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('培训档案查看',   'safety:training:archive:list',      1, 0, '安全培训', '/safety/training/archive', 'el-icon-files', NULL, 90, 1, 1, '查看培训档案', NOW(), NOW()),
('培训档案详情',   'safety:training:archive:query',     2, 0, '安全培训', '/safety/training/archive', NULL, NULL, 91, 1, 1, '查看档案详情/履历', NOW(), NOW()),
('培训档案导出',   'safety:training:archive:export',    2, 0, '安全培训', '/safety/training/archive', NULL, NULL, 92, 1, 1, '导出培训履历', NOW(), NOW()),
('证书列表查看',   'safety:training:certificate:list',  1, 0, '安全培训', '/safety/training/certificate', NULL, NULL, 93, 1, 1, '查看培训证书', NOW(), NOW()),
('证书生成',       'safety:training:certificate:add',   2, 0, '安全培训', '/safety/training/certificate', NULL, NULL, 94, 1, 1, '生成培训证书', NOW(), NOW()),
('证书导出',       'safety:training:certificate:export', 2, 0, '安全培训', '/safety/training/certificate', NULL, NULL, 95, 1, 1, '导出培训证书', NOW(), NOW()),
('证书模板配置',   'safety:training:certificate:config', 2, 0, '安全培训', '/safety/training/certificate', NULL, NULL, 96, 1, 1, '配置证书模板', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 六、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:training:archive:list','safety:training:archive:query','safety:training:archive:export',
                   'safety:training:certificate:list','safety:training:certificate:add','safety:training:certificate:export','safety:training:certificate:config');

-- ========== 七、侧边栏菜单（安全培训下新增"培训档案"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '培训档案', '/safety/training/archive', 'el-icon-files', 'safety:training:archive:list', 3, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:archive:list' AND x.`deleted_at` IS NULL);

-- 证书管理（hidden 子页面）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '证书管理', '/safety/training/certificate', 'el-icon-medal', 'safety:training:certificate:list', 4, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:certificate:list' AND x.`deleted_at` IS NULL);
