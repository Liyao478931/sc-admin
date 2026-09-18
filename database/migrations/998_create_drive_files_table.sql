-- =============================================
-- 998_create_drive_files_table.sql
-- 企业网盘文件表（database.sql 快照早于 drive 功能，补齐建表）
-- 基础结构（folder_password/uploader_id/view_scope/view_dept_ids/view_user_ids 由 999 迁移补充）
-- 幂等：IF NOT EXISTS，不 DROP
-- =============================================
CREATE TABLE IF NOT EXISTS `drive_files` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned DEFAULT '0',
  `file_name` varchar(200) NOT NULL,
  `file_type` varchar(20) DEFAULT '',
  `file_path` varchar(500) DEFAULT '',
  `file_size` int(11) DEFAULT '0',
  `mime` varchar(50) DEFAULT '',
  `uploader` varchar(50) DEFAULT '',
  `is_deleted` tinyint(4) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业网盘';
