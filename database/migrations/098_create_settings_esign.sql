-- =====================================================
-- 098_create_settings_esign.sql
-- 系统设置 → 基础服务 → 电子签服务（腾讯电子签 API 对接）
--   1. 建表 3 张：settings_esign（配置）/ settings_esign_templates（模板）/ business_sign_logs（签署日志）
--   2. 权限：settings:services:esign（菜单）/ settings:services:esign:config（按钮）
--   3. 菜单：系统设置 → 基础服务 → 电子签服务
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、电子签服务配置表 ==========
CREATE TABLE IF NOT EXISTS `settings_esign` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `service_name` varchar(50) NOT NULL DEFAULT '腾讯电子签服务' COMMENT '服务名称',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '服务状态：1启用 0停用',
  `environment` varchar(20) NOT NULL DEFAULT 'test' COMMENT '环境：test测试 production生产',
  `secret_id` varchar(100) NOT NULL DEFAULT '' COMMENT '腾讯云API密钥ID',
  `secret_key` varchar(200) NOT NULL DEFAULT '' COMMENT '腾讯云API密钥（加密存储）',
  `app_id` varchar(100) NOT NULL DEFAULT '' COMMENT '电子签应用ID',
  `space_id` varchar(100) NOT NULL DEFAULT '' COMMENT '空间ID',
  `endpoint` varchar(200) NOT NULL DEFAULT '' COMMENT '接口域名（按环境自动填充）',
  `callback_url` varchar(200) NOT NULL DEFAULT '' COMMENT '回调地址',
  `encrypt_key` varchar(100) NOT NULL DEFAULT '' COMMENT '回调消息加密Key（加密存储）',
  `default_sign_type` varchar(20) NOT NULL DEFAULT 'manual' COMMENT '默认签署方式：silent静默 manual手动',
  `sign_expire_days` int(11) NOT NULL DEFAULT 7 COMMENT '签署到期天数',
  `notify_channels` json DEFAULT NULL COMMENT '签署通知渠道',
  `seal_id` varchar(100) DEFAULT NULL COMMENT '企业印章ID',
  `operator_user_id` varchar(100) DEFAULT NULL COMMENT '操作人UserId',
  `last_test_time` datetime DEFAULT NULL COMMENT '最后测试时间',
  `test_status` varchar(20) DEFAULT NULL COMMENT '测试状态：success/failed',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_service_name` (`service_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='腾讯电子签服务配置';

-- 初始化默认配置行（单行 id=1，与 U8/FIDO2 配置一致）
INSERT IGNORE INTO `settings_esign` (`id`,`service_name`,`status`,`environment`,`secret_id`,`secret_key`,`app_id`,`space_id`,`endpoint`,`callback_url`,`default_sign_type`,`sign_expire_days`,`notify_channels`,`create_time`,`update_time`)
VALUES (1,'腾讯电子签服务',1,'test','','','','','ess.test.ess.tencent.cn','/api/business/contract/sign/callback','manual',7,JSON_ARRAY('sms','wechat'),NOW(),NOW());

-- ========== 二、电子签模板表 ==========
CREATE TABLE IF NOT EXISTS `settings_esign_templates` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_id` varchar(100) NOT NULL DEFAULT '' COMMENT '模板ID（电子签平台）',
  `template_name` varchar(200) NOT NULL DEFAULT '' COMMENT '模板名称',
  `template_type` varchar(50) DEFAULT NULL COMMENT '模板类型',
  `description` varchar(500) DEFAULT NULL COMMENT '描述说明',
  `sync_time` datetime DEFAULT NULL COMMENT '同步时间',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_id` (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='电子签模板表';

-- ========== 三、电子签签署日志表 ==========
CREATE TABLE IF NOT EXISTS `business_sign_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) DEFAULT NULL COMMENT '合同ID（关联 business_contracts）',
  `contract_no` varchar(50) DEFAULT NULL COMMENT '合同编号',
  `flow_id` varchar(100) DEFAULT NULL COMMENT '签署流程ID（电子签平台）',
  `flow_name` varchar(200) DEFAULT NULL COMMENT '流程名称',
  `sign_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '签署状态：pending/signing/signed/expired/rejected',
  `sign_url` varchar(500) DEFAULT NULL COMMENT '签署链接',
  `operator_id` int(11) DEFAULT NULL COMMENT '操作人ID',
  `operator_name` varchar(50) DEFAULT NULL COMMENT '操作人姓名',
  `sign_time` datetime DEFAULT NULL COMMENT '签署完成时间',
  `callback_data` json DEFAULT NULL COMMENT '回调数据（完整通知）',
  `error_message` text COMMENT '错误信息',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_flow_id` (`flow_id`),
  KEY `idx_contract_id` (`contract_id`),
  KEY `idx_status_create` (`sign_status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='电子签签署日志表';

-- ========== 四、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('电子签服务','settings:services:esign',1,0,'settings','/settings/services/esign','el-icon-document-checked',NULL,41,1,1,'电子签服务-配置查看（菜单）',NOW(),NOW()),
('电子签服务配置','settings:services:esign:config',2,0,'settings',NULL,NULL,NULL,42,1,1,'保存配置/测试连接/同步模板',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('settings:services:esign','settings:services:esign:config');

-- ========== 五、菜单（系统设置 → 基础服务 → 电子签服务） ==========
-- 确保系统设置顶级菜单存在
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '系统设置', '', 'el-icon-setting', 'system:view', 90, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL);

-- 确保基础服务菜单存在（挂在系统设置下）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '基础服务', '/services', 'el-icon-connection', 'service:view', 10, 1, 2, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='基础服务' AND parent_id=(SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL);

SET @esign_parent_id = (SELECT id FROM menus WHERE name='基础服务' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) LIMIT 1);

-- 电子签服务页面
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @esign_parent_id, '电子签服务', '/settings/services/esign', 'el-icon-document-checked', 'settings:services:esign', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:services:esign' AND deleted_at IS NULL AND type=2);
