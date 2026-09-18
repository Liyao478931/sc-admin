-- =====================================================
-- 071_upgrade_knowledge_upload.sql
-- AI 智能平台：文档上传功能升级
--   1. ai_knowledge_documents 增加 progress（处理进度）
--   2. 权限：ai:knowledge:upload（文档上传）
--   3. 菜单：文档上传权限调整为 ai:knowledge:upload
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、文档表增加 progress ==========
SET @has_col = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ai_knowledge_documents' AND COLUMN_NAME='progress');
SET @sql = IF(@has_col = 0,
  'ALTER TABLE `ai_knowledge_documents` ADD COLUMN `progress` int(11) NOT NULL DEFAULT 0 COMMENT ''处理进度（0-100）''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ========== 二、权限：文档上传 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('文档上传', 'ai:knowledge:upload', 2, 0, 'ai', '/ai/knowledge/upload', NULL, NULL, 5, 1, 1, '上传知识库文档')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:knowledge:upload');

-- ========== 三、菜单权限调整：文档上传 → ai:knowledge:upload ==========
UPDATE `menus` SET `permission`='ai:knowledge:upload'
WHERE `path`='/ai/knowledge/upload' AND `deleted_at` IS NULL;
