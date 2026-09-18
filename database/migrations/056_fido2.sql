-- =====================================================
-- 056_fido2.sql
-- FIDO2 硬件密钥登录（指定账号强制启用）：
--   users 新增字段 + settings_fido2 配置表 + settings_fido2_forced 强制对象表
--   + user_webauthn_credentials 凭证表 + 权限 + 菜单
-- 幂等写法，可重复执行。默认全局关闭（enabled=0），不影响现有登录流程。
-- =====================================================

-- ========== 一、users 新增字段（MySQL 兼容幂等写法） ==========
SET @sc_ex_f2 := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'fido2_enabled');
SET @sc_sql := IF(@sc_ex_f2 = 0, 'ALTER TABLE `users` ADD COLUMN `fido2_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''是否已绑定手机密钥'' AFTER `allow_login`', 'SELECT 1');
PREPARE sc_stmt FROM @sc_sql; EXECUTE sc_stmt; DEALLOCATE PREPARE sc_stmt;

SET @sc_ex_f2 := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'fido2_require');
SET @sc_sql := IF(@sc_ex_f2 = 0, 'ALTER TABLE `users` ADD COLUMN `fido2_require` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''是否强制启用（命中强制规则时落库标记）'' AFTER `fido2_enabled`', 'SELECT 1');
PREPARE sc_stmt FROM @sc_sql; EXECUTE sc_stmt; DEALLOCATE PREPARE sc_stmt;

SET @sc_ex_f2 := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'fido2_require_reason');
SET @sc_sql := IF(@sc_ex_f2 = 0, 'ALTER TABLE `users` ADD COLUMN `fido2_require_reason` varchar(100) DEFAULT NULL COMMENT ''强制启用原因'' AFTER `fido2_require`', 'SELECT 1');
PREPARE sc_stmt FROM @sc_sql; EXECUTE sc_stmt; DEALLOCATE PREPARE sc_stmt;

-- ========== 二、FIDO2 系统配置表（单行 id=1） ==========
CREATE TABLE IF NOT EXISTS `settings_fido2` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(1) DEFAULT 0 COMMENT '全局开关：0停用 1启用',
  `rp_id` varchar(100) DEFAULT NULL COMMENT 'RP ID（域名，空则取请求域名）',
  `rp_name` varchar(100) DEFAULT 'SC Admin' COMMENT 'RP显示名称',
  `user_verification` varchar(20) DEFAULT 'required' COMMENT '用户验证策略：required/preferred',
  `allow_remember_device` tinyint(1) DEFAULT 1 COMMENT '是否允许记住设备',
  `remember_days` int(11) DEFAULT 7 COMMENT '记住设备天数',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='FIDO2系统配置';

INSERT INTO `settings_fido2` (`id`,`enabled`,`rp_id`,`rp_name`,`user_verification`,`allow_remember_device`,`remember_days`,`created_at`,`updated_at`)
VALUES (1,0,NULL,'SC Admin','required',1,7,NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();

-- ========== 三、FIDO2 强制启用对象表 ==========
CREATE TABLE IF NOT EXISTS `settings_fido2_forced` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user/role/department',
  `target_id` int(11) NOT NULL COMMENT '目标ID（用户ID/角色ID/部门ID）',
  `reason` varchar(100) DEFAULT NULL COMMENT '强制原因说明',
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_target` (`target_type`, `target_id`),
  KEY `idx_target_type` (`target_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='FIDO2强制启用对象表';

-- ========== 四、WebAuthn 凭证表 ==========
CREATE TABLE IF NOT EXISTS `user_webauthn_credentials` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `credential_id` varchar(255) NOT NULL COMMENT '凭证ID',
  `public_key` text NOT NULL COMMENT '公钥（base64）',
  `sign_counter` int(11) DEFAULT 0 COMMENT '签名计数器',
  `device_name` varchar(100) DEFAULT '鸿蒙手机' COMMENT '设备名称',
  `aaguid` varchar(36) DEFAULT NULL COMMENT '认证器GUID',
  `transports` varchar(100) DEFAULT 'usb' COMMENT '传输方式',
  `last_used_at` datetime DEFAULT NULL COMMENT '最后使用时间',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_credential_id` (`credential_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='WebAuthn凭证表';

-- ========== 五、权限定义 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('FIDO2安全策略','settings:fido2:config',1,0,'安全设置','/settings/security/fido2','el-icon-key',NULL,40,1,1,'查看FIDO2安全策略配置与强制列表',NOW(),NOW()),
('FIDO2策略管理','settings:fido2:manage',2,0,'安全设置',NULL,NULL,NULL,41,1,1,'管理FIDO2强制启用规则',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- ========== 六、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('settings:fido2:config','settings:fido2:manage');

-- ========== 七、侧边栏菜单（系统设置下新增 FIDO2安全策略） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`, 'FIDO2安全策略', '/settings/security/fido2', 'el-icon-key', 'settings:fido2:config', 96, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission`='system:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='settings:fido2:config' AND x.`deleted_at` IS NULL);
