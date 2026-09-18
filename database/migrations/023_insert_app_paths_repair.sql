-- =====================================================
-- 023_insert_app_paths_repair.sql
-- 维修执行功能：应用路径管理配置（DIY 页面引用）
-- =====================================================

INSERT INTO `app_paths` (`name`, `path`, `page_key`, `platform`, `page_type`, `require_auth`, `status`, `created_at`, `updated_at`) VALUES
('维修任务列表', '/pages/sub/repair/task-list', 'repair-task-list', 0, 2, 1, 1, NOW(), NOW()),
('维修执行',     '/pages/sub/repair/execute',     'repair-execute',     0, 2, 1, 1, NOW(), NOW()),
('维修记录详情', '/pages/sub/repair/record-detail', 'repair-record-detail', 0, 2, 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();
