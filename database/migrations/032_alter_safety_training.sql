-- =====================================================
-- 032_alter_safety_training.sql
-- 培训讲师/课件表结构完善：补充索引与 MIME 字段
-- =====================================================

-- 讲师表：补充讲师姓名、状态索引
ALTER TABLE `safety_training_teacher`
  ADD INDEX `idx_teacher_name` (`teacher_name`),
  ADD INDEX `idx_status` (`status`);

-- 课件表：补充 mime_type 字段 + 名称/文件类型索引
ALTER TABLE `safety_training_courseware`
  ADD COLUMN `mime_type` varchar(100) DEFAULT NULL COMMENT '文件MIME类型' AFTER `file_path`,
  ADD INDEX `idx_courseware_name` (`courseware_name`),
  ADD INDEX `idx_file_type` (`file_type`);
