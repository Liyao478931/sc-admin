-- 106_create_business_product_bom.sql
-- 经营管理 -> 产品管理 -> BOM管理
-- 1. 建表：business_product_bom（BOM主表）/ business_product_bom_item（BOM子项表）
-- 2. 权限：business:product:bom:list/add/edit/delete/export/approve/default（7个）并授权 super_admin
-- 3. 菜单：经营管理 -> 产品管理 -> BOM管理
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission LIKE 'business:product:bom:%';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:product:bom:%');
--   DELETE FROM permissions WHERE code LIKE 'business:product:bom:%';
--   DROP TABLE IF EXISTS business_product_bom_item;
--   DROP TABLE IF EXISTS business_product_bom;

CREATE TABLE IF NOT EXISTS `business_product_bom` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `bom_code` varchar(30) NOT NULL DEFAULT '' COMMENT 'BOM编号 BOM+YYYYMMDD+XXXX',
  `bom_name` varchar(100) NOT NULL DEFAULT '' COMMENT 'BOM名称',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '父件产品ID',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '父件产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '父件产品名称（冗余）',
  `version` varchar(20) NOT NULL DEFAULT 'V1.0' COMMENT '版本号',
  `quantity` decimal(12,4) NOT NULL DEFAULT 1.0000 COMMENT '父件数量',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '父件单位',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认BOM：1是0否',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `approval_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审批状态：0草稿1待审批2已审批3已驳回',
  `effective_date` date DEFAULT NULL COMMENT '生效日期',
  `expiry_date` date DEFAULT NULL COMMENT '失效日期',
  `remark` text COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_bom_code` (`bom_code`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品BOM主表';

CREATE TABLE IF NOT EXISTS `business_product_bom_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `bom_id` int(11) NOT NULL DEFAULT 0 COMMENT '所属BOM ID',
  `parent_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '父级子项ID（0=顶级）',
  `component_product_id` int(11) NOT NULL DEFAULT 0 COMMENT '子件产品ID',
  `component_code` varchar(30) NOT NULL DEFAULT '' COMMENT '子件编码（冗余）',
  `component_name` varchar(200) NOT NULL DEFAULT '' COMMENT '子件名称（冗余）',
  `component_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '子件规格（冗余）',
  `component_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '子件单位（冗余）',
  `quantity` decimal(12,4) NOT NULL DEFAULT 1.0000 COMMENT '用量',
  `wastage_rate` decimal(6,2) NOT NULL DEFAULT 0.00 COMMENT '损耗率%',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `source_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '来源类型：1自制2外购3外协',
  `is_key` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否关键件：1是0否',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bom_id` (`bom_id`),
  KEY `idx_parent` (`bom_id`, `parent_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品BOM子项表';

-- ========== 权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('BOM列表','business:product:bom:list',1,0,'business','/business/product/bom','el-icon-share',NULL,20,1,1,'BOM管理-列表/详情（菜单/查看）',NOW(),NOW()),
('BOM新增','business:product:bom:add',2,0,'business',NULL,NULL,NULL,21,1,1,'新增BOM',NOW(),NOW()),
('BOM编辑','business:product:bom:edit',2,0,'business',NULL,NULL,NULL,22,1,1,'编辑BOM',NOW(),NOW()),
('BOM删除','business:product:bom:delete',2,0,'business',NULL,NULL,NULL,23,1,1,'删除BOM',NOW(),NOW()),
('BOM导出','business:product:bom:export',2,0,'business',NULL,NULL,NULL,24,1,1,'导出BOM列表',NOW(),NOW()),
('BOM审批','business:product:bom:approve',2,0,'business',NULL,NULL,NULL,25,1,1,'提交审批BOM',NOW(),NOW()),
('BOM默认','business:product:bom:default',2,0,'business',NULL,NULL,NULL,26,1,1,'设为默认BOM',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:product:bom:list','business:product:bom:add','business:product:bom:edit','business:product:bom:delete','business:product:bom:export','business:product:bom:approve','business:product:bom:default');

-- ========== 菜单（经营管理 -> 产品管理 -> BOM管理） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);
SET @product_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='产品管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @product_menu_id, 'BOM管理', '/business/product/bom', 'el-icon-share', 'business:product:bom:list', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:product:bom:list' AND deleted_at IS NULL AND type=2);
