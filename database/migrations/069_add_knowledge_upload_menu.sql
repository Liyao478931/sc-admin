-- =====================================================
-- 069_add_knowledge_upload_menu.sql
-- AI 智能平台：知识库文档上传功能
--   菜单：知识库 → 文档上传（/ai/knowledge/upload）
-- 幂等写法，可重复执行
-- =====================================================

-- 文档上传（子菜单，挂知识库目录下）
SET @ai_kb_id = (SELECT id FROM menus WHERE permission='ai:knowledge:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_kb_id, '文档上传', '/ai/knowledge/upload', 'el-icon-upload2', 'ai:knowledge:add', 20, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:knowledge:add' AND path='/ai/knowledge/upload' AND deleted_at IS NULL);
