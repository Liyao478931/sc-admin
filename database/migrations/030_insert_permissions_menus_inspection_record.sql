-- =====================================================
-- 030_insert_permissions_menus_inspection_record.sql
-- 检查记录功能：权限 + 菜单 + 角色授权
-- =====================================================

-- ---------- 1. 权限定义（已存在则更新） ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('检查记录查看',   'safety:inspection:record:list',   1, 0, '安全检查', '/safety/inspection/record', 'el-icon-s-data', NULL, 60, 1, 1, '查看检查记录列表', NOW(), NOW()),
('检查记录详情',   'safety:inspection:record:query',  2, 0, '安全检查', '/safety/inspection/record', NULL, NULL, 61, 1, 1, '查看检查记录详情', NOW(), NOW()),
('导出检查记录',   'safety:inspection:record:export', 2, 0, '安全检查', '/safety/inspection/record', NULL, NULL, 62, 1, 1, '导出检查记录', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 2. 角色授权（超级管理员） ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:inspection:record:list','safety:inspection:record:query','safety:inspection:record:export');

-- ---------- 3. 侧边栏菜单：安全检查下新增"检查记录" ----------
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '检查记录', '/safety/inspection/record', 'el-icon-s-data', 'safety:inspection:record:list', 3, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:inspection:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:inspection:record:list' AND x.`deleted_at` IS NULL);
