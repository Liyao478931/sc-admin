-- =====================================================
-- 092_create_business_customer.sql
-- 经营管理 → 客户管理
--   1. 建表：business_customer_category（客户分类）/ business_customers（客户）
--   2. 数据字典：客户类型/所属行业/所属区域/客户等级
--   3. 系统参数：客户编码前缀/单次导入最大条数
--   4. 权限定义与 super_admin 授权
--   5. 菜单（经营管理 → 客户管理 → 客户列表/新增客户/客户分类）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `business_customer_category` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户分类表';

CREATE TABLE IF NOT EXISTS `business_customers` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `customer_code` varchar(30) NOT NULL DEFAULT '' COMMENT '客户编码 C-YYYYMMDD-XXXX',
  `customer_name` varchar(200) NOT NULL DEFAULT '' COMMENT '客户名称',
  `customer_short_name` varchar(50) DEFAULT NULL COMMENT '客户简称',
  `category_id` int(11) DEFAULT NULL COMMENT '客户分类ID',
  `customer_type` varchar(30) NOT NULL DEFAULT 'other' COMMENT '客户类型：state_owned/private/individual/foreign/other',
  `industry` varchar(30) DEFAULT NULL COMMENT '所属行业：coal/electric/chemical/mechanical/other',
  `region` varchar(20) DEFAULT NULL COMMENT '所属区域：north/east/south/central/southwest/northwest/northeast/other',
  `customer_level` varchar(10) NOT NULL DEFAULT 'C' COMMENT '客户等级：A/B/C/D',
  `credit_limit` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '信用额度',
  `contact_person` varchar(50) DEFAULT NULL COMMENT '联系人姓名',
  `contact_phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `contact_email` varchar(100) DEFAULT NULL COMMENT '联系邮箱',
  `address` varchar(255) DEFAULT NULL COMMENT '地址',
  `tax_number` varchar(50) DEFAULT NULL COMMENT '税号',
  `bank_name` varchar(100) DEFAULT NULL COMMENT '开户银行',
  `bank_account` varchar(50) DEFAULT NULL COMMENT '银行账号',
  `remark` text COMMENT '备注',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_customer_code` (`customer_code`),
  KEY `idx_customer_name` (`customer_name`),
  KEY `idx_customer_type` (`customer_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户表';

-- ========== 二、数据字典 ==========
-- 1. customer_type 客户类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('客户类型','customer_type','客户管理-客户类型',100,1,NOW(),NOW());
SET @dt_customer_type = (SELECT `id` FROM `dictionary_types` WHERE `code`='customer_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_customer_type,'国有企业','state_owned',1,'',1,NOW(),NOW()),
(@dt_customer_type,'民营企业','private',2,'',1,NOW(),NOW()),
(@dt_customer_type,'个体户','individual',3,'',1,NOW(),NOW()),
(@dt_customer_type,'外资企业','foreign',4,'',1,NOW(),NOW()),
(@dt_customer_type,'其他','other',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. customer_industry 所属行业
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('所属行业','customer_industry','客户管理-所属行业',101,1,NOW(),NOW());
SET @dt_customer_industry = (SELECT `id` FROM `dictionary_types` WHERE `code`='customer_industry' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_customer_industry,'煤炭','coal',1,'',1,NOW(),NOW()),
(@dt_customer_industry,'电力','electric',2,'',1,NOW(),NOW()),
(@dt_customer_industry,'化工','chemical',3,'',1,NOW(),NOW()),
(@dt_customer_industry,'机械','mechanical',4,'',1,NOW(),NOW()),
(@dt_customer_industry,'其他','other',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. customer_region 所属区域
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('所属区域','customer_region','客户管理-所属区域',102,1,NOW(),NOW());
SET @dt_customer_region = (SELECT `id` FROM `dictionary_types` WHERE `code`='customer_region' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_customer_region,'华北','north',1,'',1,NOW(),NOW()),
(@dt_customer_region,'华东','east',2,'',1,NOW(),NOW()),
(@dt_customer_region,'华南','south',3,'',1,NOW(),NOW()),
(@dt_customer_region,'华中','central',4,'',1,NOW(),NOW()),
(@dt_customer_region,'西南','southwest',5,'',1,NOW(),NOW()),
(@dt_customer_region,'西北','northwest',6,'',1,NOW(),NOW()),
(@dt_customer_region,'东北','northeast',7,'',1,NOW(),NOW()),
(@dt_customer_region,'其他','other',8,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 4. customer_level 客户等级
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('客户等级','customer_level','客户管理-客户等级',103,1,NOW(),NOW());
SET @dt_customer_level = (SELECT `id` FROM `dictionary_types` WHERE `code`='customer_level' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_customer_level,'A级','A',1,'gold',1,NOW(),NOW()),
(@dt_customer_level,'B级','B',2,'primary',1,NOW(),NOW()),
(@dt_customer_level,'C级','C',3,'success',1,NOW(),NOW()),
(@dt_customer_level,'D级','D',4,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('customer_code_prefix','客户编码前缀','C','string','business','客户编码前缀（格式：{前缀}-YYYYMMDD-XXXX）',1,1,0,NOW(),NOW()),
('customer_import_max_rows','单次导入最大条数','1000','number','business','客户Excel批量导入单次最大条数',2,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('客户列表','business:customer:list',1,0,'business','/business/customer','el-icon-user',NULL,1,1,1,'客户管理-客户列表（菜单/查看）',NOW(),NOW()),
('客户新增','business:customer:add',2,0,'business',NULL,NULL,NULL,2,1,1,'新增客户/导入客户',NOW(),NOW()),
('客户编辑','business:customer:edit',2,0,'business',NULL,NULL,NULL,3,1,1,'编辑客户/切换状态/客户合并',NOW(),NOW()),
('客户删除','business:customer:delete',2,0,'business',NULL,NULL,NULL,4,1,1,'删除客户',NOW(),NOW()),
('客户导出','business:customer:export',2,0,'business',NULL,NULL,NULL,5,1,1,'导出客户列表',NOW(),NOW()),
('客户分类查看','business:customer:category',1,0,'business','/business/customer/category','el-icon-s-operation',NULL,6,1,1,'客户分类（菜单/查看）',NOW(),NOW()),
('客户分类新增','business:customer:category:add',2,0,'business',NULL,NULL,NULL,7,1,1,'新增客户分类',NOW(),NOW()),
('客户分类编辑','business:customer:category:edit',2,0,'business',NULL,NULL,NULL,8,1,1,'编辑/切换客户分类状态',NOW(),NOW()),
('客户分类删除','business:customer:category:delete',2,0,'business',NULL,NULL,NULL,9,1,1,'删除客户分类',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:customer:list','business:customer:add','business:customer:edit','business:customer:delete','business:customer:export','business:customer:category','business:customer:category:add','business:customer:category:edit','business:customer:category:delete');

-- ========== 五、菜单（经营管理 → 客户管理） ==========
-- 顶级菜单：经营管理
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '经营管理', '', 'el-icon-s-shop', 'business:view', 90, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0);

SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

-- 客户管理目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '客户管理', '', 'el-icon-user', 'business:customer:list', 10, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='客户管理' AND deleted_at IS NULL AND parent_id=@business_id AND type=1);

SET @customer_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='客户管理' AND deleted_at IS NULL LIMIT 1);

-- 客户列表
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @customer_menu_id, '客户列表', '/business/customer', 'el-icon-user', 'business:customer:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:customer:list' AND deleted_at IS NULL AND type=2);

-- 新增客户
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @customer_menu_id, '新增客户', '/business/customer/create', 'el-icon-plus', 'business:customer:add', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:customer:add' AND deleted_at IS NULL AND type=2);

-- 客户分类
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @customer_menu_id, '客户分类', '/business/customer/category', 'el-icon-s-operation', 'business:customer:category', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:customer:category' AND deleted_at IS NULL AND type=2);
