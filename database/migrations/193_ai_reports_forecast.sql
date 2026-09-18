-- 193_ai_reports_forecast.sql
-- v1.65.0 智能报告 + 销售预测：4 张新表 + 3 预置模板 + 3 权限 + 2 菜单

CREATE TABLE IF NOT EXISTS `ai_reports` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `report_name` varchar(100) NOT NULL DEFAULT '' COMMENT '报告名称',
  `template_id` int(11) NOT NULL DEFAULT 0 COMMENT '模板ID',
  `template_name` varchar(50) NOT NULL DEFAULT '' COMMENT '模板名称（冗余展示）',
  `time_range` varchar(50) DEFAULT NULL COMMENT '时间范围（如 2026-08）',
  `config` json DEFAULT NULL COMMENT '生成配置（格式/包含内容）',
  `content` longtext COMMENT '报告内容（HTML）',
  `file_url` varchar(255) DEFAULT NULL COMMENT '导出文件URL',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=生成中 1=已完成 2=失败',
  `error_msg` varchar(500) DEFAULT NULL COMMENT '失败原因',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI报告记录表';

CREATE TABLE IF NOT EXISTS `ai_report_templates` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_name` varchar(50) NOT NULL DEFAULT '' COMMENT '模板名称',
  `template_code` varchar(30) NOT NULL DEFAULT '' COMMENT '模板编码',
  `description` text COMMENT '模板描述',
  `structure` json DEFAULT NULL COMMENT '模板结构（章节）',
  `data_sources` json DEFAULT NULL COMMENT '数据源配置',
  `prompt_template` text COMMENT 'AI分析提示词模板',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=禁用 1=启用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI报告模板表';

CREATE TABLE IF NOT EXISTS `ai_forecast_cache` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `dimension` varchar(20) NOT NULL DEFAULT '' COMMENT '预测维度：overall/category/customer_level/sales_person',
  `dimension_value` varchar(50) DEFAULT NULL COMMENT '维度值',
  `forecast_data` json DEFAULT NULL COMMENT '预测数据（日期/预测值/下限/上限）',
  `factors` json DEFAULT NULL COMMENT '因子贡献度',
  `accuracy` decimal(5,2) DEFAULT NULL COMMENT '模型准确率（%）',
  `generated_at` datetime NOT NULL COMMENT '生成时间',
  `expires_at` datetime NOT NULL COMMENT '过期时间（缓存24h）',
  PRIMARY KEY (`id`),
  KEY `idx_dimension` (`dimension`, `dimension_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI预测缓存表';

CREATE TABLE IF NOT EXISTS `ai_report_schedules` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `schedule_name` varchar(100) NOT NULL DEFAULT '' COMMENT '任务名称',
  `template_id` int(11) NOT NULL DEFAULT 0 COMMENT '模板ID',
  `template_name` varchar(50) NOT NULL DEFAULT '' COMMENT '模板名称',
  `time_range` varchar(50) DEFAULT NULL COMMENT '时间范围（如 last_month/current_month）',
  `config` json DEFAULT NULL COMMENT '生成配置',
  `frequency` varchar(10) NOT NULL DEFAULT 'daily' COMMENT '频率：daily/weekly/monthly',
  `run_time` varchar(20) NOT NULL DEFAULT '09:00' COMMENT '执行时间（daily/weekly: HH:MM；monthly: D HH:MM）',
  `recipients` json DEFAULT NULL COMMENT '接收人 [{type:user,id,name}]',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `last_run_at` datetime DEFAULT NULL COMMENT '上次执行时间',
  `next_run_at` datetime DEFAULT NULL COMMENT '下次执行时间',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status_next` (`status`, `next_run_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI定时报告任务表';

-- 预置报告模板
INSERT INTO `ai_report_templates` (`template_name`, `template_code`, `description`, `structure`, `data_sources`, `prompt_template`, `is_default`, `status`) VALUES
('经营简报', 'business_brief', '月度/季度经营总览，包含关键指标、趋势分析、重点关注、下月预测', '{"sections": ["key_metrics", "trend_analysis", "highlights", "forecast"]}', '{"metrics": "revenue_overview", "trend": "revenue_trend", "ranking": "customer_ranking"}', '你是 SC Admin 的经营分析师。请基于以下经营数据生成月度经营简报，包含：关键指标解读、趋势分析、重点关注（增长亮点/风险预警）、下月预测建议。数据：', 1, 1),
('销售分析报告', 'sales_analysis', '销售趋势深度分析，包含销售总览、品类分析、区域分析、业务员排行', '{"sections": ["overview", "category", "region", "salesperson_ranking"]}', '{"metrics": "revenue_overview", "trend": "revenue_trend", "category": "revenue_category", "ranking": "salesperson_ranking"}', '你是 SC Admin 的销售分析师。请基于以下销售数据生成销售分析报告，包含：销售总览、品类分析、业务员排行、趋势洞察。数据：', 0, 1),
('客户洞察报告', 'customer_insight', '客户价值与风险分析，包含客户总览、客户排行、流失预警、价值分层', '{"sections": ["overview", "ranking", "churn_warning", "value_tier"]}', '{"metrics": "revenue_overview", "ranking": "customer_ranking"}', '你是 SC Admin 的客户分析师。请基于以下客户数据生成客户洞察报告，包含：客户总览、客户排行、流失预警、价值分层建议。数据：', 0, 1);

-- 权限（ai:reports:generate 已存在，v1.63.0）
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('查看智能报告', 'ai:reports:view', 2, 0, 'ai', '', '', '', 0, 1, 1, '查看报告列表与报告详情', NOW(), NOW()),
('配置定时报告', 'ai:reports:schedule', 2, 0, 'ai', '', '', '', 0, 1, 1, '配置定时报告任务与推送', NOW(), NOW()),
('查看销售预测', 'ai:forecast:view', 2, 0, 'ai', '', '', '', 0, 1, 1, '查看销售预测看板', NOW(), NOW());

-- 菜单：AI智能平台下新增「智能报告」「销售预测」
SET @ai_top := (SELECT id FROM `menus` WHERE `permission` = 'ai:platform:view' LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@ai_top, '智能报告', '', 'el-icon-document', 'ai:reports:view', 12, 1, 1, 0),
(@ai_top, '销售预测', '', 'el-icon-data-line', 'ai:forecast:view', 13, 1, 1, 0);
SET @report_dir := LAST_INSERT_ID();
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@report_dir, '报告生成', '/ai/reports/generate', '', 'ai:reports:generate', 1, 1, 2, 0),
(@report_dir, '报告列表', '/ai/reports/list', '', 'ai:reports:view', 2, 1, 2, 0);
SET @forecast_dir := (SELECT id FROM `menus` WHERE `permission` = 'ai:forecast:view' AND `parent_id` = @ai_top LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@forecast_dir, '预测看板', '/ai/forecast/sales', '', 'ai:forecast:view', 1, 1, 2, 0);

-- 角色绑定（super_admin/admin）
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code IN ('super_admin', 'admin') AND p.code IN ('ai:reports:view', 'ai:reports:schedule', 'ai:forecast:view');
