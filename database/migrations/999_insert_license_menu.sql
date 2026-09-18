-- =====================================================
-- 999_insert_license_menu.sql
-- 授权管理菜单（挂「系统维护」parent_id=3 下，id=332 防重）
-- 安装向导/迁移执行：菜单数据与 database.sql 保持一致
-- =====================================================
INSERT INTO `menus` (`id`,`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`) VALUES
(332,3,'授权管理','/license','el-icon-key','license:view',10,1,2,0,'2026-08-26 16:32:23','2026-08-26 16:32:23')
ON DUPLICATE KEY UPDATE `parent_id`=3, `name`='授权管理', `path`='/license', `permission`='license:view', `status`=1;
