-- 108_create_business_product_drawing.sql
-- 经营管理 -> 产品管理 -> 图纸管理
-- 1. 建表：business_product_drawing（图纸主表）/ business_product_drawing_version（版本历史）/ business_product_drawing_category（分类树）
-- 2. 权限：business:product:drawing:list/add/edit/delete/export/download + category:list/add/edit/delete（10个）并授权 super_admin
-- 3. 菜单：经营管理 -> 产品管理 -> 图纸管理（图纸列表/分类管理）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission LIKE 'business:product:drawing:%';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:product:drawing:%');
--   DELETE FROM permissions WHERE code LIKE 'business:product:drawing:%';
--   DROP TABLE IF EXISTS business_product_drawing_version;
--   DROP TABLE IF EXISTS business_product_drawing;
--   DROP TABLE IF EXISTS business_product_drawing_category;

CREATE TABLE IF NOT EXISTS `business_product_drawing_category` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL DEFAULT 0 COMMENT '父级分类ID（0=顶级）',
  `category_code` varchar(30) NOT NULL DEFAULT '' COMMENT '分类编码',
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '分类名称',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序（小在前）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_code` (`category_code`),
  KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品图纸分类表（树形）';

CREATE TABLE IF NOT EXISTS `business_product_drawing` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `drawing_code` varchar(30) NOT NULL DEFAULT '' COMMENT '图纸编号 DWG+YYYYMMDD+XXXX',
  `drawing_name` varchar(150) NOT NULL DEFAULT '' COMMENT '图纸名称',
  `drawing_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '图纸类型：1CAD 2PDF 3图片 4三维 5其他',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联产品ID',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `category_id` int(11) DEFAULT NULL COMMENT '图纸分类ID',
  `file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '原始文件名',
  `file_path` varchar(255) NOT NULL DEFAULT '' COMMENT '文件存储路径',
  `file_size` bigint(20) NOT NULL DEFAULT 0 COMMENT '文件大小（字节）',
  `file_ext` varchar(10) NOT NULL DEFAULT '' COMMENT '文件扩展名',
  `version` varchar(20) NOT NULL DEFAULT 'V1.0' COMMENT '版本号',
  `is_newest` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否最新版本：1是0否',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用0停用',
  `uploader_id` int(11) NOT NULL DEFAULT 0 COMMENT '上传人ID',
  `uploader_name` varchar(50) NOT NULL DEFAULT '' COMMENT '上传人姓名（冗余）',
  `uploaded_at` datetime DEFAULT NULL COMMENT '上传时间',
  `remark` text COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drawing_code` (`drawing_code`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品图纸主表';

CREATE TABLE IF NOT EXISTS `business_product_drawing_version` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `drawing_id` int(11) NOT NULL DEFAULT 0 COMMENT '图纸ID',
  `version` varchar(20) NOT NULL DEFAULT '' COMMENT '版本号',
  `file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '原始文件名',
  `file_path` varchar(255) NOT NULL DEFAULT '' COMMENT '文件存储路径',
  `file_size` bigint(20) NOT NULL DEFAULT 0 COMMENT '文件大小（字节）',
  `uploader_id` int(11) NOT NULL DEFAULT 0 COMMENT '上传人ID',
  `uploader_name` varchar(50) NOT NULL DEFAULT '' COMMENT '上传人姓名（冗余）',
  `uploaded_at` datetime DEFAULT NULL COMMENT '上传时间',
  `change_description` varchar(500) DEFAULT NULL COMMENT '变更说明',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_drawing_id` (`drawing_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品图纸版本历史表';

-- ========== 权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('图纸列表','business:product:drawing:list',1,0,'business','/business/product/drawing/list','el-icon-document',NULL,30,1,1,'图纸管理-列表/详情/预览（菜单/查看）',NOW(),NOW()),
('图纸上传','business:product:drawing:add',2,0,'business',NULL,NULL,NULL,31,1,1,'上传图纸/新增分类子项',NOW(),NOW()),
('图纸编辑','business:product:drawing:edit',2,0,'business',NULL,NULL,NULL,32,1,1,'编辑图纸',NOW(),NOW()),
('图纸删除','business:product:drawing:delete',2,0,'business',NULL,NULL,NULL,33,1,1,'删除图纸',NOW(),NOW()),
('图纸导出','business:product:drawing:export',2,0,'business',NULL,NULL,NULL,34,1,1,'导出图纸列表',NOW(),NOW()),
('图纸下载','business:product:drawing:download',2,0,'business',NULL,NULL,NULL,35,1,1,'下载图纸文件',NOW(),NOW()),
('图纸分类查看','business:product:drawing:category:list',1,0,'business','/business/product/drawing/category','el-icon-s-operation',NULL,36,1,1,'图纸分类（菜单/查看）',NOW(),NOW()),
('图纸分类新增','business:product:drawing:category:add',2,0,'business',NULL,NULL,NULL,37,1,1,'新增图纸分类',NOW(),NOW()),
('图纸分类编辑','business:product:drawing:category:edit',2,0,'business',NULL,NULL,NULL,38,1,1,'编辑图纸分类',NOW(),NOW()),
('图纸分类删除','business:product:drawing:category:delete',2,0,'business',NULL,NULL,NULL,39,1,1,'删除图纸分类',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:product:drawing:list','business:product:drawing:add','business:product:drawing:edit','business:product:drawing:delete','business:product:drawing:export','business:product:drawing:download','business:product:drawing:category:list','business:product:drawing:category:add','business:product:drawing:category:edit','business:product:drawing:category:delete');

-- ========== 菜单（经营管理 -> 产品管理 -> 图纸管理） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);
SET @product_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='产品管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @product_menu_id, '图纸管理', '/business/product/drawing/list', 'el-icon-document', 'business:product:drawing:list', 50, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:product:drawing:list' AND deleted_at IS NULL AND type=2);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @product_menu_id, '图纸分类', '/business/product/drawing/category', 'el-icon-s-operation', 'business:product:drawing:category:list', 60, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:product:drawing:category:list' AND deleted_at IS NULL AND type=2);
