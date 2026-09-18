-- 135_version_policy_rollback_tasks.sql
-- 四项增强：更新策略配置 + 回滚异步任务
-- 1. 新表 system_rollback_tasks（回滚异步任务）
-- 2. version.policy.* 配置种子（9 个）
-- 3. 权限 settings:version:policy:view
-- 4. 菜单「更新策略」挂入版本管理目录
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='settings:version:policy:view' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='settings:version:policy:view');
--   DELETE FROM permissions WHERE code='settings:version:policy:view';
--   DELETE FROM system_version_config WHERE config_key LIKE 'version.policy.%';
--   DROP TABLE IF EXISTS system_rollback_tasks;

-- ========== 一、回滚任务表 ==========
CREATE TABLE IF NOT EXISTS `system_rollback_tasks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` varchar(40) NOT NULL DEFAULT '' COMMENT '回滚任务ID',
  `version_id` int(11) NOT NULL DEFAULT 0 COMMENT '目标版本ID',
  `from_version` varchar(20) NOT NULL DEFAULT '' COMMENT '原版本号',
  `to_version` varchar(20) NOT NULL DEFAULT '' COMMENT '目标版本号',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '任务状态：pending/running/success/failed',
  `total_stages` tinyint(1) NOT NULL DEFAULT 4 COMMENT '总阶段数',
  `completed_stages` tinyint(1) NOT NULL DEFAULT 0 COMMENT '已完成阶段数',
  `current_stage` tinyint(1) NOT NULL DEFAULT 0 COMMENT '当前阶段',
  `stages` text COMMENT '阶段进度（JSON数组）',
  `error` varchar(1000) DEFAULT NULL COMMENT '错误信息',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_version_id` (`version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='版本回滚任务表';

-- ========== 二、更新策略配置种子 ==========
INSERT INTO `system_version_config` (`config_key`,`config_value`,`group_name`,`description`,`status`,`create_time`,`update_time`) VALUES
('version.policy.enabled','1','version_policy','版本检测总开关：1启用 0停用',1,NOW(),NOW()),
('version.policy.interval','5','version_policy','轮询间隔（分钟），推荐5-10',1,NOW(),NOW()),
('version.policy.update_mode','prompt','version_policy','更新模式：prompt提示用户 / auto自动刷新 / silent静默更新',1,NOW(),NOW()),
('version.policy.notification_enabled','1','version_policy','通知横幅开关：1启用 0停用',1,NOW(),NOW()),
('version.policy.notification_duration','30','version_policy','横幅显示时长（秒），0永久',1,NOW(),NOW()),
('version.policy.auto_refresh_delay','3','version_policy','自动刷新延迟（秒）',1,NOW(),NOW()),
('version.policy.whitelist_enabled','0','version_policy','灰度发布白名单开关：1启用 0停用',1,NOW(),NOW()),
('version.policy.whitelist_users','[]','version_policy','灰度用户ID列表（JSON数组）',1,NOW(),NOW()),
('version.policy.hot_update_timeout','300','version_policy','热更新超时时间（秒）',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE
`group_name`=VALUES(`group_name`),`description`=VALUES(`description`),
`status`=VALUES(`status`),`update_time`=NOW();

-- ========== 三、权限：更新策略配置 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('更新策略配置','settings:version:policy:view',2,0,'version','/settings/version/policy','el-icon-setting',NULL,17,1,1,'版本更新策略配置（菜单）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='settings:version:policy:view';

-- ========== 四、菜单：版本管理目录 -> 更新策略 ==========
SET @version_dir_id = (SELECT id FROM menus WHERE permission='settings:version' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @version_dir_id, '更新策略', '/settings/version/policy', 'el-icon-setting', 'settings:version:policy:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:version:policy:view' AND deleted_at IS NULL AND parent_id=@version_dir_id);
