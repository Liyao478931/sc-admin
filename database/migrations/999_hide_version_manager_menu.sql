-- ============================================================
-- 隐藏"版本管理"菜单组（版本管理/版本回滚/版本统计/更新策略）
-- 客户环境不应展示该菜单；同时移除角色对版本权限的关联。
-- 幂等说明：UPDATE 设 status=0 可重复执行；DELETE 可重复执行。
-- ============================================================

UPDATE `menus` SET `status` = 0
WHERE `permission` IN (
  'settings:version',
  'settings:version:view',
  'settings:version:rollback',
  'settings:version:statistics:view',
  'settings:version:policy:view'
);

DELETE FROM `role_permissions`
WHERE `permission_id` IN (
  SELECT `id` FROM `permissions` WHERE `code` LIKE 'settings:version%'
);