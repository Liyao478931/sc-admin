-- =====================================================
-- 094_create_business_supplier.sql
-- 经营管理 → 供应商管理
--   1. 建表：business_supplier_category（供应商分类）/ business_suppliers（供应商）
--   2. 数据字典：供应商类型/供应品类/所属区域/供应商评级
--   3. 系统参数：供应商编码前缀/单次导入最大条数
--   4. 权限定义与 super_admin 授权
--   5. 菜单（经营管理 → 供应商管理 → 供应商列表/新增供应商/供应商分类）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `business_supplier_category` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `category_code` varchar(30) NOT NULL DEFAULT '' COMMENT '分类编码',
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '分类名称',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_code` (`category_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='供应商分类表';

CREATE TABLE IF NOT EXISTS `business_suppliers` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `supplier_code` varchar(30) NOT NULL DEFAULT '' COMMENT '供应商编码 S-YYYYMMDD-XXXX',
  `supplier_name` varchar(200) NOT NULL DEFAULT '' COMMENT '供应商名称',
  `supplier_short_name` varchar(50) DEFAULT NULL COMMENT '供应商简称',
  `category_id` int(11) DEFAULT NULL COMMENT '供应商分类ID',
  `supplier_type` varchar(30) NOT NULL DEFAULT 'other' COMMENT '供应商类型：manufacturer/trader/outsource/service/other',
  `supply_category` varchar(30) DEFAULT NULL COMMENT '供应品类：parts/raw_material/outsource/equipment/other',
  `region` varchar(20) DEFAULT NULL COMMENT '所属区域：north/east/south/central/southwest/northwest/northeast/other',
  `supplier_level` varchar(10) NOT NULL DEFAULT 'C' COMMENT '供应商评级：A/B/C/D',
  `contact_person` varchar(50) DEFAULT NULL COMMENT '联系人姓名',
  `contact_phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `contact_email` varchar(100) DEFAULT NULL COMMENT '联系邮箱',
  `address` varchar(255) DEFAULT NULL COMMENT '地址',
  `tax_number` varchar(50) DEFAULT NULL COMMENT '税号',
  `bank_name` varchar(100) DEFAULT NULL COMMENT '开户银行',
  `bank_account` varchar(50) DEFAULT NULL COMMENT '银行账号',
  `qualifications` json DEFAULT NULL COMMENT '资质证照（名称/编号/有效期）',
  `cooperation_start` date DEFAULT NULL COMMENT '合作开始日期',
  `remark` text COMMENT '备注',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_supplier_code` (`supplier_code`),
  KEY `idx_supplier_name` (`supplier_name`),
  KEY `idx_supplier_type` (`supplier_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='供应商表';

-- ========== 二、数据字典 ==========
-- 1. supplier_type 供应商类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('供应商类型','supplier_type','供应商管理-供应商类型',110,1,NOW(),NOW());
SET @dt_supplier_type = (SELECT `id` FROM `dictionary_types` WHERE `code`='supplier_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_supplier_type,'生产厂家','manufacturer',1,'',1,NOW(),NOW()),
(@dt_supplier_type,'贸易商','trader',2,'',1,NOW(),NOW()),
(@dt_supplier_type,'外协加工','outsource',3,'',1,NOW(),NOW()),
(@dt_supplier_type,'服务商','service',4,'',1,NOW(),NOW()),
(@dt_supplier_type,'其他','other',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. supplier_supply_category 供应品类
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('供应品类','supplier_supply_category','供应商管理-供应品类',111,1,NOW(),NOW());
SET @dt_supply_category = (SELECT `id` FROM `dictionary_types` WHERE `code`='supplier_supply_category' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_supply_category,'配件','parts',1,'',1,NOW(),NOW()),
(@dt_supply_category,'原材料','raw_material',2,'',1,NOW(),NOW()),
(@dt_supply_category,'外协加工','outsource',3,'',1,NOW(),NOW()),
(@dt_supply_category,'设备','equipment',4,'',1,NOW(),NOW()),
(@dt_supply_category,'其他','other',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. supplier_region 所属区域
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('所属区域','supplier_region','供应商管理-所属区域',112,1,NOW(),NOW());
SET @dt_supplier_region = (SELECT `id` FROM `dictionary_types` WHERE `code`='supplier_region' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_supplier_region,'华北','north',1,'',1,NOW(),NOW()),
(@dt_supplier_region,'华东','east',2,'',1,NOW(),NOW()),
(@dt_supplier_region,'华南','south',3,'',1,NOW(),NOW()),
(@dt_supplier_region,'华中','central',4,'',1,NOW(),NOW()),
(@dt_supplier_region,'西南','southwest',5,'',1,NOW(),NOW()),
(@dt_supplier_region,'西北','northwest',6,'',1,NOW(),NOW()),
(@dt_supplier_region,'东北','northeast',7,'',1,NOW(),NOW()),
(@dt_supplier_region,'其他','other',8,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 4. supplier_level 供应商评级
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('供应商评级','supplier_level','供应商管理-供应商评级',113,1,NOW(),NOW());
SET @dt_supplier_level = (SELECT `id` FROM `dictionary_types` WHERE `code`='supplier_level' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_supplier_level,'A级','A',1,'gold',1,NOW(),NOW()),
(@dt_supplier_level,'B级','B',2,'primary',1,NOW(),NOW()),
(@dt_supplier_level,'C级','C',3,'success',1,NOW(),NOW()),
(@dt_supplier_level,'D级','D',4,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('supplier_code_prefix','供应商编码前缀','S','string','business','供应商编码前缀（格式：{前缀}-YYYYMMDD-XXXX）',3,1,0,NOW(),NOW()),
('supplier_import_max_rows','单次导入最大条数','1000','number','business','供应商Excel批量导入单次最大条数',4,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('供应商列表','business:supplier:list',1,0,'business','/business/supplier','el-icon-truck',NULL,11,1,1,'供应商管理-供应商列表（菜单/查看）',NOW(),NOW()),
('供应商新增','business:supplier:add',2,0,'business',NULL,NULL,NULL,12,1,1,'新增供应商/导入供应商',NOW(),NOW()),
('供应商编辑','business:supplier:edit',2,0,'business',NULL,NULL,NULL,13,1,1,'编辑供应商/切换状态/调整评级',NOW(),NOW()),
('供应商删除','business:supplier:delete',2,0,'business',NULL,NULL,NULL,14,1,1,'删除供应商',NOW(),NOW()),
('供应商导出','business:supplier:export',2,0,'business',NULL,NULL,NULL,15,1,1,'导出供应商列表',NOW(),NOW()),
('供应商分类查看','business:supplier:category',1,0,'business','/business/supplier/category','el-icon-s-operation',NULL,16,1,1,'供应商分类（菜单/查看）',NOW(),NOW()),
('供应商分类新增','business:supplier:category:add',2,0,'business',NULL,NULL,NULL,17,1,1,'新增供应商分类',NOW(),NOW()),
('供应商分类编辑','business:supplier:category:edit',2,0,'business',NULL,NULL,NULL,18,1,1,'编辑/切换供应商分类状态',NOW(),NOW()),
('供应商分类删除','business:supplier:category:delete',2,0,'business',NULL,NULL,NULL,19,1,1,'删除供应商分类',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:supplier:list','business:supplier:add','business:supplier:edit','business:supplier:delete','business:supplier:export','business:supplier:category','business:supplier:category:add','business:supplier:category:edit','business:supplier:category:delete');

-- ========== 五、菜单（经营管理 → 供应商管理） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

-- 供应商管理目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '供应商管理', '', 'el-icon-truck', 'business:supplier:list', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='供应商管理' AND deleted_at IS NULL AND parent_id=@business_id AND type=1);

SET @supplier_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='供应商管理' AND deleted_at IS NULL LIMIT 1);

-- 供应商列表
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @supplier_menu_id, '供应商列表', '/business/supplier', 'el-icon-truck', 'business:supplier:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:supplier:list' AND deleted_at IS NULL AND type=2);

-- 新增供应商
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @supplier_menu_id, '新增供应商', '/business/supplier/create', 'el-icon-plus', 'business:supplier:add', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:supplier:add' AND deleted_at IS NULL AND type=2);

-- 供应商分类
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @supplier_menu_id, '供应商分类', '/business/supplier/category', 'el-icon-s-operation', 'business:supplier:category', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:supplier:category' AND deleted_at IS NULL AND type=2);
