-- =====================================================
-- 012_insert_permissions_menus_device_asset.sql
-- 设备台账模块：权限 + 菜单 + 角色授权
-- =====================================================

-- ---------- 1. 权限定义（已存在则更新） ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('设备台账',     'device:asset:list',   1, 0, '设备台账', '/device/asset', 'el-icon-s-goods', NULL, 20, 1, 1, '设备台账菜单/列表权限', NOW(), NOW()),
('设备台账查询', 'device:asset:query',  2, 0, '设备台账', '/device/asset', NULL, NULL, 30, 1, 1, '查看设备详情', NOW(), NOW()),
('设备台账新增', 'device:asset:add',    2, 0, '设备台账', '/device/asset', NULL, NULL, 40, 1, 1, '新增设备', NOW(), NOW()),
('设备台账编辑', 'device:asset:edit',   2, 0, '设备台账', '/device/asset', NULL, NULL, 50, 1, 1, '编辑设备', NOW(), NOW()),
('设备台账删除', 'device:asset:delete', 2, 0, '设备台账', '/device/asset', NULL, NULL, 60, 1, 1, '删除/批量删除', NOW(), NOW()),
('设备台账状态变更', 'device:asset:status', 2, 0, '设备台账', '/device/asset', NULL, NULL, 70, 1, 1, '变更设备状态', NOW(), NOW()),
('设备台账导入', 'device:asset:import', 2, 0, '设备台账', '/device/asset', NULL, NULL, 80, 1, 1, '导入设备', NOW(), NOW()),
('设备台账导出', 'device:asset:export', 2, 0, '设备台账', '/device/asset', NULL, NULL, 90, 1, 1, '导出设备', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 2. 将权限分配给超级管理员角色 ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:asset:list','device:asset:query','device:asset:add','device:asset:edit',
                   'device:asset:delete','device:asset:status','device:asset:import','device:asset:export');

-- ---------- 3. 侧边栏菜单：设备管理目录下增加"设备台账"子菜单 ----------
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '设备台账', '/device/asset', 'el-icon-s-goods', 'device:asset:list', 20, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:manage:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:asset:list' AND x.`deleted_at` IS NULL);
