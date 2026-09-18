-- 160_create_process_workstation.sql
-- 工位联动工序：production_process_workstation（工位-工序多对多关联）+ production_report 增加工序/工位字段
-- 幂等写法，可重复执行
-- 回滚 down：
--   DROP TABLE IF EXISTS production_process_workstation;
--   ALTER TABLE production_report DROP COLUMN process_id, DROP COLUMN process_name, DROP COLUMN workstation_id, DROP COLUMN workstation_name;

-- ========== 一、工位-工序关联表 ==========
CREATE TABLE IF NOT EXISTS `production_process_workstation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `process_id` int(11) NOT NULL DEFAULT 0 COMMENT '工序ID（production_process）',
  `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT '工位ID（production_workstation）',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认工序：1是 0否',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pw` (`process_id`,`workstation_id`),
  KEY `idx_pw_process` (`process_id`),
  KEY `idx_pw_workstation` (`workstation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工位-工序关联表';

-- ========== 二、production_report 新增字段（幂等 ALTER） ==========
--   process_id       INT NOT NULL DEFAULT 0  COMMENT '关联工序ID'
--   process_name     VARCHAR(100) NOT NULL DEFAULT '' COMMENT '工序名称（冗余）'
--   workstation_id   INT NOT NULL DEFAULT 0  COMMENT '关联工位ID'
--   workstation_name VARCHAR(100) NOT NULL DEFAULT '' COMMENT '工位名称（冗余）'

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='process_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `process_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联工序ID''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='process_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `process_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''工序名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='workstation_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联工位ID''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='workstation_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `workstation_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''工位名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
