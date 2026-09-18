-- 员工档案权限体系统一（菜单与页面按钮一致：employeeprofile:*）

UPDATE `menus` SET `permission` = 'employeeprofile:view', `updated_at` = '2026-08-31 20:00:01' WHERE `id` = 22;
UPDATE `permissions` SET `status` = 1, `updated_at` = '2026-08-31 20:00:01' WHERE `id` IN (5,6,7,219,220,221);
UPDATE `permissions` SET `status` = 0, `updated_at` = '2026-08-31 20:00:01' WHERE `id` IN (187,188,189,190,191,192);
