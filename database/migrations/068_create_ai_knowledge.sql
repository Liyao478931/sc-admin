-- =====================================================
-- 068_create_ai_knowledge.sql
-- AI 智能平台：知识库列表功能
--   1. 知识库表 ai_knowledge_bases
--   2. 知识库文档表 ai_knowledge_documents
--   3. 权限（ai:knowledge 系列）
--   4. 菜单（AI智能平台 → 知识库 → 知识库列表）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、知识库表 ==========
CREATE TABLE IF NOT EXISTS `ai_knowledge_bases` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `kb_id` varchar(32) NOT NULL DEFAULT '' COMMENT '知识库唯一标识（UUID去横线）',
  `kb_name` varchar(100) NOT NULL DEFAULT '' COMMENT '知识库名称',
  `description` varchar(255) DEFAULT NULL COMMENT '知识库描述',
  `embedding_model` varchar(50) NOT NULL DEFAULT 'text-embedding-v3' COMMENT '向量化模型',
  `chunk_size` int(11) NOT NULL DEFAULT 512 COMMENT '切片大小',
  `overlap` int(11) NOT NULL DEFAULT 50 COMMENT '重叠大小',
  `doc_count` int(11) NOT NULL DEFAULT 0 COMMENT '文档数量',
  `total_size` bigint(20) NOT NULL DEFAULT 0 COMMENT '总大小（字节）',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态：pending/processing/completed/failed',
  `progress` int(11) NOT NULL DEFAULT 0 COMMENT '向量化进度（0-100）',
  `error_message` text COMMENT '错误信息',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_kb_id` (`kb_id`),
  KEY `idx_created_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI知识库表';

-- ========== 二、知识库文档表 ==========
CREATE TABLE IF NOT EXISTS `ai_knowledge_documents` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `doc_id` varchar(32) NOT NULL DEFAULT '' COMMENT '文档唯一标识（UUID去横线）',
  `kb_id` varchar(32) NOT NULL DEFAULT '' COMMENT '知识库ID',
  `doc_name` varchar(255) NOT NULL DEFAULT '' COMMENT '文档名称',
  `doc_type` varchar(20) NOT NULL DEFAULT '' COMMENT '文档类型：pdf/word/excel/ppt/txt/md/html',
  `doc_size` bigint(20) NOT NULL DEFAULT 0 COMMENT '文档大小（字节）',
  `doc_path` varchar(500) NOT NULL DEFAULT '' COMMENT '文档存储路径',
  `chunk_count` int(11) NOT NULL DEFAULT 0 COMMENT '切片数量',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '向量化状态：pending/processing/completed/failed',
  `error_message` text COMMENT '错误信息',
  `uploaded_by` int(11) NOT NULL DEFAULT 0 COMMENT '上传人ID',
  `uploaded_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '上传人姓名',
  `upload_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `process_time` datetime DEFAULT NULL COMMENT '处理完成时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_doc_id` (`doc_id`),
  KEY `idx_kb_status` (`kb_id`, `status`),
  KEY `idx_upload_time` (`upload_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI知识库文档表';

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('知识库', 'ai:knowledge:view', 1, 0, 'ai', '/ai/knowledge/list', 'el-icon-collection', NULL, 0, 1, 1, 'AI知识库目录'),
  ('知识库列表', 'ai:knowledge:list', 1, 0, 'ai', '/ai/knowledge/list', 'el-icon-collection', NULL, 1, 1, 1, 'AI知识库列表菜单'),
  ('知识库创建', 'ai:knowledge:add', 2, 0, 'ai', '/ai/knowledge/list', NULL, NULL, 2, 1, 1, '创建知识库'),
  ('知识库编辑', 'ai:knowledge:edit', 2, 0, 'ai', '/ai/knowledge/list', NULL, NULL, 3, 1, 1, '编辑知识库'),
  ('知识库删除', 'ai:knowledge:delete', 2, 0, 'ai', '/ai/knowledge/list', NULL, NULL, 4, 1, 1, '删除知识库')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:knowledge:view','ai:knowledge:list','ai:knowledge:add','ai:knowledge:edit','ai:knowledge:delete');

-- ========== 四、菜单 ==========
-- 知识库（目录，挂 AI智能平台 下）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '知识库', '', 'el-icon-collection', 'ai:knowledge:view', 20, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:knowledge:view' AND deleted_at IS NULL);

-- 知识库列表（子菜单）
SET @ai_kb_id = (SELECT id FROM menus WHERE permission='ai:knowledge:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_kb_id, '知识库列表', '/ai/knowledge/list', 'el-icon-collection', 'ai:knowledge:list', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:knowledge:list' AND deleted_at IS NULL);
