-- 174_create_notify_config.sql
-- 统一审批「通知设置」规范化：approval_notify_config 增加新字段 + 数据迁移（旧字段保留兼容）
-- 幂等写法，可重复执行
-- 回滚 down：
--   ALTER TABLE approval_notify_config DROP COLUMN enable_site, DROP COLUMN enable_email, DROP COLUMN enable_sms,
--     DROP COLUMN email_address, DROP COLUMN mobile,
--     DROP COLUMN scene_todo, DROP COLUMN scene_urge, DROP COLUMN scene_approve,
--     DROP COLUMN scene_reject, DROP COLUMN scene_transfer, DROP COLUMN scene_overdue;

-- ========== 一、增加新字段（新字段均不存在时一次性添加） ==========
SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='approval_notify_config' AND COLUMN_NAME IN ('enable_site','enable_email','enable_sms','email_address','mobile','scene_todo','scene_urge','scene_approve','scene_reject','scene_transfer','scene_overdue'));
SET @sql := IF(@cnt = 0,
'ALTER TABLE `approval_notify_config`
  ADD COLUMN `enable_site` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''站内信通知（默认开，不可关闭）'' AFTER `inmail`,
  ADD COLUMN `enable_email` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''邮件通知开关'' AFTER `enable_site`,
  ADD COLUMN `enable_sms` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''短信通知开关'' AFTER `enable_email`,
  ADD COLUMN `email_address` varchar(100) DEFAULT NULL COMMENT ''接收通知邮箱'' AFTER `enable_sms`,
  ADD COLUMN `mobile` varchar(20) DEFAULT NULL COMMENT ''接收通知手机号'' AFTER `email_address`,
  ADD COLUMN `scene_todo` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''待办提醒'' AFTER `mobile`,
  ADD COLUMN `scene_urge` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''催办提醒'' AFTER `scene_todo`,
  ADD COLUMN `scene_approve` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''通过通知'' AFTER `scene_urge`,
  ADD COLUMN `scene_reject` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''驳回通知'' AFTER `scene_approve`,
  ADD COLUMN `scene_transfer` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''转办通知'' AFTER `scene_reject`,
  ADD COLUMN `scene_overdue` tinyint(1) NOT NULL DEFAULT 1 COMMENT ''超时提醒'' AFTER `scene_transfer`',
'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 二、数据迁移：旧字段 -> 新字段（幂等） ==========
UPDATE `approval_notify_config` SET
  `enable_site` = 1,
  `enable_email` = IF(`email_switch` IS NOT NULL, `email_switch`, `enable_email`),
  `enable_sms` = IF(`sms_switch` IS NOT NULL, `sms_switch`, `enable_sms`),
  `email_address` = IF(`email` IS NOT NULL AND `email` <> '', `email`, `email_address`),
  `mobile` = IF(`phone` IS NOT NULL AND `phone` <> '', `phone`, `mobile`),
  `scene_todo` = IF(`scenes` LIKE '%todo%', 1, 0),
  `scene_urge` = IF(`scenes` LIKE '%urge%', 1, 0),
  `scene_approve` = IF(`scenes` LIKE '%approve%', 1, 0),
  `scene_reject` = IF(`scenes` LIKE '%reject%', 1, 0),
  `scene_transfer` = IF(`scenes` LIKE '%transfer%', 1, 0),
  `scene_overdue` = IF(`scenes` LIKE '%timeout%', 1, 0),
  `updated_at` = NOW()
WHERE `enable_site` IS NOT NULL;
