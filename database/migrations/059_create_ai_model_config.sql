-- =====================================================
-- 059_create_ai_model_config.sql
-- AI 智能平台：模型配置模块
--   1. 服务商表 ai_model_providers
--   2. 模型表 ai_models
--   3. 数据字典（认证方式/模型状态）
--   4. 系统参数（默认温度/TopP/MaxTokens/流式）
--   5. 预置服务商与模型
--   6. 权限 + 菜单（AI智能平台 → 系统设置 → 模型配置）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、服务商表 ==========
CREATE TABLE IF NOT EXISTS `ai_model_providers` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `provider_code` varchar(50) NOT NULL DEFAULT '' COMMENT '服务商标识：deepseek/qwen/zhipu/baichuan/custom',
  `provider_name` varchar(100) NOT NULL DEFAULT '' COMMENT '服务商名称',
  `api_base_url` varchar(255) NOT NULL DEFAULT '' COMMENT 'API基础地址',
  `auth_type` varchar(20) NOT NULL DEFAULT 'api_key' COMMENT '认证方式：api_key/jwt_token',
  `api_key` text COMMENT 'API密钥（加密存储）',
  `api_secret` text COMMENT 'API密钥备用字段（加密存储）',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述说明',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider_code` (`provider_code`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI服务商表';

-- ========== 二、模型表 ==========
CREATE TABLE IF NOT EXISTS `ai_models` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `model_code` varchar(50) NOT NULL DEFAULT '' COMMENT '模型标识：deepseek-v4-pro/qwen-plus/glm-5.2',
  `model_name` varchar(100) NOT NULL DEFAULT '' COMMENT '模型名称',
  `provider_id` int(11) NOT NULL DEFAULT 0 COMMENT '所属服务商ID',
  `context_length` int(11) NOT NULL DEFAULT 128000 COMMENT '上下文长度',
  `input_price` decimal(10,4) NOT NULL DEFAULT 0 COMMENT '输入价格（元/百万tokens）',
  `output_price` decimal(10,4) NOT NULL DEFAULT 0 COMMENT '输出价格（元/百万tokens）',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认模型：1是 0否',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述说明',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_model_code` (`model_code`),
  KEY `idx_provider_id` (`provider_id`),
  KEY `idx_status` (`status`),
  KEY `idx_is_default` (`is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI模型表';

-- ========== 三、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`)
VALUES ('认证方式', 'ai_auth_type', 'AI服务商API认证方式', 1, 1);

INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`)
VALUES ('模型状态', 'ai_model_status', 'AI模型启用状态', 2, 1);

SET @dty_auth = (SELECT id FROM dictionary_types WHERE code='ai_auth_type' AND deleted_at IS NULL);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`)
VALUES
  (@dty_auth, 'API Key', 'api_key', 1, 'primary', 1),
  (@dty_auth, 'JWT Token', 'jwt_token', 2, 'warning', 1)
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`), `sort`=VALUES(`sort`), `style`=VALUES(`style`), `status`=VALUES(`status`), `deleted_at`=NULL, `updated_at`=NOW();

SET @dty_status = (SELECT id FROM dictionary_types WHERE code='ai_model_status' AND deleted_at IS NULL);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`)
VALUES
  (@dty_status, '启用', 'active', 1, 'success', 1),
  (@dty_status, '停用', 'inactive', 2, 'info', 1)
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`), `sort`=VALUES(`sort`), `style`=VALUES(`style`), `status`=VALUES(`status`), `deleted_at`=NULL, `updated_at`=NOW();

-- ========== 四、系统参数 ==========
INSERT INTO `system_params`
  (`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`)
VALUES
  ('ai_default_temperature', '0.7',   '默认温度参数',       'ai', 'number', '模型随机性，0-2，越高越随机', 1, 0, 1),
  ('ai_default_top_p',       '0.95',  '默认TopP参数',       'ai', 'number', '核采样，0-1，与temperature二选一调节', 2, 0, 1),
  ('ai_default_max_tokens',  '4096',  '默认最大输出Token',  'ai', 'number', '单次生成最大token数', 3, 0, 1),
  ('ai_default_stream',      'true',  '默认启用流式输出',   'ai', 'switch', '是否默认启用流式输出', 4, 0, 1)
ON DUPLICATE KEY UPDATE
  `param_value`=VALUES(`param_value`), `name`=VALUES(`name`), `param_group`=VALUES(`param_group`),
  `param_type`=VALUES(`param_type`), `description`=VALUES(`description`), `sort`=VALUES(`sort`),
  `status`=VALUES(`status`), `updated_at`=NOW();

-- ========== 五、预置服务商与模型 ==========
INSERT INTO `ai_model_providers` (`provider_code`, `provider_name`, `api_base_url`, `auth_type`, `api_key`, `sort`, `status`, `description`)
VALUES
  ('deepseek', '深度求索', 'https://api.deepseek.com', 'api_key', '', 1, 1, 'DeepSeek 官方 API'),
  ('qwen',     '通义千问', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'api_key', '', 2, 1, '阿里云通义千问（OpenAI兼容）'),
  ('zhipu',    '智谱AI',   'https://open.bigmodel.cn/api/paas/v4', 'api_key', '', 3, 1, '智谱 GLM 系列'),
  ('baichuan', '百川智能', 'https://api.baichuan-ai.com/v1', 'api_key', '', 4, 1, '百川大模型')
ON DUPLICATE KEY UPDATE `provider_name`=VALUES(`provider_name`), `api_base_url`=VALUES(`api_base_url`),
  `auth_type`=VALUES(`auth_type`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `description`=VALUES(`description`), `update_time`=NOW();

-- 预置模型（内联子查询关联服务商，避免依赖 @变量）
INSERT INTO `ai_models` (`model_code`, `model_name`, `provider_id`, `context_length`, `input_price`, `output_price`, `is_default`, `sort`, `status`, `description`)
SELECT v.model_code, v.model_name, p.id, v.context_length, 0, 0, v.is_default, v.sort, 1, ''
FROM (
  SELECT 'deepseek-v4-pro' model_code, 'DeepSeek V4 Pro' model_name, 'deepseek' pc, 128000 context_length, 0 is_default, 1 sort
  UNION ALL SELECT 'deepseek-v4-flash', 'DeepSeek V4 Flash', 'deepseek', 128000, 0, 2
  UNION ALL SELECT 'qwen-max', '通义千问 Max', 'qwen', 128000, 0, 1
  UNION ALL SELECT 'qwen-plus', '通义千问 Plus', 'qwen', 128000, 0, 2
  UNION ALL SELECT 'qwen-turbo', '通义千问 Turbo', 'qwen', 128000, 0, 3
  UNION ALL SELECT 'glm-5.2', 'GLM-5.2', 'zhipu', 128000, 0, 1
  UNION ALL SELECT 'glm-5.1', 'GLM-5.1', 'zhipu', 128000, 0, 2
  UNION ALL SELECT 'baichuan-4', '百川4', 'baichuan', 128000, 0, 1
) v JOIN `ai_model_providers` p ON p.provider_code = v.pc
ON DUPLICATE KEY UPDATE `model_name`=VALUES(`model_name`), `provider_id`=VALUES(`provider_id`),
  `context_length`=VALUES(`context_length`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `update_time`=NOW();

-- 预置第一个可用模型为默认（deepseek-v4-pro）
UPDATE `ai_models` SET `is_default`=0 WHERE `is_default`=1;
UPDATE `ai_models` SET `is_default`=1 WHERE `model_code`='deepseek-v4-pro';

-- ========== 六、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('模型配置', 'ai:settings:model', 1, 0, 'ai', '/ai/settings/model', 'el-icon-s-data', NULL, 1, 1, 1, 'AI模型配置菜单'),
  ('模型配置-新增', 'ai:settings:model:add', 2, 0, 'ai', '/ai/settings/model', NULL, NULL, 2, 1, 1, '新增服务商/模型'),
  ('模型配置-编辑', 'ai:settings:model:edit', 2, 0, 'ai', '/ai/settings/model', NULL, NULL, 3, 1, 1, '编辑服务商/模型/状态'),
  ('模型配置-删除', 'ai:settings:model:delete', 2, 0, 'ai', '/ai/settings/model', NULL, NULL, 4, 1, 1, '删除服务商/模型'),
  ('模型配置-测试', 'ai:settings:model:test', 2, 0, 'ai', '/ai/settings/model', NULL, NULL, 5, 1, 1, '测试模型连接')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:settings:model','ai:settings:model:add','ai:settings:model:edit','ai:settings:model:delete','ai:settings:model:test');

-- ========== 七、菜单 ==========
-- AI智能平台（顶级目录）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- AI 系统设置（目录）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '系统设置', '', 'el-icon-setting', 'ai:settings:view', 10, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:settings:view' AND deleted_at IS NULL);

-- 模型配置（子菜单）
SET @ai_settings_id = (SELECT id FROM menus WHERE permission='ai:settings:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_settings_id, '模型配置', '/ai/settings/model', 'el-icon-s-data', 'ai:settings:model', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:settings:model' AND deleted_at IS NULL);
