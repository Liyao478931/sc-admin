-- 139_create_warehouse_device_receipt.sql
-- 产品接收（设备入库）：3 张表 + 7 权限 + 菜单（设备出入库 -> 产品接收）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:device:receive:view' OR permission='warehouse:device' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:device:receive:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:device:receive:%';
--   DROP TABLE IF EXISTS warehouse_device_receipt_log;
--   DROP TABLE IF EXISTS warehouse_device_receipt_item;
--   DROP TABLE IF EXISTS warehouse_device_receipt;

-- ========== 一、产品入库单主表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_device_receipt` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_no` varchar(30) NOT NULL DEFAULT '' COMMENT '入库单编号 DR0001',
  `receive_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '入库来源：1维修完成 2调拨 3盘盈 4其他',
  `receive_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联产品接收单ID（/business/receive）',
  `receive_no` varchar(30) NOT NULL DEFAULT '' COMMENT '关联产品接收单编号（冗余）',
  `repair_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联维修工单ID',
  `repair_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '关联维修工单编号',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(100) NOT NULL DEFAULT '' COMMENT '客户名称',
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库仓库ID',
  `warehouse_name` varchar(100) NOT NULL DEFAULT '' COMMENT '入库仓库名称',
  `warehouse_keeper_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库人ID',
  `warehouse_keeper_name` varchar(50) NOT NULL DEFAULT '' COMMENT '入库人姓名',
  `receive_date` date DEFAULT NULL COMMENT '入库日期',
  `quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '入库数量',
  `price` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '入库单价（成本）',
  `total` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '入库总价',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审核 2已审核 3已入库 4已驳回 5已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `reason` varchar(500) DEFAULT NULL COMMENT '入库原因',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_receipt_no` (`receipt_no`),
  KEY `idx_receive_id` (`receive_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品入库单主表';

-- ========== 二、产品入库明细表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_device_receipt_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `receive_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联产品接收明细ID',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称',
  `spec` varchar(200) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '入库数量',
  `price` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '入库单价',
  `total` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '入库总价',
  `device_no` varchar(100) DEFAULT NULL COMMENT '设备编号/序列号',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位ID',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_receipt_id` (`receipt_id`),
  KEY `idx_receive_item_id` (`receive_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品入库明细表';

-- ========== 三、入库操作日志表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_device_receipt_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `action_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6确认入库 7撤销 8删除',
  `action_label` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `from_status` tinyint(1) DEFAULT NULL COMMENT '操作前状态',
  `to_status` tinyint(1) DEFAULT NULL COMMENT '操作后状态',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `action_time` datetime DEFAULT NULL COMMENT '操作时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `field_snapshot` json DEFAULT NULL COMMENT '变更字段快照（JSON）',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_receipt_id` (`receipt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品入库操作日志表';

-- ========== 四、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品接收查看','warehouse:device:receive:view',2,0,'warehouse','/warehouse/device/receive/list','el-icon-box',NULL,55,1,1,'产品接收（设备入库）-查看（菜单）',NOW(),NOW()),
('产品接收新增','warehouse:device:receive:add',2,0,'warehouse',NULL,NULL,NULL,56,1,1,'新增入库单',NOW(),NOW()),
('产品接收编辑','warehouse:device:receive:edit',2,0,'warehouse',NULL,NULL,NULL,57,1,1,'编辑入库单',NOW(),NOW()),
('产品接收删除','warehouse:device:receive:delete',2,0,'warehouse',NULL,NULL,NULL,58,1,1,'删除入库单',NOW(),NOW()),
('产品接收审核','warehouse:device:receive:audit',2,0,'warehouse',NULL,NULL,NULL,59,1,1,'审核入库单（通过/驳回）',NOW(),NOW()),
('产品接收确认','warehouse:device:receive:confirm',2,0,'warehouse',NULL,NULL,NULL,60,1,1,'确认入库',NOW(),NOW()),
('产品接收导出','warehouse:device:receive:export',2,0,'warehouse',NULL,NULL,NULL,61,1,1,'导出入库单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:device:receive:%';

-- ========== 五、菜单：仓储管理 -> 设备出入库 -> 产品接收 ==========
SET @wh_menu_id = (SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @wh_menu_id, '设备出入库', '', 'el-icon-truck', 'warehouse:device', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:device' AND deleted_at IS NULL AND parent_id=@wh_menu_id);

SET @device_menu_id = (SELECT id FROM menus WHERE permission='warehouse:device' AND deleted_at IS NULL AND parent_id=@wh_menu_id LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @device_menu_id, '产品接收', '/warehouse/device/receive/list', 'el-icon-box', 'warehouse:device:receive:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:device:receive:view' AND deleted_at IS NULL AND parent_id=@device_menu_id);
