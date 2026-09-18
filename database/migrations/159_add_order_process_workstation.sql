-- 159_add_order_process_workstation.sql
-- 工单整合工序/工位/BOM：production_order 与 production_order_item 增加工序/工位字段
-- 幂等写法（information_schema 判断，兼容 PDO/phpMyAdmin），可重复执行
-- 回滚 down：
--   ALTER TABLE production_order DROP COLUMN process_id, DROP COLUMN process_name, DROP COLUMN workstation_id, DROP COLUMN workstation_name;
--   ALTER TABLE production_order_item DROP COLUMN process_id, DROP COLUMN process_name, DROP COLUMN workstation_id, DROP COLUMN workstation_name, DROP COLUMN work_duration;

-- ========== 一、production_order 新增 4 列 ==========
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order' AND COLUMN_NAME='process_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order` ADD COLUMN `process_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联工序ID''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order' AND COLUMN_NAME='process_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order` ADD COLUMN `process_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''工序名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order' AND COLUMN_NAME='workstation_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order` ADD COLUMN `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联工位ID''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order' AND COLUMN_NAME='workstation_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order` ADD COLUMN `workstation_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''工位名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 二、production_order_item 新增 5 列 ==========
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order_item' AND COLUMN_NAME='process_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order_item` ADD COLUMN `process_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联工序ID''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order_item' AND COLUMN_NAME='process_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order_item` ADD COLUMN `process_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''工序名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order_item' AND COLUMN_NAME='workstation_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order_item` ADD COLUMN `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联工位ID''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order_item' AND COLUMN_NAME='workstation_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order_item` ADD COLUMN `workstation_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''工位名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_order_item' AND COLUMN_NAME='work_duration');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_order_item` ADD COLUMN `work_duration` decimal(6,2) NOT NULL DEFAULT 0 COMMENT ''计划工时（小时）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
