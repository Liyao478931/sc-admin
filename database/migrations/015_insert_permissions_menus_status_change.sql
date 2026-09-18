-- =====================================================
-- 015_insert_permissions_menus_status_change.sql
-- 设备状态变更模块：权限 + 菜单 + 角色授权
-- =====================================================

-- ---------- 1. 权限定义（已存在则更新） ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('状态变更',       'device:status:list',        1, 0, '状态变更', '/device/status-change', 'el-icon-s-flag', NULL, 30, 1, 1, '状态变更菜单/列表权限', NOW(), NOW()),
('状态变更详情',   'device:status:query',       2, 0, '状态变更', '/device/status-change', NULL, NULL, 40, 1, 1, '查看变更详情/设备历史', NOW(), NOW()),
('发起状态变更',   'device:status:add',         2, 0, '状态变更', '/device/status-change', NULL, NULL, 50, 1, 1, '发起/批量状态变更', NOW(), NOW()),
('批量状态变更',   'device:status:batch',       2, 0, '状态变更', '/device/status-change', NULL, NULL, 60, 1, 1, '批量状态变更', NOW(), NOW()),
('撤销本人变更',   'device:status:rollback',    2, 0, '状态变更', '/device/status-change', NULL, NULL, 70, 1, 1, '撤销本人变更', NOW(), NOW()),
('撤销所有人变更', 'device:status:rollback_all', 2, 0, '状态变更', '/device/status-change', NULL, NULL, 80, 1, 1, '撤销所有人变更', NOW(), NOW()),
('导出变更记录',   'device:status:export',      2, 0, '状态变更', '/device/status-change', NULL, NULL, 90, 1, 1, '导出变更记录', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 2. 将权限分配给超级管理员角色 ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:status:list','device:status:query','device:status:add','device:status:batch',
                   'device:status:rollback','device:status:rollback_all','device:status:export');

-- ---------- 3. 侧边栏菜单：设备管理目录下增加"状态变更"子菜单 ----------
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '状态变更', '/device/status-change', 'el-icon-s-flag', 'device:status:list', 30, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:manage:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:status:list' AND x.`deleted_at` IS NULL);
