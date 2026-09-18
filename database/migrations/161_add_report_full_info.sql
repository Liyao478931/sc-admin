-- 161_add_report_full_info.sql
-- 报工完整信息采集：production_report 增加设备/数量/工时/照片/自动工分字段 + production_report_material 材料明细表
-- 说明：ALTER 由执行器（信息架构检查）幂等添加；表创建幂等
-- 回滚 down：
--   DROP TABLE IF EXISTS production_report_material;
--   ALTER TABLE production_report DROP COLUMN device_id, DROP COLUMN device_name, DROP COLUMN device_code,
--     DROP COLUMN quantity, DROP COLUMN duration, DROP COLUMN photos, DROP COLUMN calculated_score;

-- ========== 一、报工主表新增字段 ==========
--   device_id         INT NOT NULL DEFAULT 0  COMMENT '关联设备ID（device_assets）'
--   device_name       VARCHAR(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）'
--   device_code       VARCHAR(50) NOT NULL DEFAULT '' COMMENT '设备编码（冗余）'
--   quantity          INT NOT NULL DEFAULT 1  COMMENT '完成数量（件）'
--   duration          DECIMAL(6,1) NOT NULL DEFAULT 0 COMMENT '设备使用时长（小时）'
--   photos            JSON DEFAULT NULL        COMMENT '作业照片URL数组'
--   calculated_score  DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '自动计算工分（工序定额×数量）'

-- ========== 二、报工材料明细表 ==========
CREATE TABLE IF NOT EXISTS `production_report_material` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `report_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联报工主表ID',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID（warehouse_material）',
  `material_code` varchar(50) NOT NULL DEFAULT '' COMMENT '物料编码（冗余）',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称（冗余）',
  `specification` varchar(100) NOT NULL DEFAULT '' COMMENT '规格型号（冗余）',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '使用数量',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_rm_report` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报工材料明细表';

-- ========== 三、production_report 新增字段（幂等 ALTER） ==========
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='device_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `device_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联设备ID（device_assets）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='device_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `device_name` varchar(100) NOT NULL DEFAULT '''' COMMENT ''设备名称（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='device_code');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `device_code` varchar(50) NOT NULL DEFAULT '''' COMMENT ''设备编码（冗余）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='quantity');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `quantity` int(11) NOT NULL DEFAULT 1 COMMENT ''完成数量（件）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='duration');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `duration` decimal(6,1) NOT NULL DEFAULT 0 COMMENT ''设备使用时长（小时）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='photos');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `photos` json DEFAULT NULL COMMENT ''作业照片URL数组''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='production_report' AND COLUMN_NAME='calculated_score');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `production_report` ADD COLUMN `calculated_score` decimal(10,2) NOT NULL DEFAULT 0 COMMENT ''自动计算工分（工序定额×数量）''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
