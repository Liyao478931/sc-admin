-- 192_ai_message_feedback.sql
-- AI 对话消息增加：引用来源（sources）、用户反馈（feedback）、反馈原因（feedback_reason）
-- v1.63.0 AI 助手业务上下文感知

ALTER TABLE `ai_chat_messages`
  ADD COLUMN `sources` json NULL COMMENT '引用来源列表：[{type:knowledge|data,title,source,page?,url?}]' AFTER `content`,
  ADD COLUMN `feedback` tinyint(1) NOT NULL DEFAULT 0 COMMENT '用户反馈：0=无 1=有用 2=无用' AFTER `sources`,
  ADD COLUMN `feedback_reason` varchar(500) NULL COMMENT '反馈原因（无用时填写）' AFTER `feedback`;
