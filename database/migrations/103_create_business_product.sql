-- =====================================================
-- 103_create_business_product.sql
-- 经营管理 → 产品管理
--   1. 建表：business_product_category（产品分类-树形）/ business_products（产品）
--   2. 系统参数：产品编码前缀
--   3. 权限定义与 super_admin 授权
--   4. 菜单（经营管理 → 产品管理 → 产品列表/新增产品/产品分类）
-- 幂等写法，可重复执行
--
-- 回滚（down）：
--   DELETE FROM menus WHERE permission IN ('business:product:list','business:product:add','business:product:category');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:product:%');
--   DELETE FROM permissions WHERE code LIKE 'business:product:%';
--   DELETE FROM system_params WHERE param_key='product_code_prefix';
--   DROP TABLE IF EXISTS business_products;
--   DROP TABLE IF EXISTS business_product_category;
-- =====================================================

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `business_product_category` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL DEFAULT 0 COMMENT '父级分类ID（0=顶级）',
  `category_code` varchar(30) NOT NULL DEFAULT '' COMMENT '分类编码',
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '分类名称',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序（小在前）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_code` (`category_code`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品分类表（树形）';

CREATE TABLE IF NOT EXISTS `business_products` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码 P-YYYYMMDD-XXXX',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称',
  `category_id` int(11) DEFAULT NULL COMMENT '产品分类ID',
  `specification` varchar(100) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `remark` text COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_product_code` (`product_code`),
  KEY `idx_product_name` (`product_name`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品表';

-- ========== 二、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('product_code_prefix','产品编码前缀','P','string','business','产品编码前缀（格式：{前缀}-YYYYMMDD-XXXX）',3,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 三、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品列表','business:product:list',1,0,'business','/business/product/list','el-icon-goods',NULL,10,1,1,'产品管理-产品列表（菜单/查看）',NOW(),NOW()),
('产品新增','business:product:add',2,0,'business',NULL,NULL,NULL,11,1,1,'新增产品',NOW(),NOW()),
('产品编辑','business:product:edit',2,0,'business',NULL,NULL,NULL,12,1,1,'编辑产品',NOW(),NOW()),
('产品删除','business:product:delete',2,0,'business',NULL,NULL,NULL,13,1,1,'删除产品',NOW(),NOW()),
('产品导出','business:product:export',2,0,'business',NULL,NULL,NULL,14,1,1,'导出产品列表',NOW(),NOW()),
('产品分类查看','business:product:category',1,0,'business','/business/product/category','el-icon-s-operation',NULL,15,1,1,'产品分类（菜单/查看）',NOW(),NOW()),
('产品分类新增','business:product:category:add',2,0,'business',NULL,NULL,NULL,16,1,1,'新增产品分类',NOW(),NOW()),
('产品分类编辑','business:product:category:edit',2,0,'business',NULL,NULL,NULL,17,1,1,'编辑/切换产品分类状态',NOW(),NOW()),
('产品分类删除','business:product:category:delete',2,0,'business',NULL,NULL,NULL,18,1,1,'删除产品分类',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:product:list','business:product:add','business:product:edit','business:product:delete','business:product:export','business:product:category','business:product:category:add','business:product:category:edit','business:product:category:delete');

-- ========== 四、菜单（经营管理 → 产品管理） ==========
-- 顶级菜单：经营管理（若已存在则复用）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '经营管理', '', 'el-icon-s-shop', 'business:view', 90, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0);

SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

-- 产品管理目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '产品管理', '', 'el-icon-goods', 'business:product:list', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='产品管理' AND deleted_at IS NULL AND parent_id=@business_id AND type=1);

SET @product_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='产品管理' AND deleted_at IS NULL LIMIT 1);

-- 产品列表
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @product_menu_id, '产品列表', '/business/product/list', 'el-icon-goods', 'business:product:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:product:list' AND deleted_at IS NULL AND type=2);

-- 新增产品
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @product_menu_id, '新增产品', '/business/product/add', 'el-icon-plus', 'business:product:add', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:product:add' AND deleted_at IS NULL AND type=2);

-- 产品分类
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @product_menu_id, '产品分类', '/business/product/category', 'el-icon-s-operation', 'business:product:category', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:product:category' AND deleted_at IS NULL AND type=2);
