-- ============================================================
-- menu_roles 增加 excluded 字段：0=分配(可见) 1=排除(子菜单单独取消)
-- 菜单-角色继承：主菜单分配角色→子菜单继承可见；子菜单 excluded=1 可单独取消
-- ============================================================
ALTER TABLE `menu_roles` ADD COLUMN `excluded` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0分配1排除' AFTER `role_id`;
