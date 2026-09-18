-- =====================================================
-- 008_insert_permissions_menus_device_category.sql
-- 设备分类模块：权限 + 菜单 + 角色授权
-- =====================================================

-- ---------- 1. 权限定义（已存在则更新） ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('设备分类',     'device:category:list',   1, 0, '设备分类', '/device/category', 'el-icon-s-tree', NULL, 10, 1, 1, '设备分类菜单权限', NOW(), NOW()),
('设备分类查询', 'device:category:query',  2, 0, '设备分类', '/device/category', NULL, NULL, 20, 1, 1, '查看分类详情', NOW(), NOW()),
('设备分类新增', 'device:category:add',    2, 0, '设备分类', '/device/category', NULL, NULL, 30, 1, 1, '新增分类', NOW(), NOW()),
('设备分类编辑', 'device:category:edit',   2, 0, '设备分类', '/device/category', NULL, NULL, 40, 1, 1, '编辑/切换状态', NOW(), NOW()),
('设备分类删除', 'device:category:delete', 2, 0, '设备分类', '/device/category', NULL, NULL, 50, 1, 1, '删除分类', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 2. 将上述权限分配给超级管理员角色（role code = super_admin） ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:category:list','device:category:query','device:category:add','device:category:edit','device:category:delete');

-- ---------- 3. 侧边栏菜单（设备管理目录 + 设备分类子菜单） ----------
-- 3.1 设备管理目录（已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT 0, '设备管理', '', 'el-icon-s-management', 'device:manage:view', 40, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission` = 'device:manage:view' AND `deleted_at` IS NULL);

SET @dev_menu_id = (SELECT `id` FROM `menus` WHERE `permission` = 'device:manage:view' AND `deleted_at` IS NULL LIMIT 1);

-- 3.2 设备分类子菜单（已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT @dev_menu_id, '设备分类', '/device/category', 'el-icon-s-tree', 'device:category:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission` = 'device:category:list' AND `deleted_at` IS NULL);
