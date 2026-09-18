-- =====================================================
-- 009_create_device_master_placeholder.sql
-- 设备台账主表（占位表）
-- 说明：设备分类删除时校验是否被设备引用（DeviceCategoryController::checkDeviceReference），
--       本表存在后该校验立即生效；后续设备台账模块开发时可在此表基础上扩展字段。
-- =====================================================
CREATE TABLE IF NOT EXISTS `device_master` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `category_id` int(11) unsigned NOT NULL DEFAULT '0'    COMMENT '所属设备分类ID（关联 device_category.id）',
  `device_code` varchar(50)  NOT NULL DEFAULT ''         COMMENT '设备编号',
  `name`        varchar(100) NOT NULL DEFAULT ''         COMMENT '设备名称',
  `model`       varchar(100) NOT NULL DEFAULT ''         COMMENT '规格型号',
  `status`      tinyint(4)   NOT NULL DEFAULT '1'        COMMENT '状态：1使用中 0停用',
  `create_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备台账主表（占位，待设备台账模块完善）';
