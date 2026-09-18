-- =====================================================
-- 061_create_ai_chat_history.sql
-- AI 智能平台：对话历史功能
--   1. 新增权限（ai:chat:history 系列）
--   2. 对话历史菜单权限更新为 ai:chat:history
-- 幂等写法，可重复执行
-- =====================================================

-- 一、权限
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('对话历史', 'ai:chat:history', 1, 0, 'ai', '/ai/chat/history', 'el-icon-document-copy', NULL, 1, 1, 1, 'AI对话历史菜单'),
  ('对话历史-编辑', 'ai:chat:history:edit', 2, 0, 'ai', '/ai/chat/history', NULL, NULL, 2, 1, 1, '重命名/归档/恢复'),
  ('对话历史-删除', 'ai:chat:history:delete', 2, 0, 'ai', '/ai/chat/history', NULL, NULL, 3, 1, 1, '删除/批量删除'),
  ('对话历史-导出', 'ai:chat:history:export', 2, 0, 'ai', '/ai/chat/history', NULL, NULL, 4, 1, 1, '导出对话记录')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- 二、super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:chat:history','ai:chat:history:edit','ai:chat:history:delete','ai:chat:history:export');

-- 三、对话历史菜单权限更新为 ai:chat:history
UPDATE `menus` SET `permission`='ai:chat:history', `icon`='el-icon-document-copy'
WHERE `permission`='ai:chat:list' AND `path`='/ai/chat/history' AND `deleted_at` IS NULL;
