-- =====================================================
-- 070_create_ai_knowledge_chunks.sql
-- AI 智能平台：知识库检索测试功能
--   1. 文档切片表 ai_knowledge_chunks（关键词检索 / 后续向量检索基础）
--   2. 菜单：知识库 → 检索测试（/ai/knowledge/retrieve）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、文档切片表 ==========
CREATE TABLE IF NOT EXISTS `ai_knowledge_chunks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `chunk_id` varchar(32) NOT NULL DEFAULT '' COMMENT '切片唯一标识（UUID去横线）',
  `doc_id` varchar(32) NOT NULL DEFAULT '' COMMENT '文档ID（关联 ai_knowledge_documents.doc_id）',
  `kb_id` varchar(32) NOT NULL DEFAULT '' COMMENT '知识库ID',
  `chunk_index` int(11) NOT NULL DEFAULT 0 COMMENT '切片序号',
  `content` text COMMENT '切片文本内容',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_chunk_id` (`chunk_id`),
  KEY `idx_kb_id` (`kb_id`),
  KEY `idx_doc_index` (`doc_id`, `chunk_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI知识库文档切片表';

-- ========== 二、菜单：检索测试 ==========
SET @ai_kb_id = (SELECT id FROM menus WHERE permission='ai:knowledge:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_kb_id, '检索测试', '/ai/knowledge/retrieve', 'el-icon-search', 'ai:knowledge:list', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:knowledge:list' AND path='/ai/knowledge/retrieve' AND deleted_at IS NULL);
