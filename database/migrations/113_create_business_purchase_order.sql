-- 113_create_business_purchase_order.sql
-- 经营管理 -> 采购管理 -> 采购订单
-- 1. 建表：business_purchase_order（主表）/ business_purchase_order_item（明细）/ business_purchase_order_log（执行日志）
-- 2. 权限：business:purchase:order:list/add/edit/delete/export/approve（6个）并授权 super_admin
-- 3. 菜单：经营管理 -> 采购管理 -> 采购订单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='business:purchase:order:list';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:purchase:order:%');
--   DELETE FROM permissions WHERE code LIKE 'business:purchase:order:%';
--   DROP TABLE IF EXISTS business_purchase_order_log;
--   DROP TABLE IF EXISTS business_purchase_order_item;
--   DROP TABLE IF EXISTS business_purchase_order;

CREATE TABLE IF NOT EXISTS `business_purchase_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_no` varchar(30) NOT NULL DEFAULT '' COMMENT '订单编号 PO+YYYYMMDD+XXXX',
  `title` varchar(200) NOT NULL DEFAULT '' COMMENT '订单标题',
  `supplier_id` int(11) NOT NULL DEFAULT 0 COMMENT '供应商ID',
  `supplier_name` varchar(200) NOT NULL DEFAULT '' COMMENT '供应商名称（冗余）',
  `request_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源采购申请ID',
  `request_no` varchar(30) NOT NULL DEFAULT '' COMMENT '来源采购申请编号（冗余）',
  `order_date` date DEFAULT NULL COMMENT '订单日期',
  `expected_date` date DEFAULT NULL COMMENT '期望交货日期',
  `total_amount` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '订单总金额',
  `order_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '订单状态：0草稿 1已确认 2已发货 3部分入库 4已入库 5已关闭 6已中止',
  `payment_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '付款状态：0未付款 1部分付款 2已付款',
  `approval_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核状态：0草稿 1待审核 2已审核 3已驳回',
  `approver_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `approver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审核人姓名（冗余）',
  `approval_date` datetime DEFAULT NULL COMMENT '审核日期',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `receive_address` varchar(255) DEFAULT NULL COMMENT '收货地址',
  `receiver` varchar(50) DEFAULT NULL COMMENT '收货人',
  `receiver_phone` varchar(20) DEFAULT NULL COMMENT '收货电话',
  `payment_terms` varchar(255) DEFAULT NULL COMMENT '付款条款',
  `transport_type` varchar(50) DEFAULT NULL COMMENT '运输方式',
  `received_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已入库总数量',
  `remark` text COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_supplier` (`supplier_id`),
  KEY `idx_request` (`request_id`),
  KEY `idx_order_status` (`order_status`),
  KEY `idx_approval` (`approval_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购订单主表';

CREATE TABLE IF NOT EXISTS `business_purchase_order_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `request_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源申请明细ID（行级追溯）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '规格型号（冗余）',
  `product_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT '下单数量',
  `received_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已入库数量',
  `unit_price` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '采购单价',
  `total_amount` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '总价（数量x单价）',
  `need_date` date DEFAULT NULL COMMENT '需求日期',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_request_item` (`request_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购订单明细表';

CREATE TABLE IF NOT EXISTS `business_purchase_order_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `action_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2提交审核 3审核通过 4审核驳回 5确认 6发货 7入库 8关闭 9中止',
  `action_label` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型标签（冗余）',
  `from_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作前订单状态',
  `to_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作后订单状态',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名（冗余）',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购订单执行日志表';

-- ========== 权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('采购订单列表','business:purchase:order:list',1,0,'business','/business/purchase/order/list','el-icon-s-order',NULL,50,1,1,'采购订单-列表/详情（菜单/查看）',NOW(),NOW()),
('采购订单新增','business:purchase:order:add',2,0,'business',NULL,NULL,NULL,51,1,1,'新增采购订单',NOW(),NOW()),
('采购订单编辑','business:purchase:order:edit',2,0,'business',NULL,NULL,NULL,52,1,1,'编辑采购订单',NOW(),NOW()),
('采购订单删除','business:purchase:order:delete',2,0,'business',NULL,NULL,NULL,53,1,1,'删除采购订单',NOW(),NOW()),
('采购订单导出','business:purchase:order:export',2,0,'business',NULL,NULL,NULL,54,1,1,'导出采购订单列表',NOW(),NOW()),
('采购订单审核','business:purchase:order:approve',2,0,'business',NULL,NULL,NULL,55,1,1,'审核采购订单（提交/通过/驳回）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:purchase:order:list','business:purchase:order:add','business:purchase:order:edit','business:purchase:order:delete','business:purchase:order:export','business:purchase:order:approve');

-- ========== 菜单（经营管理 -> 采购管理 -> 采购订单） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);
SET @purchase_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='采购管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @purchase_menu_id, '采购订单', '/business/purchase/order/list', 'el-icon-s-order', 'business:purchase:order:list', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:order:list' AND deleted_at IS NULL AND type=2);
