-- 20260920_menu_survey_fix.sql 修正：问卷统计不再单独占菜单位（软删），统计入口在问卷管理列表页"统计"按钮
UPDATE `menus` m
JOIN `menus` s ON s.`name` = '系统设置' AND s.`parent_id` = 0 AND s.`type` = 1 AND s.`permission` = 'system:view'
SET m.`parent_id` = s.`id`
WHERE m.`permission` = 'survey:view' AND m.`parent_id` <> s.`id`;
UPDATE `menus` SET `deleted_at` = NOW() WHERE `permission` = 'survey:stats' AND `deleted_at` IS NULL;
