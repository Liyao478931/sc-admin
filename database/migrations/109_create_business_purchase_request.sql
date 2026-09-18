-- 109_create_business_purchase_request.sql
-- 经营管理 -> 采购管理 -> 采购申请
-- 1. 建表：business_purchase_request（主表）/ business_purchase_request_item（明细）/ business_purchase_request_tracking（执行跟踪）
-- 2. 权限：business:purchase:request:list/add/edit/delete/export/approve + order:add + contract:view（8个）并授权 super_admin
-- 3. 菜单：经营管理 -> 采购管理 -> 采购申请
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission LIKE 'business:purchase:%';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:purchase:%');
--   DELETE FROM permissions WHERE code LIKE 'business:purchase:%';
--   DROP TABLE IF EXISTS business_purchase_request_tracking;
--   DROP TABLE IF EXISTS business_purchase_request_item;
--   DROP TABLE IF EXISTS business_purchase_request;

CREATE TABLE IF NOT EXISTS `business_purchase_request` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_code` varchar(30) NOT NULL DEFAULT '' COMMENT '申请编号 PR+YYYYMMDD+XXXX',
  `title` varchar(200) NOT NULL DEFAULT '' COMMENT '申请标题',
  `request_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '申请类型：1日常 2项目 3紧急 4备品备件',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '申请部门名称（冗余）',
  `applicant_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请人ID',
  `applicant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '申请人姓名（冗余）',
  `request_date` date DEFAULT NULL COMMENT '申请日期',
  `expected_date` date DEFAULT NULL COMMENT '期望交付日期',
  `budget_subject` varchar(100) DEFAULT NULL COMMENT '预算科目',
  `budget_amount` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '预算金额（0=无限制）',
  `purpose` text COMMENT '用途说明',
  `urgency` tinyint(1) NOT NULL DEFAULT 1 COMMENT '紧急程度：1普通 2紧急 3特急',
  `approval_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审批状态：0草稿 1待审批 2已审批 3已驳回 4已撤销',
  `approver_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批人ID',
  `approver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审批人姓名（冗余）',
  `approval_date` datetime DEFAULT NULL COMMENT '审批日期',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `source_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '来源类型：1手动 2销售订单 3维修订单 4生产工单 5库存补货 6消耗品 7项目 8计划 9紧急',
  `source_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源单据ID',
  `source_no` varchar(50) NOT NULL DEFAULT '' COMMENT '来源单据编号（冗余）',
  `source_category` tinyint(1) NOT NULL DEFAULT 1 COMMENT '来源大类：1订单驱动 2库存补充 3消耗品 4项目 5计划 6紧急',
  `execution_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '执行状态：0待执行 1部分执行 2全部执行 3全部入库',
  `order_count` int(11) NOT NULL DEFAULT 0 COMMENT '已生成采购订单数量',
  `ordered_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已下单总数量',
  `received_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已入库总数量',
  `contract_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联采购合同ID',
  `contract_no` varchar(50) NOT NULL DEFAULT '' COMMENT '合同编号（冗余）',
  `contract_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '合同状态：0未签约 1已签约 2已生效',
  `demand_pool_id` int(11) NOT NULL DEFAULT 0 COMMENT '需求池ID',
  `remark` text COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_request_code` (`request_code`),
  KEY `idx_department` (`department_id`),
  KEY `idx_applicant` (`applicant_id`),
  KEY `idx_status` (`approval_status`),
  KEY `idx_source_type` (`source_type`),
  KEY `idx_source_id` (`source_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购申请主表';

CREATE TABLE IF NOT EXISTS `business_purchase_request_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请ID',
  `source_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源明细ID（精确追溯）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '规格型号（冗余）',
  `product_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT '申请数量',
  `approved_quantity` int(11) NOT NULL DEFAULT 0 COMMENT '审批数量',
  `unit_price` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '采购单价',
  `total_amount` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '总价（数量x单价）',
  `need_date` date DEFAULT NULL COMMENT '需求日期',
  `ordered_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已下单数量',
  `received_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已入库数量',
  `execution_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '执行状态：0待执行 1已生成订单 2部分入库 3全部入库 4已关闭',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_request_id` (`request_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购申请明细表';

CREATE TABLE IF NOT EXISTS `business_purchase_request_tracking` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `request_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请明细ID',
  `purchase_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '采购订单ID',
  `purchase_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '采购订单编号（冗余）',
  `contract_id` int(11) NOT NULL DEFAULT 0 COMMENT '采购合同ID',
  `contract_no` varchar(50) NOT NULL DEFAULT '' COMMENT '合同编号（冗余）',
  `ordered_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '订单数量',
  `received_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '入库数量',
  `execution_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '执行状态：0待执行 1已生成订单 2部分入库 3全部入库 4已关闭',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_request_item_id` (`request_item_id`),
  KEY `idx_purchase_order_id` (`purchase_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购申请执行跟踪表';

-- ========== 权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('采购申请列表','business:purchase:request:list',1,0,'business','/business/purchase/request/list','el-icon-shopping-cart-2',NULL,40,1,1,'采购申请-列表/详情（菜单/查看）',NOW(),NOW()),
('采购申请新增','business:purchase:request:add',2,0,'business',NULL,NULL,NULL,41,1,1,'新增采购申请/提交审批/快捷入口',NOW(),NOW()),
('采购申请编辑','business:purchase:request:edit',2,0,'business',NULL,NULL,NULL,42,1,1,'编辑采购申请',NOW(),NOW()),
('采购申请删除','business:purchase:request:delete',2,0,'business',NULL,NULL,NULL,43,1,1,'删除采购申请',NOW(),NOW()),
('采购申请导出','business:purchase:request:export',2,0,'business',NULL,NULL,NULL,44,1,1,'导出采购申请列表',NOW(),NOW()),
('采购申请审批','business:purchase:request:approve',2,0,'business',NULL,NULL,NULL,45,1,1,'审批采购申请（通过/驳回）',NOW(),NOW()),
('生成采购订单','business:purchase:order:add',2,0,'business',NULL,NULL,NULL,46,1,1,'从采购申请生成采购订单',NOW(),NOW()),
('采购合同查看','business:purchase:contract:view',2,0,'business',NULL,NULL,NULL,47,1,1,'查看关联采购合同',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:purchase:request:list','business:purchase:request:add','business:purchase:request:edit','business:purchase:request:delete','business:purchase:request:export','business:purchase:request:approve','business:purchase:order:add','business:purchase:contract:view');

-- ========== 菜单（经营管理 -> 采购管理 -> 采购申请） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '采购管理', '', 'el-icon-shopping-cart-2', 'business:purchase:request:list', 30, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='采购管理' AND deleted_at IS NULL AND parent_id=@business_id AND type=1);

SET @purchase_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='采购管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @purchase_menu_id, '采购申请', '/business/purchase/request/list', 'el-icon-shopping-cart-2', 'business:purchase:request:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:request:list' AND deleted_at IS NULL AND type=2);
