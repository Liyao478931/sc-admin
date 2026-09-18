-- 134_hot_update.sql
-- 热更新功能：system_versions 增字段 + 新表 system_hot_update_logs + 权限 + 配置种子
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM system_version_config WHERE config_key IN ('hot_update_enabled','hot_update_deploy_script','hot_update_notify_on_fail');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='settings:version:hot-update');
--   DELETE FROM permissions WHERE code='settings:version:hot-update';
--   DROP TABLE IF EXISTS system_hot_update_logs;
--   ALTER TABLE system_versions DROP COLUMN hot_update_log, DROP COLUMN hot_update_time, DROP COLUMN hot_update_status;

-- ========== 一、system_versions 增加热更新字段（幂等） ==========
SET @has_col = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='system_versions' AND COLUMN_NAME='hot_update_status');
SET @ddl = IF(@has_col=0, 'ALTER TABLE `system_versions` ADD COLUMN `hot_update_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''热更新状态 0待执行 1执行中 2已生效 3失败'' AFTER `is_current`', 'SELECT 1');
PREPARE stmt1 FROM @ddl; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;

SET @has_col = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='system_versions' AND COLUMN_NAME='hot_update_time');
SET @ddl = IF(@has_col=0, 'ALTER TABLE `system_versions` ADD COLUMN `hot_update_time` datetime DEFAULT NULL COMMENT ''热更新执行时间'' AFTER `hot_update_status`', 'SELECT 1');
PREPARE stmt2 FROM @ddl; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;

SET @has_col = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='system_versions' AND COLUMN_NAME='hot_update_log');
SET @ddl = IF(@has_col=0, 'ALTER TABLE `system_versions` ADD COLUMN `hot_update_log` text COMMENT ''热更新执行日志（JSON数组）'' AFTER `hot_update_time`', 'SELECT 1');
PREPARE stmt3 FROM @ddl; EXECUTE stmt3; DEALLOCATE PREPARE stmt3;

-- ========== 二、热更新执行日志表 ==========
CREATE TABLE IF NOT EXISTS `system_hot_update_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `version_id` int(11) NOT NULL DEFAULT 0 COMMENT '版本ID',
  `stage` tinyint(1) NOT NULL DEFAULT 1 COMMENT '执行阶段：1前端资源 2后端代码 3数据库迁移 4OpCache清除 5通知发送',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '执行状态：0待执行 1执行中 2成功 3失败',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `detail` text COMMENT '执行详情（JSON）',
  `error` varchar(1000) DEFAULT NULL COMMENT '错误信息',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_version_id` (`version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='热更新执行日志表';

-- ========== 三、权限：执行热更新 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('执行热更新','settings:version:hot-update',2,0,'version',NULL,NULL,NULL,16,1,1,'执行热更新（前端资源/后端代码/数据库迁移/OpCache清除/通知）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='settings:version:hot-update';

-- ========== 四、热更新配置种子 ==========
INSERT INTO `system_version_config` (`config_key`,`config_value`,`group_name`,`description`,`status`,`create_time`,`update_time`) VALUES
('hot_update_enabled','1','hot_update','热更新总开关：1启用 0停用',1,NOW(),NOW()),
('hot_update_deploy_script','','hot_update','热更新部署脚本绝对路径（可选；未配置时前端构建/后端部署/数据库迁移阶段跳过，由运维人工执行）',1,NOW(),NOW()),
('hot_update_notify_on_fail','1','hot_update','热更新失败是否通知运维：1是 0否',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE
`config_value`=VALUES(`config_value`),`group_name`=VALUES(`group_name`),
`description`=VALUES(`description`),`status`=VALUES(`status`),`update_time`=NOW();
