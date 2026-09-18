-- =====================================================
-- 021_insert_permissions_menus_statistics.sql
-- 保养统计模块：权限 + 菜单 + 角色授权 + 系统参数
-- =====================================================

-- ---------- 1. 权限定义（挂载到保养模块根权限 device:maintenance:plan:view 之下） ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('保养统计查看', 'device:maintenance:statistics:view',   2, 565, '保养统计', '/device/maintenance/statistics', 'el-icon-s-marketing', NULL, 26, 1, 1, '查看保养统计看板', NOW(), NOW()),
('逾期设备导出', 'device:maintenance:statistics:export', 2, 565, '保养统计', '/device/maintenance/statistics', NULL, NULL, 27, 1, 1, '导出逾期未保养设备列表', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 2. 将统计权限分配给超级管理员角色 ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:maintenance:statistics:view','device:maintenance:statistics:export');

-- ---------- 3. 侧边栏菜单：设备管理目录下增加"保养统计"与"保养记录"子菜单 ----------
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '保养记录', '/device/maintenance/record', 'el-icon-s-data', 'device:maintenance:record:list', 60, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:manage:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:maintenance:record:list' AND x.`deleted_at` IS NULL);

INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '保养统计', '/device/maintenance/statistics', 'el-icon-s-marketing', 'device:maintenance:statistics:view', 70, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:manage:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:maintenance:statistics:view' AND x.`deleted_at` IS NULL);

-- ---------- 4. 系统参数（趋势月数 / 排行条数 / 成本单位 / 工时单价） ----------
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('maintenance_statistics_trend_months', '12', NOW(), NOW()),
('maintenance_statistics_top_limit', '10', NOW(), NOW()),
('maintenance_statistics_cost_unit', '元', NOW(), NOW()),
('maintenance_statistics_hourly_cost', '0', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();
