-- =====================================================
-- 080_create_system_permission.sql
-- 系统设置：权限管理（基于现有 permissions/roles 表完善，不新建表）
--   1. 预置 system 模块权限
--   2. 权限管理菜单（系统设置 → 权限管理）
--   3. 权限管理相关权限授权 super_admin
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、预置 system 模块权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('系统管理', 'system:manage', 1, 0, 'system', '/system', 'el-icon-setting', NULL, 0, 1, 1, '系统管理目录'),
  ('权限管理', 'system:permission:list', 1, 0, 'system', '/settings/permissions', 'el-icon-lock', NULL, 0, 1, 1, '权限管理菜单/查看'),
  ('权限新增', 'system:permission:add', 2, 0, 'system', NULL, NULL, NULL, 1, 1, 1, '新增权限'),
  ('权限编辑', 'system:permission:edit', 2, 0, 'system', NULL, NULL, NULL, 2, 1, 1, '编辑/启停权限'),
  ('权限删除', 'system:permission:delete', 2, 0, 'system', NULL, NULL, NULL, 3, 1, 1, '删除权限'),
  ('权限同步', 'system:permission:sync', 2, 0, 'system', NULL, NULL, NULL, 4, 1, 1, '扫描控制器同步权限')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- ========== 二、权限管理相关权限授权 super_admin ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('system:manage','system:permission:list','system:permission:add','system:permission:edit','system:permission:delete','system:permission:sync');

-- ========== 三、菜单（系统设置 → 权限管理） ==========
SET @system_id = (SELECT id FROM menus WHERE permission='system:view' AND deleted_at IS NULL LIMIT 1);
-- 兼容全新安装：system:view 菜单可能尚未插入（098 才插入），父级兜底为 0（顶级菜单）
SET @system_id = IFNULL(@system_id, 0);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @system_id, '权限管理', '/settings/permissions', 'el-icon-lock', 'system:permission:list', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='system:permission:list' AND deleted_at IS NULL);
