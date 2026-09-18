-- =====================================================
-- 036_insert_safety_training_mobile_paths.sql
-- 员工端我的培训：应用路径管理（app_paths）+ 功能菜单（app_functions）
-- =====================================================

-- ---------- 1. 应用路径管理 ----------
INSERT INTO `app_paths` (`name`, `path`, `page_key`, `platform`, `page_type`, `require_auth`, `status`, `created_at`, `updated_at`) VALUES
('我的培训', '/pages/sub/safety/my-training', 'safety-my-training', 0, 2, 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

-- ---------- 2. 员工端功能菜单：安全培训 ----------
INSERT INTO `app_functions` (`name`, `code`, `icon`, `path_id`, `permission`, `sort`, `status`, `created_at`, `updated_at`)
SELECT '安全培训', 'training_learn', 'el-icon-reading',
       (SELECT id FROM `app_paths` WHERE `path` = '/pages/sub/safety/my-training' AND `deleted_at` IS NULL),
       '', 50, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `app_functions` WHERE `code` = 'training_learn');
