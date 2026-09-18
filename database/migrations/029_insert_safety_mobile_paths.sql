-- =====================================================
-- 029_insert_safety_mobile_paths.sql
-- 员工端安全检查执行：应用路径管理（app_paths）+ 功能菜单（app_functions）
-- =====================================================

-- ---------- 1. 应用路径管理 ----------
INSERT INTO `app_paths` (`name`, `path`, `page_key`, `platform`, `page_type`, `require_auth`, `status`, `created_at`, `updated_at`) VALUES
('安全检查任务', '/pages/sub/safety/task-list', 'safety-task-list', 0, 2, 1, 1, NOW(), NOW()),
('检查执行',     '/pages/sub/safety/execute',     'safety-execute',     0, 2, 1, 1, NOW(), NOW()),
('检查记录详情', '/pages/sub/safety/record-detail', 'safety-record-detail', 0, 2, 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

-- ---------- 2. 员工端功能菜单：安全检查执行 ----------
INSERT INTO `app_functions` (`name`, `code`, `icon`, `path_id`, `permission`, `sort`, `status`, `created_at`, `updated_at`)
SELECT '安全检查执行', 'safety_execute', 'el-icon-s-check',
       (SELECT id FROM `app_paths` WHERE `path` = '/pages/sub/safety/task-list' AND `deleted_at` IS NULL),
       '', 40, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `app_functions` WHERE `code` = 'safety_execute');
