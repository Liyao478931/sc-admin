-- =====================================================
-- 081_create_security_policy.sql
-- 安全策略模块（系统设置 → 安全设置 → 安全策略）
--   1. 三张核心表：system_security_policies / system_sensitive_words / system_ip_whitelist
--   2. 数据字典（分组/类型/敏感词分类/严重程度）
--   3. 系统参数（缓存键）
--   4. 预置安全策略数据
--   5. 权限定义与超级管理员授权
--   6. 侧边栏菜单（系统设置 → 安全策略）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、三张核心表 ==========
CREATE TABLE IF NOT EXISTS `system_security_policies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `policy_key` varchar(100) NOT NULL COMMENT '策略键（如 password_min_length）',
  `policy_name` varchar(100) NOT NULL COMMENT '策略名称',
  `policy_value` text COMMENT '策略值（复杂配置用JSON存储）',
  `policy_type` varchar(20) NOT NULL DEFAULT 'string' COMMENT '策略类型：string/number/boolean/json/text',
  `group` varchar(30) NOT NULL DEFAULT 'other' COMMENT '策略分组：password/login/session/ip_whitelist/data/ai/notification/other',
  `description` varchar(255) DEFAULT NULL COMMENT '策略描述',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `is_system` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否系统内置：1是0否',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_policy_key` (`policy_key`),
  KEY `idx_group` (`group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全策略配置表';

CREATE TABLE IF NOT EXISTS `system_sensitive_words` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `word` varchar(100) NOT NULL COMMENT '敏感词',
  `category` varchar(30) DEFAULT NULL COMMENT '分类：political/porn/violence/ad/other',
  `severity` varchar(20) NOT NULL DEFAULT 'medium' COMMENT '严重程度：low/medium/high/critical',
  `replace_with` varchar(100) DEFAULT NULL COMMENT '替换词（为空则替换为***）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_word` (`word`),
  KEY `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='敏感词表';

CREATE TABLE IF NOT EXISTS `system_ip_whitelist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(50) NOT NULL COMMENT 'IP或CIDR网段（如 192.168.1.0/24）',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `user_id` int(11) DEFAULT NULL COMMENT '关联用户ID（空为全局白名单）',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间（空为永不过期）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ip_address` (`ip_address`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IP白名单表';

-- ========== 二、数据字典 ==========

-- 1. security_policy_group 安全策略分组
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('安全策略分组','security_policy_group','安全策略配置分组',90,1,NOW(),NOW());
SET @dt1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='security_policy_group' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt1,'密码策略','password',1,'',1,NOW(),NOW()),
(@dt1,'登录安全','login',2,'',1,NOW(),NOW()),
(@dt1,'会话安全','session',3,'',1,NOW(),NOW()),
(@dt1,'IP白名单','ip_whitelist',4,'',1,NOW(),NOW()),
(@dt1,'数据安全','data',5,'',1,NOW(),NOW()),
(@dt1,'AI安全','ai',6,'',1,NOW(),NOW()),
(@dt1,'安全通知','notification',7,'',1,NOW(),NOW()),
(@dt1,'其他','other',8,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. security_policy_type 策略类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('策略类型','security_policy_type','安全策略值类型',91,1,NOW(),NOW());
SET @dt2 = (SELECT `id` FROM `dictionary_types` WHERE `code`='security_policy_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt2,'字符串','string',1,'',1,NOW(),NOW()),
(@dt2,'数字','number',2,'',1,NOW(),NOW()),
(@dt2,'布尔','boolean',3,'',1,NOW(),NOW()),
(@dt2,'JSON','json',4,'',1,NOW(),NOW()),
(@dt2,'文本','text',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. sensitive_word_category 敏感词分类
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('敏感词分类','sensitive_word_category','AI敏感词分类',92,1,NOW(),NOW());
SET @dt3 = (SELECT `id` FROM `dictionary_types` WHERE `code`='sensitive_word_category' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt3,'政治','political',1,'danger',1,NOW(),NOW()),
(@dt3,'色情','porn',2,'danger',1,NOW(),NOW()),
(@dt3,'暴力','violence',3,'warning',1,NOW(),NOW()),
(@dt3,'广告','ad',4,'',1,NOW(),NOW()),
(@dt3,'其他','other',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 4. sensitive_word_severity 敏感词严重程度
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('敏感词严重程度','sensitive_word_severity','敏感词严重程度',93,1,NOW(),NOW());
SET @dt4 = (SELECT `id` FROM `dictionary_types` WHERE `code`='sensitive_word_severity' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt4,'低','low',1,'',1,NOW(),NOW()),
(@dt4,'中','medium',2,'warning',1,NOW(),NOW()),
(@dt4,'高','high',3,'danger',1,NOW(),NOW()),
(@dt4,'严重','critical',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('security_policy_cache_key','安全策略缓存Key','security_policies','string','system','安全策略配置缓存键名',1,1,0,NOW(),NOW()),
('security_policy_cache_ttl','安全策略缓存时间（秒）','3600','number','system','安全策略缓存有效期，单位秒',2,1,0,NOW(),NOW()),
('security_sensitive_words_cache_key','敏感词缓存Key','sensitive_words','string','system','敏感词列表缓存键名',3,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、预置安全策略数据 ==========
INSERT INTO `system_security_policies`
(`policy_key`,`policy_name`,`policy_value`,`policy_type`,`group`,`description`,`sort`,`is_system`,`status`,`create_time`,`update_time`) VALUES
-- 一、密码策略
('password_min_length','密码最小长度','8','number','password','密码最短长度（6-32）',1,1,1,NOW(),NOW()),
('password_complexity','密码复杂度要求','["uppercase","lowercase","number"]','json','password','密码必须包含的字符类型',2,1,1,NOW(),NOW()),
('password_expire_days','密码有效期（天）','90','number','password','密码有效期，0为永不过期',3,1,1,NOW(),NOW()),
('password_history_count','密码历史限制次数','5','number','password','禁止重复使用最近N次密码',4,1,1,NOW(),NOW()),
('password_fail_lock_count','失败锁定次数','5','number','password','连续失败N次后锁定',5,1,1,NOW(),NOW()),
('password_lock_duration','锁定持续时间（分钟）','30','number','password','锁定持续时长',6,1,1,NOW(),NOW()),
('password_first_login_change','首次登录强制修改密码','true','boolean','password','首次登录是否强制修改密码',7,1,1,NOW(),NOW()),
-- 二、登录安全
('login_captcha_enabled','验证码开关','true','boolean','login','启用/停用登录验证码',1,1,1,NOW(),NOW()),
('login_mfa_enabled','多因素认证开关','false','boolean','login','启用/停用多因素认证',2,1,1,NOW(),NOW()),
('login_mfa_scope','多因素认证强制范围','admin','string','login','多因素认证强制范围',3,1,1,NOW(),NOW()),
('login_location_alert','异地登录提醒','true','boolean','login','异地登录时发送提醒',4,1,1,NOW(),NOW()),
('login_fail_alert','登录失败提醒','true','boolean','login','登录失败时发送提醒',5,1,1,NOW(),NOW()),
('login_fail_log_retention','登录失败记录保留天数','30','number','login','登录失败日志保留天数',6,1,1,NOW(),NOW()),
-- 三、会话安全
('session_timeout','会话超时时间（分钟）','60','number','session','会话超时时间',1,1,1,NOW(),NOW()),
('session_max_concurrent','最大并发登录数','1','number','session','同一账号最大同时登录设备数，0不限制',2,1,1,NOW(),NOW()),
('session_sso_enabled','单点登录强制开关','false','boolean','session','开启后新登录踢掉旧会话',3,1,1,NOW(),NOW()),
('session_remember_days','记住设备天数','7','number','session','记住设备有效期天数',4,1,1,NOW(),NOW()),
('session_idle_detect','会话空闲检测','true','boolean','session','检测用户闲置状态',5,1,1,NOW(),NOW()),
('session_idle_alert_minutes','闲置超时提醒（分钟）','5','number','session','会话超时前提醒分钟数',6,1,1,NOW(),NOW()),
-- 四、IP白名单
('ip_whitelist_enabled','IP白名单开关','false','boolean','ip_whitelist','启用/停用IP白名单限制',1,1,1,NOW(),NOW()),
('ip_whitelist_mode','白名单模式','strict','string','ip_whitelist','strict=仅白名单IP访问；trusted=白名单IP免验证',2,1,1,NOW(),NOW()),
-- 五、数据安全
('data_encryption_enabled','数据加密开关','true','boolean','data','敏感数据加密存储',1,1,1,NOW(),NOW()),
('data_export_max_rows','单次导出最大条数','10000','number','data','单次导出最大条数',2,1,1,NOW(),NOW()),
('data_log_retention_days','日志保留天数','180','number','data','各类日志保留天数',3,1,1,NOW(),NOW()),
-- 六、AI安全策略
('ai_enabled','AI调用开关','true','boolean','ai','AI功能全局开关',1,1,1,NOW(),NOW()),
('ai_input_detection','AI输入内容安全检测','true','boolean','ai','检测用户输入敏感内容/提示注入',2,1,1,NOW(),NOW()),
('ai_output_detection','AI输出内容安全检测','true','boolean','ai','检测AI输出敏感/有害内容',3,1,1,NOW(),NOW()),
('ai_tool_control','工具调用安全控制','true','boolean','ai','AI调用工具需安全审核',4,1,1,NOW(),NOW()),
('ai_token_budget_daily','每日Token预算','1000000','number','ai','每日Token消耗上限',5,1,1,NOW(),NOW()),
('ai_token_budget_monthly','每月Token预算','30000000','number','ai','每月Token消耗上限',6,1,1,NOW(),NOW()),
('ai_audit_enabled','AI操作审计日志','true','boolean','ai','记录所有AI调用和工具调用日志',7,1,1,NOW(),NOW()),
-- 七、安全通知
('notify_channels','安全事件通知渠道','["inbox","email"]','json','notification','安全事件通知渠道',1,1,1,NOW(),NOW()),
('notify_abnormal_login','异常登录通知','true','boolean','notification','异常登录时发送通知',2,1,1,NOW(),NOW()),
('notify_password_change','密码变更通知','true','boolean','notification','密码变更时发送通知',3,1,1,NOW(),NOW()),
('notify_permission_change','权限变更通知','true','boolean','notification','权限变更时发送通知',4,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `policy_name`=VALUES(`policy_name`),`policy_value`=VALUES(`policy_value`),`policy_type`=VALUES(`policy_type`),`group`=VALUES(`group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`update_time`=NOW();

-- ========== 五、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('安全策略','settings:security:policy',1,0,'安全设置','/settings/security/policy','el-icon-shield',NULL,94,1,1,'查看安全策略配置',NOW(),NOW()),
('安全策略编辑','settings:security:policy:edit',2,0,'安全设置',NULL,NULL,NULL,95,1,1,'编辑安全策略/敏感词/IP白名单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('settings:security:policy','settings:security:policy:edit');

-- ========== 六、侧边栏菜单（系统设置 → 安全策略） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`, '安全策略', '/settings/security/policy', 'el-icon-shield', 'settings:security:policy', 95, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission`='system:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='settings:security:policy' AND x.`deleted_at` IS NULL);
