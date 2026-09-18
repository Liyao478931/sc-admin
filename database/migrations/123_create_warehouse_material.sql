-- 123_create_warehouse_material.sql
-- 仓储管理 -> 基础设置 -> 物料管理（依赖仓库/货位档案）
-- 1. 建表：warehouse_material_category（物料分类）/ warehouse_material（物料）/ warehouse_stock_flow（库存流水，当前库存聚合来源）
-- 2. 预置一级物料分类（矿山设备维修常用）
-- 3. 权限：warehouse:setting:material:view/add/edit/delete/export（5条）并授权 super_admin
-- 4. 菜单：仓储管理 -> 基础设置 -> 物料管理
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:setting:material:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:setting:material:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:setting:material:%';
--   DROP TABLE IF EXISTS warehouse_stock_flow;
--   DROP TABLE IF EXISTS warehouse_material;
--   DROP TABLE IF EXISTS warehouse_material_category;

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_material_category` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL DEFAULT 0 COMMENT '父分类ID（0为顶级）',
  `category_name` varchar(100) NOT NULL DEFAULT '' COMMENT '分类名称',
  `category_code` varchar(30) NOT NULL DEFAULT '' COMMENT '分类编码',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物料分类表';

CREATE TABLE IF NOT EXISTS `warehouse_material` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `material_code` varchar(30) NOT NULL DEFAULT '' COMMENT '物料编码 M001',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称',
  `category_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料分类ID',
  `specification` varchar(200) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `material_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '物料类型：1原材料 2半成品 3成品 4备件 5辅料',
  `safety_stock` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '安全库存量',
  `max_stock` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '最高库存量',
  `min_stock` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '最低库存量',
  `purchase_cycle` int(11) NOT NULL DEFAULT 0 COMMENT '采购周期（天）',
  `default_supplier_id` int(11) NOT NULL DEFAULT 0 COMMENT '默认供应商ID',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位ID',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `images` json DEFAULT NULL COMMENT '物料图片URL数组',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_material_code` (`material_code`),
  KEY `idx_category` (`category_id`),
  KEY `idx_type` (`material_type`),
  KEY `idx_location` (`location_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物料表';

CREATE TABLE IF NOT EXISTS `warehouse_stock_flow` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID',
  `flow_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '变动类型：1采购入库 2生产领料 3成品入库 4销售出库 5调拨入库 6调拨出库 7盘盈 8盘亏 9报废出库',
  `flow_quantity` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '变动数量（正增负减）',
  `before_stock` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '变动前库存',
  `after_stock` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '变动后库存',
  `ref_type` varchar(30) NOT NULL DEFAULT '' COMMENT '关联单据类型',
  `ref_no` varchar(50) NOT NULL DEFAULT '' COMMENT '关联单据编号',
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '仓库ID',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '货位ID',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `flow_time` datetime DEFAULT NULL COMMENT '变动时间',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_material_id` (`material_id`),
  KEY `idx_warehouse_id` (`warehouse_id`),
  KEY `idx_flow_time` (`flow_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='库存流水表（当前库存=SUM(flow_quantity)）';

-- ========== 二、预置一级物料分类（矿山设备维修常用，幂等） ==========
INSERT INTO `warehouse_material_category` (`parent_id`,`category_name`,`category_code`,`sort`,`status`,`create_time`,`update_time`) VALUES
(0,'密封件','MF',1,1,NOW(),NOW()),
(0,'液压件','YY',2,1,NOW(),NOW()),
(0,'电气件','DQ',3,1,NOW(),NOW()),
(0,'机械件','JX',4,1,NOW(),NOW()),
(0,'标准件','BZ',5,1,NOW(),NOW()),
(0,'润滑油','RH',6,1,NOW(),NOW()),
(0,'焊接材料','HJ',7,1,NOW(),NOW()),
(0,'工具','GJ',8,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `category_name`=VALUES(`category_name`),`update_time`=NOW();

-- ========== 三、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('物料查看','warehouse:setting:material:view',2,0,'warehouse','/warehouse/setting/material','el-icon-goods',NULL,19,1,1,'物料管理-查看（菜单）',NOW(),NOW()),
('物料新增','warehouse:setting:material:add',2,0,'warehouse',NULL,NULL,NULL,20,1,1,'新增物料',NOW(),NOW()),
('物料编辑','warehouse:setting:material:edit',2,0,'warehouse',NULL,NULL,NULL,21,1,1,'编辑物料',NOW(),NOW()),
('物料删除','warehouse:setting:material:delete',2,0,'warehouse',NULL,NULL,NULL,22,1,1,'删除物料',NOW(),NOW()),
('物料导出','warehouse:setting:material:export',2,0,'warehouse',NULL,NULL,NULL,23,1,1,'导出物料',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` LIKE 'warehouse:setting:material:%';

-- ========== 四、菜单（基础设置 -> 物料管理） ==========
SET @setting_menu_id = (SELECT id FROM menus WHERE permission='warehouse:setting' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @setting_menu_id, '物料管理', '/warehouse/setting/material', 'el-icon-goods', 'warehouse:setting:material:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:setting:material:view' AND deleted_at IS NULL AND parent_id=@setting_menu_id);
