-- 186_create_ship_order.sql
-- 经营管理「发货单」：2 表 + 7 权限 + 1 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:ship:list:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:ship:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:ship:%';
--   DROP TABLE IF EXISTS sales_ship_order_item;
--   DROP TABLE IF EXISTS sales_ship_order;

-- ========== 一、发货单主表 ==========
CREATE TABLE IF NOT EXISTS `sales_ship_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ship_no` varchar(50) NOT NULL DEFAULT '' COMMENT '发货单编号 SH+YYYYMMDD+4位流水',
  `out_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联出库单ID',
  `out_no` varchar(50) NOT NULL DEFAULT '' COMMENT '出库单编号（冗余）',
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联销售订单ID',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '销售订单编号（冗余）',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(200) NOT NULL DEFAULT '' COMMENT '客户名称（冗余）',
  `receiver` varchar(50) NOT NULL DEFAULT '' COMMENT '收货人',
  `receiver_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '收货电话',
  `receiver_address` varchar(255) DEFAULT NULL COMMENT '收货地址',
  `ship_date` date DEFAULT NULL COMMENT '发货日期',
  `logistics_company` varchar(100) DEFAULT NULL COMMENT '物流公司',
  `tracking_no` varchar(100) DEFAULT NULL COMMENT '物流单号',
  `ship_method` tinyint(1) NOT NULL DEFAULT 1 COMMENT '发货方式：1物流 2自提 3快递',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '发货状态：0草稿 1已发货 2已签收 3已取消 4异常',
  `signer` varchar(50) DEFAULT NULL COMMENT '签收人',
  `sign_time` datetime DEFAULT NULL COMMENT '签收时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ship_no` (`ship_no`),
  KEY `idx_out` (`out_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发货单主表';

-- ========== 二、发货单明细表 ==========
CREATE TABLE IF NOT EXISTS `sales_ship_order_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ship_id` int(11) NOT NULL DEFAULT 0 COMMENT '发货单ID',
  `out_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联出库单明细ID',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(50) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `specification` varchar(100) DEFAULT NULL COMMENT '规格型号（冗余）',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位（冗余）',
  `ship_quantity` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '发货数量',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ship` (`ship_id`),
  KEY `idx_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发货单明细表';

-- ========== 三、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('发货单列表','sales:ship:list:view',2,0,'business','/business/sales/ship/list','el-icon-ship',NULL,280,1,1,'发货单-查看（菜单）',NOW(),NOW()),
('新增发货单','sales:ship:add',2,0,'business',NULL,NULL,NULL,281,1,1,'新增发货单',NOW(),NOW()),
('编辑发货单','sales:ship:edit',2,0,'business',NULL,NULL,NULL,282,1,1,'编辑发货单',NOW(),NOW()),
('删除发货单','sales:ship:delete',2,0,'business',NULL,NULL,NULL,283,1,1,'删除发货单',NOW(),NOW()),
('确认发货','sales:ship:confirm',2,0,'business',NULL,NULL,NULL,284,1,1,'确认发货',NOW(),NOW()),
('登记签收','sales:ship:sign',2,0,'business',NULL,NULL,NULL,285,1,1,'登记签收',NOW(),NOW()),
('导出发货单','sales:ship:export',2,0,'business',NULL,NULL,NULL,286,1,1,'导出发货单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:ship:%';

-- ========== 四、菜单：发货管理（id=260）-> 发货单列表（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 260, '发货单列表', '/business/sales/ship/list', 'el-icon-ship', 'sales:ship:list:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/ship/list' AND deleted_at IS NULL);
