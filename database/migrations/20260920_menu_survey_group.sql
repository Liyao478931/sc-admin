-- =====================================================
-- 20260920_menu_survey_group.sql
-- 问卷菜单调整：问卷管理 → 系统设置 分组下；问卷统计 → 问卷管理 子菜单
-- 幂等：重复执行无副作用
-- =====================================================

-- 1) 问卷管理挂到"系统设置"顶级分组下
UPDATE `menus` m
JOIN `menus` s ON s.`name` = '系统设置' AND s.`parent_id` = 0 AND s.`type` = 1 AND s.`permission` = 'system:view'
SET m.`parent_id` = s.`id`
WHERE m.`permission` = 'survey:view' AND m.`parent_id` <> s.`id`;

-- 2) 问卷统计挂到"问卷管理"下（作为其子菜单）
UPDATE `menus` m
JOIN `menus` q ON q.`permission` = 'survey:view' AND q.`deleted_at` IS NULL
SET m.`parent_id` = q.`id`
WHERE m.`permission` = 'survey:stats' AND m.`parent_id` <> q.`id`;
