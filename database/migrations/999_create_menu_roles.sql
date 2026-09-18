-- ============================================================
-- 菜单可见角色表（菜单管理直接给菜单分配角色，分配角色即可见该菜单）
-- 菜单显示逻辑：权限匹配 OR 菜单-角色匹配（用户任一角色被分配该菜单）OR 超管
-- ============================================================
CREATE TABLE IF NOT EXISTS `menu_roles` (
  `menu_id` int(11) unsigned NOT NULL,
  `role_id` int(11) unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`menu_id`,`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='菜单可见角色（菜单管理直接分配角色）';
