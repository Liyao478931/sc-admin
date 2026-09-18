-- 员工档案权限与菜单归属对齐（profile:manage 挂人事管理，按钮挂员工档案）

UPDATE `permissions` SET `type` = 1, `parent_id` = 2085, `updated_at` = '2026-08-31 19:56:20' WHERE `id` = 187 AND `code` = 'profile:manage';
UPDATE `permissions` SET `type` = 2, `parent_id` = 187, `updated_at` = '2026-08-31 19:56:20' WHERE `id` IN (188,189,190,191,192) AND `code` LIKE 'profile:%';
