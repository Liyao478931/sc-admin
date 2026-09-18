-- =====================================================
-- 073_add_agent_to_chat_sessions.sql
-- AI 智能平台：新建对话智能体集成
--   ai_chat_sessions 增加 agent_id（智能体ID）、agent_name（智能体名称冗余）
-- 幂等写法，可重复执行
-- =====================================================

SET @has_col1 = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ai_chat_sessions' AND COLUMN_NAME='agent_id');
SET @sql1 = IF(@has_col1 = 0,
  'ALTER TABLE `ai_chat_sessions` ADD COLUMN `agent_id` varchar(32) DEFAULT NULL COMMENT ''智能体ID（关联 ai_agents.agent_id）''',
  'SELECT 1');
PREPARE stmt1 FROM @sql1; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;

SET @has_col2 = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ai_chat_sessions' AND COLUMN_NAME='agent_name');
SET @sql2 = IF(@has_col2 = 0,
  'ALTER TABLE `ai_chat_sessions` ADD COLUMN `agent_name` varchar(100) DEFAULT NULL COMMENT ''智能体名称（冗余）''',
  'SELECT 1');
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;
