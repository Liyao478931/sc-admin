-- =====================================================
-- 038_insert_safety_certificate_mobile_paths.sql
-- 员工端我的证书：应用路径管理（app_paths）+ 功能菜单（app_functions）
-- =====================================================

-- ---------- 1. 应用路径管理 ----------
INSERT INTO `app_paths` (`name`, `path`, `page_key`, `platform`, `page_type`, `require_auth`, `status`, `created_at`, `updated_at`) VALUES
('我的证书', '/pages/sub/safety/my-certificates', 'safety-my-certificates', 0, 2, 1, 1, NOW(), NOW()),
('证书详情', '/pages/sub/safety/certificate-detail', 'safety-certificate-detail', 0, 2, 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

-- ---------- 2. 员工端功能菜单：我的证书 ----------
INSERT INTO `app_functions` (`name`, `code`, `icon`, `path_id`, `permission`, `sort`, `status`, `created_at`, `updated_at`)
SELECT '我的证书', 'my_certificates', 'el-icon-medal',
       (SELECT id FROM `app_paths` WHERE `path` = '/pages/sub/safety/my-certificates' AND `deleted_at` IS NULL),
       '', 60, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `app_functions` WHERE `code` = 'my_certificates');
