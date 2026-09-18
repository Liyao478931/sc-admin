-- ============================================================
-- 设备保养执行 · 路径管理数据
-- 表：app_paths
-- ============================================================

INSERT INTO `app_paths` (`name`,`path`,`page_key`,`platform`,`page_type`,`require_auth`,`status`,`created_at`,`updated_at`) VALUES
('保养任务列表','/pages/sub/maintenance/task-list','maintenance-task-list',0,2,1,1,NOW(),NOW()),
('保养执行','/pages/sub/maintenance/execute','maintenance-execute',0,2,1,1,NOW(),NOW()),
('保养记录详情','/pages/sub/maintenance/record-detail','maintenance-record-detail',0,2,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `page_type`=VALUES(`page_type`), `status`=VALUES(`status`);
