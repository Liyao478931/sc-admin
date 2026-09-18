-- =====================================================
-- 087_create_ai_datasource.sql
-- AI 智能平台：知识库 → 数据源管理
--   1. 两张核心表：ai_datasources（数据源）/ ai_datasource_sync_logs（同步日志）
--   2. 数据字典（数据源类型/数据源状态/同步状态）
--   3. 系统参数（同步批次/超时/预览条数/重试次数）
--   4. 权限（ai:knowledge:datasource 系列）
--   5. 菜单（知识库 → 数据源管理）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、两张核心表 ==========
CREATE TABLE IF NOT EXISTS `ai_datasources` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ds_id` varchar(32) NOT NULL DEFAULT '' COMMENT '数据源唯一标识(UUID)',
  `ds_name` varchar(100) NOT NULL DEFAULT '' COMMENT '数据源名称',
  `ds_type` varchar(30) NOT NULL DEFAULT '' COMMENT '类型：database/api/webpage/filesystem/message_queue/file',
  `kb_id` varchar(32) NOT NULL DEFAULT '' COMMENT '关联知识库ID',
  `config` json NOT NULL COMMENT '数据源配置(JSON，按类型不同)',
  `sync_config` json DEFAULT NULL COMMENT '同步配置(JSON：频率/增量/预处理)',
  `field_mapping` json DEFAULT NULL COMMENT '字段映射(JSON：源字段→知识库字段)',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `sync_status` varchar(20) NOT NULL DEFAULT 'idle' COMMENT '同步状态：idle/syncing/success/failed',
  `last_sync_time` datetime DEFAULT NULL COMMENT '最后同步时间',
  `last_sync_count` int(11) NOT NULL DEFAULT 0 COMMENT '最后同步记录数',
  `total_sync_count` int(11) NOT NULL DEFAULT 0 COMMENT '总同步记录数',
  `sync_count` int(11) NOT NULL DEFAULT 0 COMMENT '同步次数',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ds_id` (`ds_id`),
  KEY `idx_kb_id` (`kb_id`),
  KEY `idx_creator_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI数据源表';

CREATE TABLE IF NOT EXISTS `ai_datasource_sync_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` varchar(32) NOT NULL DEFAULT '' COMMENT '日志唯一标识(UUID)',
  `ds_id` varchar(32) NOT NULL DEFAULT '' COMMENT '数据源ID（关联 ai_datasources）',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `duration` int(11) DEFAULT NULL COMMENT '执行耗时（毫秒）',
  `total_count` int(11) NOT NULL DEFAULT 0 COMMENT '总记录数',
  `success_count` int(11) NOT NULL DEFAULT 0 COMMENT '成功记录数',
  `failed_count` int(11) NOT NULL DEFAULT 0 COMMENT '失败记录数',
  `skipped_count` int(11) NOT NULL DEFAULT 0 COMMENT '跳过记录数',
  `status` varchar(20) NOT NULL DEFAULT 'running' COMMENT '状态：running/success/failed',
  `error_message` text COMMENT '错误信息',
  `error_details` json DEFAULT NULL COMMENT '错误详情(JSON，失败记录详细信息)',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_id` (`log_id`),
  KEY `idx_ds_create` (`ds_id`, `create_time`),
  KEY `idx_status_create` (`status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI数据源同步日志表';

-- ========== 二、数据字典 ==========

-- 1. datasource_type 数据源类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('数据源类型','datasource_type','AI数据源类型',91,1,NOW(),NOW());
SET @dd1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='datasource_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dd1,'数据库','database',1,'primary',1,NOW(),NOW()),
(@dd1,'API','api',2,'success',1,NOW(),NOW()),
(@dd1,'网页','webpage',3,'warning',1,NOW(),NOW()),
(@dd1,'文件系统','filesystem',4,'info',1,NOW(),NOW()),
(@dd1,'消息队列','message_queue',5,'danger',1,NOW(),NOW()),
(@dd1,'文件','file',6,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. datasource_status 数据源状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('数据源状态','datasource_status','AI数据源状态',92,1,NOW(),NOW());
SET @dd2 = (SELECT `id` FROM `dictionary_types` WHERE `code`='datasource_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dd2,'已配置','config',1,'primary',1,NOW(),NOW()),
(@dd2,'已启用','enabled',2,'success',1,NOW(),NOW()),
(@dd2,'已停用','disabled',3,'info',1,NOW(),NOW()),
(@dd2,'异常','error',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. datasource_sync_status 同步状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('同步状态','datasource_sync_status','AI数据源同步状态',93,1,NOW(),NOW());
SET @dd3 = (SELECT `id` FROM `dictionary_types` WHERE `code`='datasource_sync_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dd3,'空闲','idle',1,'info',1,NOW(),NOW()),
(@dd3,'同步中','syncing',2,'warning',1,NOW(),NOW()),
(@dd3,'成功','success',3,'success',1,NOW(),NOW()),
(@dd3,'失败','failed',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('datasource_sync_batch_size','同步批次大小','100','number','ai','数据源同步每次写入批次大小',50,1,0,NOW(),NOW()),
('datasource_sync_timeout_minutes','同步超时时间（分钟）','30','number','ai','数据源同步超时时间',51,1,0,NOW(),NOW()),
('datasource_max_preview_records','数据预览最大条数','10','number','ai','数据源预览最大记录数',52,1,0,NOW(),NOW()),
('datasource_retry_max_times','同步失败最大重试次数','3','number','ai','同步失败自动重试次数',53,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('数据源管理','ai:knowledge:datasource',1,0,'ai','/ai/knowledge/datasource','el-icon-connection',NULL,3,1,1,'数据源管理查看',NOW(),NOW()),
('数据源新增','ai:knowledge:datasource:add',2,0,'ai',NULL,NULL,NULL,4,1,1,'新增数据源',NOW(),NOW()),
('数据源编辑','ai:knowledge:datasource:edit',2,0,'ai',NULL,NULL,NULL,5,1,1,'编辑/启停/测试/预览数据源',NOW(),NOW()),
('数据源删除','ai:knowledge:datasource:delete',2,0,'ai',NULL,NULL,NULL,6,1,1,'删除数据源',NOW(),NOW()),
('数据源同步','ai:knowledge:datasource:sync',2,0,'ai',NULL,NULL,NULL,7,1,1,'执行同步/取消同步',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:knowledge:datasource','ai:knowledge:datasource:add','ai:knowledge:datasource:edit','ai:knowledge:datasource:delete','ai:knowledge:datasource:sync');

-- ========== 五、菜单（知识库 → 数据源管理） ==========
SET @ai_kb_id = (SELECT id FROM menus WHERE permission='ai:knowledge:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_kb_id, '数据源管理', '/ai/knowledge/datasource', 'el-icon-connection', 'ai:knowledge:datasource', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:knowledge:datasource' AND deleted_at IS NULL);
