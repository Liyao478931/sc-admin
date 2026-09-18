-- =====================================================
-- 096_create_business_quotation.sql
-- 经营管理 → 订单中心 → 报价管理
--   1. 建表 3 张：business_quotations / business_quotation_items / business_quotation_reviews
--   2. 数据字典：报价类别/报价状态/明细类型
--   3. 系统参数：报价单编号前缀/默认有效期天数
--   4. 权限定义与 super_admin 授权
--   5. 菜单（经营管理 → 订单中心 → 报价管理 → 报价单列表/新增报价单/报价单审核）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `business_quotations` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `quotation_no` varchar(50) NOT NULL DEFAULT '' COMMENT '报价单编号 QT-YYYYMMDD-XXXX',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(200) NOT NULL DEFAULT '' COMMENT '客户名称（冗余）',
  `quotation_category` varchar(20) NOT NULL DEFAULT '' COMMENT '报价类别：repair/sales',
  `quotation_amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '报价金额',
  `quotation_status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '报价状态：draft/pending/approved/rejected/converted',
  `validity_days` int(11) NOT NULL DEFAULT 30 COMMENT '有效期（天）',
  `validity_date` date DEFAULT NULL COMMENT '有效期截止日期',
  `quotation_date` date NOT NULL COMMENT '报价日期',
  `delivery_date` date DEFAULT NULL COMMENT '预计交付日期',
  `remark` text COMMENT '备注',
  `salesperson_id` int(11) DEFAULT NULL COMMENT '业务员ID',
  `salesperson_name` varchar(50) DEFAULT NULL COMMENT '业务员姓名（冗余）',
  `converted_order_id` int(11) DEFAULT NULL COMMENT '转订单后的订单ID',
  `converted_order_no` varchar(50) DEFAULT NULL COMMENT '转订单后的订单编号',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_quotation_no` (`quotation_no`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_category_status` (`quotation_category`, `quotation_status`),
  KEY `idx_status_create` (`quotation_status`, `create_time`),
  KEY `idx_quotation_date` (`quotation_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报价单主表';

CREATE TABLE IF NOT EXISTS `business_quotation_items` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `quotation_id` int(11) NOT NULL DEFAULT 0 COMMENT '报价单ID',
  `item_type` varchar(20) NOT NULL DEFAULT 'product' COMMENT '明细类型：product/service/repair/part',
  `item_name` varchar(200) NOT NULL DEFAULT '' COMMENT '项目名称',
  `item_spec` varchar(100) DEFAULT NULL COMMENT '规格型号',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT '数量',
  `unit_price` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '单价',
  `amount` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '金额（数量×单价）',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quotation_id` (`quotation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报价单明细表';

CREATE TABLE IF NOT EXISTS `business_quotation_reviews` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `quotation_id` int(11) NOT NULL DEFAULT 0 COMMENT '报价单ID',
  `reviewer_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `reviewer_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审核人姓名（冗余）',
  `review_result` varchar(20) NOT NULL DEFAULT '' COMMENT '审核结果：pass/reject',
  `review_comment` varchar(500) DEFAULT NULL COMMENT '审核意见',
  `review_time` datetime DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_quotation_id` (`quotation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报价单审核记录表';

-- ========== 二、数据字典 ==========
-- 1. quotation_category 报价类别
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('报价类别','quotation_category','报价管理-报价类别',130,1,NOW(),NOW());
SET @dt_qcat = (SELECT `id` FROM `dictionary_types` WHERE `code`='quotation_category' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_qcat,'维修报价','repair',1,'warning',1,NOW(),NOW()),
(@dt_qcat,'销售报价','sales',2,'primary',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. quotation_status 报价状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('报价状态','quotation_status','报价管理-报价状态',131,1,NOW(),NOW());
SET @dt_qstatus = (SELECT `id` FROM `dictionary_types` WHERE `code`='quotation_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_qstatus,'草稿','draft',1,'info',1,NOW(),NOW()),
(@dt_qstatus,'待审核','pending',2,'warning',1,NOW(),NOW()),
(@dt_qstatus,'已通过','approved',3,'success',1,NOW(),NOW()),
(@dt_qstatus,'已驳回','rejected',4,'danger',1,NOW(),NOW()),
(@dt_qstatus,'已转订单','converted',5,'primary',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. quotation_item_type 明细类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('明细类型','quotation_item_type','报价管理-明细类型',132,1,NOW(),NOW());
SET @dt_qitem = (SELECT `id` FROM `dictionary_types` WHERE `code`='quotation_item_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_qitem,'产品','product',1,'',1,NOW(),NOW()),
(@dt_qitem,'服务','service',2,'',1,NOW(),NOW()),
(@dt_qitem,'维修项目','repair',3,'',1,NOW(),NOW()),
(@dt_qitem,'配件','part',4,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('quotation_no_prefix','报价单编号前缀','QT','string','business','报价单编号前缀（格式：{前缀}-YYYYMMDD-XXXX）',6,1,0,NOW(),NOW()),
('quotation_default_validity_days','默认有效期天数','30','number','business','报价单默认有效期天数',7,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('报价单列表','business:quotation:list',1,0,'business','/business/quotation','el-icon-document-copy',NULL,27,1,1,'报价管理-报价单列表（菜单/查看）',NOW(),NOW()),
('报价单新增','business:quotation:add',2,0,'business',NULL,NULL,NULL,28,1,1,'新增报价单/复制报价单',NOW(),NOW()),
('报价单编辑','business:quotation:edit',2,0,'business',NULL,NULL,NULL,29,1,1,'编辑报价单/提交审核',NOW(),NOW()),
('报价单删除','business:quotation:delete',2,0,'business',NULL,NULL,NULL,30,1,1,'删除报价单',NOW(),NOW()),
('报价单审核','business:quotation:review',1,0,'business','/business/quotation/review','el-icon-check',NULL,31,1,1,'报价单审核（菜单/审核操作）',NOW(),NOW()),
('报价单转订单','business:quotation:convert',2,0,'business',NULL,NULL,NULL,32,1,1,'报价单转订单',NOW(),NOW()),
('报价单导出','business:quotation:export',2,0,'business',NULL,NULL,NULL,33,1,1,'导出报价单列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:quotation:list','business:quotation:add','business:quotation:edit','business:quotation:delete','business:quotation:review','business:quotation:convert','business:quotation:export');

-- ========== 五、菜单（经营管理 → 订单中心 → 报价管理） ==========
SET @order_menu_id = (SELECT id FROM menus WHERE name='订单中心' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0) LIMIT 1);

-- 报价管理目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @order_menu_id, '报价管理', '', 'el-icon-document-copy', 'business:quotation:list', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='报价管理' AND deleted_at IS NULL AND parent_id=@order_menu_id AND type=1);

SET @quotation_menu_id = (SELECT id FROM menus WHERE parent_id=@order_menu_id AND name='报价管理' AND deleted_at IS NULL LIMIT 1);

-- 报价单列表
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @quotation_menu_id, '报价单列表', '/business/quotation', 'el-icon-document-copy', 'business:quotation:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:quotation:list' AND deleted_at IS NULL AND type=2);

-- 新增报价单
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @quotation_menu_id, '新增报价单', '/business/quotation/add', 'el-icon-plus', 'business:quotation:add', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:quotation:add' AND deleted_at IS NULL AND type=2);

-- 报价单审核
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @quotation_menu_id, '报价单审核', '/business/quotation/review', 'el-icon-check', 'business:quotation:review', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:quotation:review' AND deleted_at IS NULL AND type=2);
