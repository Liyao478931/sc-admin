-- 175_create_phrases.sql
-- 统一审批「常用语管理」：approval_common_phrase 增加 use_count/remark/deleted_at + 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/approval/phrases';
--   ALTER TABLE approval_common_phrase DROP COLUMN use_count, DROP COLUMN remark, DROP COLUMN deleted_at;

-- ========== 一、增加字段（幂等） ==========
SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='approval_common_phrase' AND COLUMN_NAME IN ('use_count','remark','deleted_at'));
SET @sql := IF(@cnt = 0,
'ALTER TABLE `approval_common_phrase`
  ADD COLUMN `use_count` int(11) NOT NULL DEFAULT 0 COMMENT ''使用次数'' AFTER `sort`,
  ADD COLUMN `remark` varchar(200) DEFAULT NULL COMMENT ''备注'' AFTER `use_count`,
  ADD COLUMN `deleted_at` datetime DEFAULT NULL COMMENT ''软删除时间'' AFTER `remark`',
'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 二、菜单：统一审批 -> 常用语管理（叶子，path 幂等，复用 approval:task:view） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='approval:view' AND deleted_at IS NULL LIMIT 1), '常用语管理', '/approval/phrases', 'el-icon-chat-dot-square', 'approval:task:view', 70, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/approval/phrases' AND deleted_at IS NULL);
