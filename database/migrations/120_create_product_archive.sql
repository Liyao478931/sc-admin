-- 120_create_product_archive.sql
-- 产品档案（产品维修履历）增强
-- 1. business_products 增加档案字段（设备编号/生产厂家/出厂日期/当前位置/图片）
-- 2. 建表：business_product_repair_history（维修履历）/ business_product_status_log（状态变更日志）
-- 3. 权限：business:receive:archive:export
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM permissions WHERE code='business:receive:archive:export';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='business:receive:archive:export');
--   DROP TABLE IF EXISTS business_product_status_log;
--   DROP TABLE IF EXISTS business_product_repair_history;
--   ALTER TABLE business_products DROP COLUMN product_image, DROP COLUMN current_location, DROP COLUMN manufacture_date, DROP COLUMN manufacturer, DROP COLUMN serial_number;

-- ========== 一、产品表增加档案字段 ==========
ALTER TABLE `business_products`
  ADD COLUMN `serial_number` varchar(100) DEFAULT NULL COMMENT '设备编号/序列号（设备类唯一标识）' AFTER `specification`,
  ADD COLUMN `manufacturer` varchar(100) DEFAULT NULL COMMENT '生产厂家' AFTER `serial_number`,
  ADD COLUMN `manufacture_date` date DEFAULT NULL COMMENT '出厂日期' AFTER `manufacturer`,
  ADD COLUMN `current_location` varchar(100) DEFAULT NULL COMMENT '当前所在位置（如维修车间/成品区/XX煤矿）' AFTER `status`,
  ADD COLUMN `product_image` varchar(255) DEFAULT NULL COMMENT '产品图片URL' AFTER `current_location`;

-- ========== 二、产品维修履历表 ==========
CREATE TABLE IF NOT EXISTS `business_product_repair_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '维修工单ID',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '维修工单编号（冗余）',
  `repair_type` tinyint(1) NOT NULL DEFAULT 3 COMMENT '维修类型：1大修 2中修 3小修 4保养',
  `content` varchar(500) DEFAULT NULL COMMENT '维修内容描述',
  `start_date` date DEFAULT NULL COMMENT '维修开始日期',
  `complete_date` date DEFAULT NULL COMMENT '维修完成日期',
  `repairer` varchar(50) DEFAULT NULL COMMENT '维修负责人',
  `result` varchar(20) NOT NULL DEFAULT '已修复' COMMENT '维修结果：已修复/部分修复/无法修复',
  `parts` text COMMENT '更换配件清单（JSON数组）',
  `cost` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT '维修费用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_work_order` (`work_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品维修履历表';

-- ========== 三、产品状态变更日志表 ==========
CREATE TABLE IF NOT EXISTS `business_product_status_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `before_status` tinyint(1) DEFAULT NULL COMMENT '变更前状态（1-5）',
  `after_status` tinyint(1) NOT NULL DEFAULT 5 COMMENT '变更后状态（1-5）',
  `reason` varchar(255) DEFAULT NULL COMMENT '变更原因',
  `ref_no` varchar(50) DEFAULT NULL COMMENT '关联单据号（接收单/维修工单编号）',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品状态变更日志表';

-- ========== 四、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品档案导出','business:receive:archive:export',2,0,'business',NULL,NULL,NULL,88,1,1,'导出产品档案',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='business:receive:archive:export';
