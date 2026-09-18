-- 140_create_warehouse_product_in.sql
-- 产品入库（上架确认）：3 张表 + 7 权限 + 菜单（设备出入库 -> 产品入库）
-- 说明：库存数量由产品接收（warehouse_device_receipt, flow_type=7）增加；本模块负责货位分配与上架确认，不重复写库存流水
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:product:in:view' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:product:in:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:product:in:%';
--   DROP TABLE IF EXISTS warehouse_product_in_log;
--   DROP TABLE IF EXISTS warehouse_product_in_item;
--   DROP TABLE IF EXISTS warehouse_product_in;

-- ========== 一、产品入库单主表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_product_in` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_no` varchar(30) NOT NULL DEFAULT '' COMMENT '入库单编号 IN0001',
  `source_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '来源类型：1产品接收单 2调拨 3盘盈 4其他',
  `source_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源单据ID（产品接收单ID）',
  `source_no` varchar(30) NOT NULL DEFAULT '' COMMENT '来源单据编号（冗余）',
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库仓库ID',
  `warehouse_name` varchar(100) NOT NULL DEFAULT '' COMMENT '入库仓库名称',
  `in_user_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库人ID',
  `in_user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '入库人姓名',
  `in_date` date DEFAULT NULL COMMENT '入库日期',
  `total_quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '总数量',
  `total_amount` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '总金额',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审核 2已审核 3已入库 4已驳回 5已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_in_no` (`in_no`),
  KEY `idx_source_id` (`source_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品入库单主表';

-- ========== 二、产品入库明细表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_product_in_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `source_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源明细ID（产品接收明细）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(50) NOT NULL DEFAULT '' COMMENT '产品编码',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称',
  `specification` varchar(200) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '入库数量',
  `unit_price` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '入库单价',
  `total_price` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '入库总价',
  `serial_number` varchar(100) DEFAULT NULL COMMENT '设备编号/序列号',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位ID',
  `location_name` varchar(100) NOT NULL DEFAULT '' COMMENT '存放货位名称（冗余）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_in_id` (`in_id`),
  KEY `idx_source_item_id` (`source_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品入库明细表';

-- ========== 三、入库操作日志表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_product_in_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `action` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6确认入库 7撤销 8删除',
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
  KEY `idx_in_id` (`in_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品入库操作日志表';

-- ========== 四、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品入库查看','warehouse:product:in:view',2,0,'warehouse','/warehouse/product/in/list','el-icon-sort',NULL,62,1,1,'产品入库-查看（菜单）',NOW(),NOW()),
('产品入库新增','warehouse:product:in:add',2,0,'warehouse',NULL,NULL,NULL,63,1,1,'新增产品入库单',NOW(),NOW()),
('产品入库编辑','warehouse:product:in:edit',2,0,'warehouse',NULL,NULL,NULL,64,1,1,'编辑产品入库单',NOW(),NOW()),
('产品入库删除','warehouse:product:in:delete',2,0,'warehouse',NULL,NULL,NULL,65,1,1,'删除产品入库单',NOW(),NOW()),
('产品入库审核','warehouse:product:in:audit',2,0,'warehouse',NULL,NULL,NULL,66,1,1,'审核产品入库单（通过/驳回）',NOW(),NOW()),
('产品入库确认','warehouse:product:in:confirm',2,0,'warehouse',NULL,NULL,NULL,67,1,1,'确认入库（上架）',NOW(),NOW()),
('产品入库导出','warehouse:product:in:export',2,0,'warehouse',NULL,NULL,NULL,68,1,1,'导出入库单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:product:in:%';

-- ========== 五、菜单：设备出入库 -> 产品入库 ==========
SET @device_menu_id = (SELECT id FROM menus WHERE permission='warehouse:device' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0) LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @device_menu_id, '产品入库', '/warehouse/product/in/list', 'el-icon-sort', 'warehouse:product:in:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:product:in:view' AND deleted_at IS NULL AND parent_id=@device_menu_id);
