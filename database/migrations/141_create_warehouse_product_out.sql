-- 141_create_warehouse_product_out.sql
-- 产品出库（维修完成交付/销售/调拨）：3 张表 + 7 权限 + 菜单（设备出入库 -> 产品出库）
-- 说明：确认出库写库存流水（flow_type=8 产品出库，负数），减少可用库存
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:product:out:view' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:product:out:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:product:out:%';
--   DROP TABLE IF EXISTS warehouse_product_out_log;
--   DROP TABLE IF EXISTS warehouse_product_out_item;
--   DROP TABLE IF EXISTS warehouse_product_out;

-- ========== 一、产品出库单主表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_product_out` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `out_no` varchar(30) NOT NULL DEFAULT '' COMMENT '出库单编号 OUT0001',
  `out_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '出库类型：1维修完成交付 2调拨出库 3销售出库 4其他出库',
  `source_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '来源类型：1维修工单 2销售订单 3调拨单 4其他',
  `source_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源单据ID',
  `source_no` varchar(50) NOT NULL DEFAULT '' COMMENT '来源单据编号（冗余）',
  `repair_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联维修工单ID',
  `repair_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '维修工单编号（冗余）',
  `sales_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联销售订单ID',
  `sales_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '销售订单编号（冗余）',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(100) NOT NULL DEFAULT '' COMMENT '客户名称',
  `delivery_address` varchar(200) DEFAULT NULL COMMENT '交付地址',
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '出库仓库ID',
  `warehouse_name` varchar(100) NOT NULL DEFAULT '' COMMENT '出库仓库名称',
  `out_user_id` int(11) NOT NULL DEFAULT 0 COMMENT '出库人ID',
  `out_user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '出库人姓名',
  `out_date` date DEFAULT NULL COMMENT '出库日期',
  `total_quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '总数量',
  `total_amount` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '总金额（出库成本）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审核 2已审核 3已出库 4已驳回 5已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_out_no` (`out_no`),
  KEY `idx_repair_order_id` (`repair_order_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品出库单主表';

-- ========== 二、产品出库明细表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_product_out_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `out_id` int(11) NOT NULL DEFAULT 0 COMMENT '出库单ID',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(50) NOT NULL DEFAULT '' COMMENT '产品编码',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称',
  `specification` varchar(200) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '出库数量',
  `unit_price` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '出库单价（当前加权平均价）',
  `total_price` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '出库总价',
  `serial_number` varchar(100) DEFAULT NULL COMMENT '设备编号/序列号',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '出库货位ID',
  `location_name` varchar(100) NOT NULL DEFAULT '' COMMENT '出库货位名称（冗余）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_out_id` (`out_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品出库明细表';

-- ========== 三、出库操作日志表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_product_out_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `out_id` int(11) NOT NULL DEFAULT 0 COMMENT '出库单ID',
  `action` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6确认出库 7撤销 8删除',
  `action_label` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `before_status` tinyint(1) DEFAULT NULL COMMENT '操作前状态',
  `after_status` tinyint(1) DEFAULT NULL COMMENT '操作后状态',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `operator_time` datetime DEFAULT NULL COMMENT '操作时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `changed_fields` json DEFAULT NULL COMMENT '变更字段快照（JSON）',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_out_id` (`out_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品出库操作日志表';

-- ========== 四、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品出库查看','warehouse:product:out:view',2,0,'warehouse','/warehouse/product/out/list','el-icon-sold-out',NULL,69,1,1,'产品出库-查看（菜单）',NOW(),NOW()),
('产品出库新增','warehouse:product:out:add',2,0,'warehouse',NULL,NULL,NULL,70,1,1,'新增产品出库单',NOW(),NOW()),
('产品出库编辑','warehouse:product:out:edit',2,0,'warehouse',NULL,NULL,NULL,71,1,1,'编辑产品出库单',NOW(),NOW()),
('产品出库删除','warehouse:product:out:delete',2,0,'warehouse',NULL,NULL,NULL,72,1,1,'删除产品出库单',NOW(),NOW()),
('产品出库审核','warehouse:product:out:audit',2,0,'warehouse',NULL,NULL,NULL,73,1,1,'审核产品出库单（通过/驳回）',NOW(),NOW()),
('产品出库确认','warehouse:product:out:confirm',2,0,'warehouse',NULL,NULL,NULL,74,1,1,'确认出库',NOW(),NOW()),
('产品出库导出','warehouse:product:out:export',2,0,'warehouse',NULL,NULL,NULL,75,1,1,'导出处库单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:product:out:%';

-- ========== 五、菜单：设备出入库 -> 产品出库 ==========
SET @device_menu_id = (SELECT id FROM menus WHERE permission='warehouse:device' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0) LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @device_menu_id, '产品出库', '/warehouse/product/out/list', 'el-icon-sold-out', 'warehouse:product:out:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:product:out:view' AND deleted_at IS NULL AND parent_id=@device_menu_id);
