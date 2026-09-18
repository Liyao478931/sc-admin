-- 127_create_warehouse_purchase_in.sql
-- 仓储管理 -> 配件出入库 -> 采购入库（采购到货 -> 入库，含成本核算）
-- 1. 建表：warehouse_purchase_in（入库单主表）/ warehouse_purchase_in_item（入库明细）
-- 2. 权限：warehouse:parts（分组）+ warehouse:purchase:in:view/add/edit/delete/confirm/export（6条）并授权 super_admin
-- 3. 菜单：仓储管理 -> 配件出入库 -> 采购入库
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:purchase:in:view' OR permission='warehouse:parts';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:purchase:in:%' OR code='warehouse:parts');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:purchase:in:%' OR code='warehouse:parts';
--   DROP TABLE IF EXISTS warehouse_purchase_in_item;
--   DROP TABLE IF EXISTS warehouse_purchase_in;

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_purchase_in` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_no` varchar(30) NOT NULL DEFAULT '' COMMENT '入库单编号 IN+YYYYMMDD+XXXX',
  `arrival_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联采购到货单ID',
  `arrival_no` varchar(30) NOT NULL DEFAULT '' COMMENT '关联到货单编号（冗余）',
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联采购订单ID（通过到货单）',
  `order_no` varchar(30) NOT NULL DEFAULT '' COMMENT '关联采购订单编号（冗余）',
  `supplier_id` int(11) NOT NULL DEFAULT 0 COMMENT '供应商ID',
  `supplier_name` varchar(200) NOT NULL DEFAULT '' COMMENT '供应商名称（冗余）',
  `in_date` date DEFAULT NULL COMMENT '入库日期',
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库仓库ID',
  `warehouse_name` varchar(100) NOT NULL DEFAULT '' COMMENT '入库仓库名称（冗余）',
  `receiver_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库人ID',
  `receiver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '入库人姓名（冗余）',
  `in_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '入库类型：1采购入库 2退货入库 3盘盈入库',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '入库状态：0草稿 1已入库 2已撤销',
  `confirm_time` datetime DEFAULT NULL COMMENT '确认入库时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_in_no` (`in_no`),
  KEY `idx_arrival_id` (`arrival_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_status` (`status`),
  KEY `idx_in_date` (`in_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购入库单主表';

CREATE TABLE IF NOT EXISTS `warehouse_purchase_in_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `arrival_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联到货明细ID（行级追溯）',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID',
  `material_code` varchar(30) NOT NULL DEFAULT '' COMMENT '物料编码（冗余）',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称（冗余）',
  `spec` varchar(200) DEFAULT NULL COMMENT '规格型号（冗余）',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `in_quantity` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '入库数量',
  `in_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '入库单价（采购成本单价）',
  `in_total` decimal(18,4) NOT NULL DEFAULT 0 COMMENT '入库总价（数量×单价）',
  `avg_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '确认入库时加权平均单价（移动加权平均法）',
  `batch_no` varchar(50) DEFAULT NULL COMMENT '生产批次',
  `produce_date` date DEFAULT NULL COMMENT '生产日期',
  `expire_date` date DEFAULT NULL COMMENT '有效期至',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位ID',
  `location_name` varchar(100) NOT NULL DEFAULT '' COMMENT '存放货位名称（冗余）',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_in_id` (`in_id`),
  KEY `idx_material_id` (`material_id`),
  KEY `idx_arrival_item_id` (`arrival_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购入库明细表';

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('配件出入库','warehouse:parts',1,0,'warehouse','','el-icon-sold-out',NULL,20,1,1,'仓储-配件出入库（分组）',NOW(),NOW()),
('采购入库查看','warehouse:purchase:in:view',2,0,'warehouse','/warehouse/parts/purchase-in/list','el-icon-download',NULL,35,1,1,'采购入库-查看（菜单）',NOW(),NOW()),
('采购入库新增','warehouse:purchase:in:add',2,0,'warehouse',NULL,NULL,NULL,36,1,1,'新增采购入库单',NOW(),NOW()),
('采购入库编辑','warehouse:purchase:in:edit',2,0,'warehouse',NULL,NULL,NULL,37,1,1,'编辑采购入库单',NOW(),NOW()),
('采购入库删除','warehouse:purchase:in:delete',2,0,'warehouse',NULL,NULL,NULL,38,1,1,'删除采购入库单',NOW(),NOW()),
('采购入库确认','warehouse:purchase:in:confirm',2,0,'warehouse',NULL,NULL,NULL,39,1,1,'确认入库',NOW(),NOW()),
('采购入库导出','warehouse:purchase:in:export',2,0,'warehouse',NULL,NULL,NULL,40,1,1,'导出采购入库单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND (p.`code` LIKE 'warehouse:purchase:in:%' OR p.`code`='warehouse:parts');

-- ========== 三、菜单（仓储管理 -> 配件出入库 -> 采购入库） ==========
SET @warehouse_menu_id = (SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @warehouse_menu_id, '配件出入库', '', 'el-icon-sold-out', 'warehouse:parts', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:parts' AND deleted_at IS NULL AND parent_id=@warehouse_menu_id);

SET @parts_menu_id = (SELECT id FROM menus WHERE permission='warehouse:parts' AND deleted_at IS NULL AND parent_id=@warehouse_menu_id LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @parts_menu_id, '采购入库', '/warehouse/parts/purchase-in/list', 'el-icon-download', 'warehouse:purchase:in:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:purchase:in:view' AND deleted_at IS NULL AND parent_id=@parts_menu_id);
