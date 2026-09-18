-- =====================================================
-- 077_create_ai_api_keys.sql
-- AI 智能平台：API 密钥管理
--   1. 密钥表 ai_api_keys
--   2. 权限（ai:app:apikey 系列）
--   3. 菜单（AI智能平台 → 应用中心 → API密钥管理）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、密钥表 ==========
CREATE TABLE IF NOT EXISTS `ai_api_keys` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `key_id` varchar(32) NOT NULL DEFAULT '' COMMENT '密钥唯一标识(UUID)',
  `app_id` varchar(32) NOT NULL DEFAULT '' COMMENT '所属应用ID',
  `key_name` varchar(100) NOT NULL DEFAULT '' COMMENT '密钥名称',
  `key_prefix` varchar(50) NOT NULL DEFAULT '' COMMENT '密钥展示前缀（前8+后4，含掩码）',
  `key_hash` varchar(255) NOT NULL DEFAULT '' COMMENT '密钥加密值（CryptHelper 可逆加密，不存明文）',
  `key_expire` datetime DEFAULT NULL COMMENT '过期时间（空=永不过期）',
  `ip_whitelist` json DEFAULT NULL COMMENT 'IP白名单',
  `call_count` int(11) NOT NULL DEFAULT 0 COMMENT '调用次数',
  `last_call_time` datetime DEFAULT NULL COMMENT '最后调用时间',
  `last_call_ip` varchar(50) NOT NULL DEFAULT '' COMMENT '最后调用IP',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_key_id` (`key_id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_creator_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI应用API密钥表';

-- ========== 二、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('API密钥管理', 'ai:app:apikey', 1, 0, 'ai', '/ai/app/apikey', 'el-icon-key', NULL, 0, 1, 1, 'AI应用API密钥管理菜单/查看'),
  ('API密钥生成', 'ai:app:apikey:add', 2, 0, 'ai', '/ai/app/apikey', NULL, NULL, 1, 1, 1, '生成/刷新API密钥'),
  ('API密钥编辑', 'ai:app:apikey:edit', 2, 0, 'ai', '/ai/app/apikey', NULL, NULL, 2, 1, 1, '启停/刷新API密钥'),
  ('API密钥删除', 'ai:app:apikey:delete', 2, 0, 'ai', '/ai/app/apikey', NULL, NULL, 3, 1, 1, '删除API密钥'),
  ('API密钥查看明文', 'ai:app:apikey:view', 2, 0, 'ai', '/ai/app/apikey', NULL, NULL, 4, 1, 1, '查看完整密钥明文')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:app:apikey','ai:app:apikey:add','ai:app:apikey:edit','ai:app:apikey:delete','ai:app:apikey:view');

-- ========== 三、菜单 ==========
-- 应用中心（目录，已存在则跳过）
SET @ai_app_id = (SELECT id FROM menus WHERE permission='ai:app:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, '应用中心', '', 'el-icon-apps', 'ai:app:view', 25, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:app:view' AND deleted_at IS NULL);

-- API密钥管理（子菜单）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_app_id, 'API密钥管理', '/ai/app/apikey', 'el-icon-key', 'ai:app:apikey', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:app:apikey' AND deleted_at IS NULL);
