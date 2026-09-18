-- 131_create_system_versions.sql
-- 系统维护 -> 版本管理：版本管理核心数据表（4张）
-- 1. system_versions        系统版本表
-- 2. system_update_logs     版本更新日志表
-- 3. system_version_config  版本管理配置表
-- 4. system_rollback_logs   版本回滚日志表
-- 幂等写法，可重复执行
-- 回滚 down：
--   DROP TABLE IF EXISTS system_rollback_logs;
--   DROP TABLE IF EXISTS system_version_config;
--   DROP TABLE IF EXISTS system_update_logs;
--   DROP TABLE IF EXISTS system_versions;

-- ========== 一、系统版本表 ==========
CREATE TABLE IF NOT EXISTS `system_versions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `version_no` varchar(20) NOT NULL DEFAULT '' COMMENT '版本号，语义化 vX.Y.Z',
  `version_name` varchar(100) NOT NULL DEFAULT '' COMMENT '版本名称',
  `version_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '版本类型：1正式版 2测试版 3热修复版',
  `env` tinyint(1) NOT NULL DEFAULT 3 COMMENT '环境标识：1开发 2测试 3生产',
  `release_time` datetime DEFAULT NULL COMMENT '发布时间',
  `release_note` text COMMENT '发布说明',
  `release_by` int(11) NOT NULL DEFAULT 0 COMMENT '发布人ID',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1已发布 2已归档',
  `approve_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审批状态：0无需审批 1待审批 2已审批 3已驳回',
  `approve_by` int(11) NOT NULL DEFAULT 0 COMMENT '审批人ID',
  `approve_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approve_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `prev_version_id` int(11) NOT NULL DEFAULT 0 COMMENT '前置版本ID（追溯版本链）',
  `is_current` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否当前版本：1是 0否',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_version_no` (`version_no`),
  KEY `idx_status` (`status`),
  KEY `idx_env` (`env`),
  KEY `idx_is_current` (`is_current`),
  KEY `idx_prev_version` (`prev_version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统版本表';

-- ========== 二、版本更新日志表 ==========
CREATE TABLE IF NOT EXISTS `system_update_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `version_id` int(11) NOT NULL DEFAULT 0 COMMENT '版本ID',
  `change_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '变更类型：1新增功能 2功能优化 3Bug修复 4性能优化 5安全更新 6数据库变更',
  `change_content` text COMMENT '变更内容',
  `impact_scope` varchar(500) DEFAULT NULL COMMENT '影响范围',
  `file_list` text COMMENT '变更文件列表（JSON数组）',
  `db_migrations` text COMMENT '数据库迁移文件（JSON数组）',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_version_id` (`version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='版本更新日志表';

-- ========== 三、版本管理配置表 ==========
CREATE TABLE IF NOT EXISTS `system_version_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `config_key` varchar(100) NOT NULL DEFAULT '' COMMENT '配置键（唯一）',
  `config_value` text COMMENT '配置值',
  `group_name` varchar(50) NOT NULL DEFAULT '' COMMENT '配置分组',
  `description` varchar(255) DEFAULT NULL COMMENT '配置描述',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='版本管理配置表';

-- ========== 四、版本回滚日志表 ==========
CREATE TABLE IF NOT EXISTS `system_rollback_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `from_version` varchar(20) NOT NULL DEFAULT '' COMMENT '原版本号（回滚前）',
  `to_version` varchar(20) NOT NULL DEFAULT '' COMMENT '目标版本号（回滚后）',
  `rollback_reason` varchar(500) DEFAULT NULL COMMENT '回滚原因',
  `rollback_scope` text COMMENT '回滚范围（JSON数组：code/database/frontend）',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `result` tinyint(1) NOT NULL DEFAULT 1 COMMENT '回滚结果：1成功 0失败',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='版本回滚日志表';
