-- 119_create_product_receive.sql
-- 经营管理 -> 产品接收管理（接收单列表 / 产品档案 / 运输管理）
-- 聚焦煤矿拉回设备主场景；采购到货接收由采购到货模块负责，本模块不包含
-- 1. 建表：business_product_receipt（接收单）/ business_product_receipt_item（明细）/ business_product_receipt_transport（运输信息）/ business_product_receipt_log（操作日志）
-- 2. 权限：business:receive:list/add/edit/delete/confirm/export/archive:view/transport:view（8条）并授权 super_admin
-- 3. 菜单：经营管理 -> 产品接收管理 -> 接收单列表 / 产品档案 / 运输管理
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('business:receive:list','business:receive:archive:view','business:receive:transport:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:receive:%');
--   DELETE FROM permissions WHERE code LIKE 'business:receive:%';
--   DROP TABLE IF EXISTS business_product_receipt_log;
--   DROP TABLE IF EXISTS business_product_receipt_transport;
--   DROP TABLE IF EXISTS business_product_receipt_item;
--   DROP TABLE IF EXISTS business_product_receipt;

-- ========== 一、接收单主表 ==========
CREATE TABLE IF NOT EXISTS `business_product_receipt` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_no` varchar(30) NOT NULL DEFAULT '' COMMENT '接收单编号 RC+YYYYMMDD+XXXX',
  `receipt_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '接收类型：1煤矿拉回 2维修完成移交 3客户退货 4内部调拨 5其他',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联维修工单ID（煤矿拉回/维修完成时）',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '关联维修工单编号（冗余）',
  `source_location` varchar(100) DEFAULT NULL COMMENT '来源地点（如XX煤矿，煤矿拉回必填）',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID（客户退货时）',
  `customer_name` varchar(200) NOT NULL DEFAULT '' COMMENT '客户名称（冗余）',
  `receipt_date` date DEFAULT NULL COMMENT '接收日期',
  `receiver_id` int(11) NOT NULL DEFAULT 0 COMMENT '接收人ID',
  `receiver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '接收人姓名（冗余）',
  `product_status` tinyint(1) NOT NULL DEFAULT 5 COMMENT '产品状态：1完好 2待维修 3待保养 4报废 5待检验',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '接收状态：0草稿 1已接收 2已入库 3已移交/已发货',
  `remark` text COMMENT '整体备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_receipt_no` (`receipt_no`),
  KEY `idx_type` (`receipt_type`),
  KEY `idx_status` (`status`),
  KEY `idx_receipt_date` (`receipt_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品接收单主表';

-- ========== 二、接收明细表 ==========
CREATE TABLE IF NOT EXISTS `business_product_receipt_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` int(11) NOT NULL DEFAULT 0 COMMENT '接收单ID',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID（关联产品表，无则0）',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码（冗余/手填）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称',
  `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '规格型号',
  `product_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT '接收数量',
  `product_status` tinyint(1) NOT NULL DEFAULT 5 COMMENT '产品状态：1完好 2待维修 3待保养 4报废 5待检验',
  `serial_no` varchar(100) DEFAULT NULL COMMENT '设备编号/序列号',
  `source_location` varchar(100) DEFAULT NULL COMMENT '来源矿井（从接收单带入）',
  `manufacturer` varchar(100) DEFAULT NULL COMMENT '生产厂家',
  `manufacture_date` date DEFAULT NULL COMMENT '出厂日期',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_receipt_id` (`receipt_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品接收明细表';

-- ========== 三、运输信息表 ==========
CREATE TABLE IF NOT EXISTS `business_product_receipt_transport` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` int(11) NOT NULL DEFAULT 0 COMMENT '接收单ID',
  `transport_no` varchar(30) NOT NULL DEFAULT '' COMMENT '运输单号 TR+YYYYMMDD+XXXX',
  `transport_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '运输方式：1公司派车 2外包物流 3客户自送 4其他',
  `plate_no` varchar(30) DEFAULT NULL COMMENT '车牌号',
  `driver_name` varchar(50) DEFAULT NULL COMMENT '司机姓名',
  `driver_phone` varchar(30) DEFAULT NULL COMMENT '司机联系方式',
  `logistics_company` varchar(100) DEFAULT NULL COMMENT '物流公司',
  `track_no` varchar(60) DEFAULT NULL COMMENT '物流单号',
  `depart_date` date DEFAULT NULL COMMENT '发车日期',
  `expected_arrive_date` date DEFAULT NULL COMMENT '预计到达日期',
  `actual_arrive_date` date DEFAULT NULL COMMENT '实际到达日期',
  `ship_address` varchar(200) DEFAULT NULL COMMENT '发货地址（如XX煤矿）',
  `receive_address` varchar(200) DEFAULT NULL COMMENT '收货地址（公司地址）',
  `freight_amount` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT '运费金额',
  `transport_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '运输状态：0待发车 1运输中 2已到达 3已签收',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_receipt_id` (`receipt_id`),
  KEY `idx_transport_no` (`transport_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品接收运输信息表';

-- ========== 四、操作日志表 ==========
CREATE TABLE IF NOT EXISTS `business_product_receipt_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` int(11) NOT NULL DEFAULT 0 COMMENT '接收单ID',
  `action` varchar(50) NOT NULL DEFAULT '' COMMENT '操作动作',
  `content` varchar(500) DEFAULT NULL COMMENT '操作内容',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_receipt_id` (`receipt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品接收操作日志表';

-- ========== 五、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品接收','business:receive:list',1,0,'business','/business/receive/list','el-icon-box',NULL,80,1,1,'产品接收-列表/详情（菜单/查看）',NOW(),NOW()),
('产品接收新增','business:receive:add',2,0,'business',NULL,NULL,NULL,81,1,1,'新增接收单',NOW(),NOW()),
('产品接收编辑','business:receive:edit',2,0,'business',NULL,NULL,NULL,82,1,1,'编辑接收单',NOW(),NOW()),
('产品接收删除','business:receive:delete',2,0,'business',NULL,NULL,NULL,83,1,1,'删除接收单',NOW(),NOW()),
('产品接收确认','business:receive:confirm',2,0,'business',NULL,NULL,NULL,84,1,1,'确认接收',NOW(),NOW()),
('产品接收导出','business:receive:export',2,0,'business',NULL,NULL,NULL,85,1,1,'导出接收单',NOW(),NOW()),
('产品档案查看','business:receive:archive:view',1,0,'business','/business/receive/archive','el-icon-collection',NULL,86,1,1,'产品档案-查看（菜单）',NOW(),NOW()),
('运输管理查看','business:receive:transport:view',1,0,'business','/business/receive/transport','el-icon-truck',NULL,87,1,1,'运输管理-查看（菜单）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:receive:list','business:receive:add','business:receive:edit','business:receive:delete','business:receive:confirm','business:receive:export','business:receive:archive:view','business:receive:transport:view');

-- ========== 六、菜单（经营管理 -> 产品接收管理 -> 3 页面） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '产品接收管理', '/business/receive/list', 'el-icon-box', 'business:receive:list', 40, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:receive:list' AND deleted_at IS NULL AND type=1);

SET @receive_parent_id = (SELECT id FROM menus WHERE permission='business:receive:list' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @receive_parent_id, '接收单列表', '/business/receive/list', 'el-icon-box', 'business:receive:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:receive:list' AND deleted_at IS NULL AND type=2);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @receive_parent_id, '产品档案', '/business/receive/archive', 'el-icon-collection', 'business:receive:archive:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:receive:archive:view' AND deleted_at IS NULL AND type=2);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @receive_parent_id, '运输管理', '/business/receive/transport', 'el-icon-truck', 'business:receive:transport:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:receive:transport:view' AND deleted_at IS NULL AND type=2);
