-- =====================================================
-- 099_add_contract_sign.sql
-- 合同管理 - 电子签章闭环增量
--   1. business_contracts 新增签署字段（sign_status/sign_flow_id/sign_url/sign_time/sign_log/file_id）
--   2. 建表 business_sign_callback_logs（签署回调日志）
--   3. 字典 sign_status（签署状态）
--   4. 参数 contract_sign_expire_days（签署链接有效期天数）
--   5. 权限 business:contract:sign（发起签署/获取链接/重发通知）
-- 幂等写法，可重复执行（字段存在性经 information_schema 判断，兼容 PDO/phpMyAdmin）
-- =====================================================

-- ========== 一、business_contracts 新增签署字段（逐字段判断） ==========
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='sign_status');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `sign_status` varchar(20) NOT NULL DEFAULT ''pending'' COMMENT ''签署状态'' AFTER `contract_status`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='sign_flow_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `sign_flow_id` varchar(100) DEFAULT NULL COMMENT ''签署流程ID'' AFTER `sign_status`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='sign_url');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `sign_url` varchar(500) DEFAULT NULL COMMENT ''签署链接'' AFTER `sign_flow_id`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='sign_time');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `sign_time` datetime DEFAULT NULL COMMENT ''签署完成时间'' AFTER `sign_url`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='sign_log');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `sign_log` json DEFAULT NULL COMMENT ''签署日志'' AFTER `sign_time`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='file_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `file_id` varchar(100) DEFAULT NULL COMMENT ''合同文件ID'' AFTER `sign_log`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 补充签署状态索引
SET @idx := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND INDEX_NAME='idx_sign_status');
SET @sql := IF(@idx > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD KEY `idx_sign_status` (`sign_status`)');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 二、签署回调日志表 ==========
CREATE TABLE IF NOT EXISTS `business_sign_callback_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `flow_id` varchar(100) NOT NULL DEFAULT '' COMMENT '签署流程ID',
  `contract_id` int(11) DEFAULT NULL COMMENT '合同ID',
  `contract_no` varchar(50) DEFAULT NULL COMMENT '合同编号',
  `callback_data` json DEFAULT NULL COMMENT '完整回调数据',
  `sign_status` varchar(20) DEFAULT NULL COMMENT '签署状态',
  `sign_time` datetime DEFAULT NULL COMMENT '签署完成时间',
  `file_url` varchar(500) DEFAULT NULL COMMENT '签署文件下载地址',
  `processed` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已处理：1是 0否',
  `process_time` datetime DEFAULT NULL COMMENT '处理时间',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_flow_id` (`flow_id`),
  KEY `idx_contract_id` (`contract_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='签署回调日志表';

-- ========== 三、数据字典：签署状态 sign_status ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('签署状态','sign_status','合同管理-签署状态',142,1,NOW(),NOW());
SET @dt_ss = (SELECT `id` FROM `dictionary_types` WHERE `code`='sign_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_ss,'待签署','pending',1,'warning',1,NOW(),NOW()),
(@dt_ss,'签署中','signing',2,'primary',1,NOW(),NOW()),
(@dt_ss,'已签署','signed',3,'success',1,NOW(),NOW()),
(@dt_ss,'已过期','expired',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 四、系统参数：签署链接有效期天数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('contract_sign_expire_days','签署链接有效期天数','7','number','business','合同签署链接有效期天数',11,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 五、权限：合同签署 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('合同签署','business:contract:sign',2,0,'business',NULL,NULL,NULL,41,1,1,'发起签署/获取签署链接/重发通知',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='business:contract:sign';
