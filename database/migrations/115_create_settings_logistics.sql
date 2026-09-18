-- 115_create_settings_logistics.sql
-- 系统设置 -> 基础服务 -> 物流服务
-- 1. 建表：settings_logistics（物流服务配置）/ logistics_call_logs（物流调用日志）
-- 2. business_purchase_order 增加物流跟踪字段（供推送回调更新，验收标准12）
-- 3. 权限：settings:services:logistics:view / edit / test 并授权 super_admin
-- 4. 菜单：系统设置 -> 基础服务 -> 物流服务
-- 幂等写法，可重复执行（ALTER 由执行脚本 catch Duplicate column）
-- 回滚 down：
--   DELETE FROM menus WHERE permission='settings:services:logistics:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'settings:services:logistics:%');
--   DELETE FROM permissions WHERE code LIKE 'settings:services:logistics:%';
--   DROP TABLE IF EXISTS logistics_call_logs;
--   DROP TABLE IF EXISTS settings_logistics;
--   ALTER TABLE business_purchase_order
--     DROP COLUMN logistics_updated_at, DROP COLUMN logistics_status_label,
--     DROP COLUMN logistics_status, DROP COLUMN express_name,
--     DROP COLUMN express_code, DROP COLUMN track_no;

-- ========== 一、物流服务配置表 ==========
CREATE TABLE IF NOT EXISTS `settings_logistics` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `provider_code` varchar(30) NOT NULL DEFAULT '' COMMENT '服务商标识：kdniao/kuaidi100/aliyun_express/aliyun_cainiao',
  `provider_name` varchar(50) NOT NULL DEFAULT '' COMMENT '服务商名称（显示用）',
  `app_key` varchar(200) NOT NULL DEFAULT '' COMMENT 'API Key（加密存储）',
  `app_secret` varchar(200) NOT NULL DEFAULT '' COMMENT 'API Secret（加密存储）',
  `app_code` varchar(200) NOT NULL DEFAULT '' COMMENT '阿里云市场AppCode（仅阿里云服务商，加密存储）',
  `api_url` varchar(255) NOT NULL DEFAULT '' COMMENT 'API请求地址',
  `callback_url` varchar(255) NOT NULL DEFAULT '' COMMENT '订阅推送回调地址（系统自动生成）',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认服务商：1是 0否',
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用：1启用 0停用',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_provider` (`provider_code`),
  KEY `idx_default` (`is_default`),
  KEY `idx_enabled` (`is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物流服务配置表';

-- ========== 二、物流调用日志表 ==========
CREATE TABLE IF NOT EXISTS `logistics_call_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `provider_code` varchar(30) NOT NULL DEFAULT '' COMMENT '调用的服务商',
  `api_method` varchar(30) NOT NULL DEFAULT '' COMMENT '调用方法：query/subscribe/callback',
  `request_params` text COMMENT '请求参数（JSON）',
  `response_data` text COMMENT '返回数据（JSON）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '调用状态：1成功 0失败',
  `error_message` varchar(255) DEFAULT NULL COMMENT '错误信息',
  `ip` varchar(50) DEFAULT NULL COMMENT '调用方IP',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_provider` (`provider_code`),
  KEY `idx_status` (`status`),
  KEY `idx_create` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物流调用日志表';

-- ========== 三、采购订单增加物流跟踪字段（回调更新） ==========
ALTER TABLE `business_purchase_order`
  ADD COLUMN `track_no` varchar(60) DEFAULT NULL COMMENT '物流单号' AFTER `transport_type`,
  ADD COLUMN `express_code` varchar(30) DEFAULT NULL COMMENT '快递公司编码（标准码）' AFTER `track_no`,
  ADD COLUMN `express_name` varchar(50) DEFAULT NULL COMMENT '快递公司名称' AFTER `express_code`,
  ADD COLUMN `logistics_status` varchar(30) DEFAULT NULL COMMENT '物流状态：pending/transporting/delivering/delivered/exception' AFTER `express_name`,
  ADD COLUMN `logistics_status_label` varchar(50) DEFAULT NULL COMMENT '物流状态标签' AFTER `logistics_status`,
  ADD COLUMN `logistics_updated_at` datetime DEFAULT NULL COMMENT '物流状态更新时间' AFTER `logistics_status_label`;

-- ========== 四、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('物流服务','settings:services:logistics:view',1,0,'settings','/settings/services/logistics','el-icon-truck',NULL,43,1,1,'物流服务-配置查看/轨迹查询（菜单）',NOW(),NOW()),
('物流服务编辑','settings:services:logistics:edit',2,0,'settings',NULL,NULL,NULL,44,1,1,'保存配置/删除/设为默认/启用停用',NOW(),NOW()),
('物流服务测试','settings:services:logistics:test',2,0,'settings',NULL,NULL,NULL,45,1,1,'测试连接',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('settings:services:logistics:view','settings:services:logistics:edit','settings:services:logistics:test');

-- ========== 五、菜单（系统设置 -> 基础服务 -> 物流服务） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '系统设置', '', 'el-icon-setting', 'system:view', 90, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '基础服务', '/services', 'el-icon-connection', 'service:view', 10, 1, 2, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='基础服务' AND parent_id=(SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL);

SET @logistics_parent_id = (SELECT id FROM menus WHERE name='基础服务' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @logistics_parent_id, '物流服务', '/settings/services/logistics', 'el-icon-truck', 'settings:services:logistics:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:services:logistics:view' AND deleted_at IS NULL AND type=2);
