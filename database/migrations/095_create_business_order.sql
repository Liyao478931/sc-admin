-- =====================================================
-- 095_create_business_order.sql
-- 经营管理 → 订单中心 → 订单管理
--   1. 建表 5 张：business_orders / business_sales_order_items / business_repair_order_items / business_order_logs / business_order_reviews
--   2. 数据字典：订单类别/订单状态/业务类型
--   3. 系统参数：订单编号前缀
--   4. 权限定义与 super_admin 授权
--   5. 菜单（经营管理 → 订单中心 → 订单列表/新增订单/订单评审）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `business_orders` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号 SO-YYYYMMDD-XXXX',
  `order_category` varchar(20) NOT NULL DEFAULT '' COMMENT '订单类别：sales/repair',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(200) NOT NULL DEFAULT '' COMMENT '客户名称（冗余）',
  `contact_person` varchar(50) DEFAULT NULL COMMENT '联系人',
  `contact_phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `order_date` date NOT NULL COMMENT '订单日期',
  `delivery_date` date DEFAULT NULL COMMENT '交付日期',
  `order_amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '订单金额',
  `order_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '订单状态：pending/reviewed/production/shipping/completed/cancelled',
  `business_type` varchar(30) NOT NULL DEFAULT 'other' COMMENT '业务类型：repair/parts_sales/product_sales/other',
  `remark` text COMMENT '备注',
  `salesperson_id` int(11) DEFAULT NULL COMMENT '业务员ID',
  `salesperson_name` varchar(50) DEFAULT NULL COMMENT '业务员姓名（冗余）',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_category_status` (`order_category`, `order_status`),
  KEY `idx_status_create` (`order_status`, `create_time`),
  KEY `idx_order_date` (`order_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单主表';

CREATE TABLE IF NOT EXISTS `business_sales_order_items` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称',
  `product_model` varchar(100) DEFAULT NULL COMMENT '产品型号',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT '数量',
  `unit_price` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '单价',
  `amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '金额（数量×单价）',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='销售订单明细表';

CREATE TABLE IF NOT EXISTS `business_repair_order_items` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `device_name` varchar(200) NOT NULL DEFAULT '' COMMENT '设备名称',
  `device_model` varchar(100) DEFAULT NULL COMMENT '设备型号',
  `device_serial` varchar(50) DEFAULT NULL COMMENT '设备编号',
  `fault_description` text COMMENT '故障描述',
  `repair_hours` decimal(8,2) NOT NULL DEFAULT 0 COMMENT '预估工时',
  `labor_rate` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工时单价',
  `labor_amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工时费（工时×单价）',
  `parts_amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '配件费',
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '小计（工时费+配件费）',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='维修订单明细表';

CREATE TABLE IF NOT EXISTS `business_order_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名（冗余）',
  `action` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型：create/edit/submit/review_pass/review_reject/status_change/delete',
  `from_status` varchar(20) DEFAULT NULL COMMENT '变更前状态',
  `to_status` varchar(20) DEFAULT NULL COMMENT '变更后状态',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单状态变更日志表';

CREATE TABLE IF NOT EXISTS `business_order_reviews` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `reviewer_id` int(11) NOT NULL DEFAULT 0 COMMENT '评审人ID',
  `reviewer_name` varchar(50) NOT NULL DEFAULT '' COMMENT '评审人姓名（冗余）',
  `review_result` varchar(20) NOT NULL DEFAULT '' COMMENT '评审结果：pass/reject',
  `review_comment` varchar(500) DEFAULT NULL COMMENT '评审意见',
  `review_time` datetime DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单评审记录表';

-- ========== 二、数据字典 ==========
-- 1. order_category 订单类别
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('订单类别','order_category','订单管理-订单类别',120,1,NOW(),NOW());
SET @dt_order_category = (SELECT `id` FROM `dictionary_types` WHERE `code`='order_category' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_order_category,'销售订单','sales',1,'primary',1,NOW(),NOW()),
(@dt_order_category,'维修订单','repair',2,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. order_status 订单状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('订单状态','order_status','订单管理-订单状态',121,1,NOW(),NOW());
SET @dt_order_status = (SELECT `id` FROM `dictionary_types` WHERE `code`='order_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_order_status,'待评审','pending',1,'warning',1,NOW(),NOW()),
(@dt_order_status,'已评审','reviewed',2,'primary',1,NOW(),NOW()),
(@dt_order_status,'生产中','production',3,'danger',1,NOW(),NOW()),
(@dt_order_status,'待发货','shipping',4,'success',1,NOW(),NOW()),
(@dt_order_status,'已完成','completed',5,'info',1,NOW(),NOW()),
(@dt_order_status,'已取消','cancelled',6,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. order_business_type 业务类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('业务类型','order_business_type','订单管理-业务类型',122,1,NOW(),NOW());
SET @dt_order_biz = (SELECT `id` FROM `dictionary_types` WHERE `code`='order_business_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_order_biz,'维修服务','repair',1,'',1,NOW(),NOW()),
(@dt_order_biz,'配件销售','parts_sales',2,'',1,NOW(),NOW()),
(@dt_order_biz,'产品销售','product_sales',3,'',1,NOW(),NOW()),
(@dt_order_biz,'其他','other',4,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('order_no_prefix','订单编号前缀','SO','string','business','订单编号前缀（格式：{前缀}-YYYYMMDD-XXXX）',5,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('订单列表','business:order:list',1,0,'business','/business/order','el-icon-document',NULL,21,1,1,'订单管理-订单列表（菜单/查看）',NOW(),NOW()),
('订单新增','business:order:add',2,0,'business',NULL,NULL,NULL,22,1,1,'新增订单/复制订单',NOW(),NOW()),
('订单编辑','business:order:edit',2,0,'business',NULL,NULL,NULL,23,1,1,'编辑订单/提交评审/变更状态',NOW(),NOW()),
('订单删除','business:order:delete',2,0,'business',NULL,NULL,NULL,24,1,1,'删除订单',NOW(),NOW()),
('订单评审','business:order:review',1,0,'business','/business/order/review','el-icon-check',NULL,25,1,1,'订单评审（菜单/评审操作）',NOW(),NOW()),
('订单导出','business:order:export',2,0,'business',NULL,NULL,NULL,26,1,1,'导出订单列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:order:list','business:order:add','business:order:edit','business:order:delete','business:order:review','business:order:export');

-- ========== 五、菜单（经营管理 → 订单中心） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

-- 订单中心目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '订单中心', '', 'el-icon-document', 'business:order:list', 30, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='订单中心' AND deleted_at IS NULL AND parent_id=@business_id AND type=1);

SET @order_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='订单中心' AND deleted_at IS NULL LIMIT 1);

-- 订单列表
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @order_menu_id, '订单列表', '/business/order', 'el-icon-document', 'business:order:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:order:list' AND deleted_at IS NULL AND type=2);

-- 新增订单
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @order_menu_id, '新增订单', '/business/order/add', 'el-icon-plus', 'business:order:add', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:order:add' AND deleted_at IS NULL AND type=2);

-- 订单评审
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @order_menu_id, '订单评审', '/business/order/review', 'el-icon-check', 'business:order:review', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:order:review' AND deleted_at IS NULL AND type=2);
