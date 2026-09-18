-- =====================================================
-- 097_create_business_contract.sql
-- 经营管理 → 订单中心 → 合同管理
--   1. 建表 4 张：business_contracts / business_contract_clauses / business_contract_approvals / business_contract_changes
--   2. 数据字典：合同类型/合同状态
--   3. 系统参数：合同编号前缀/到期提醒天数/自动检查开关
--   4. 权限定义与 super_admin 授权
--   5. 菜单（经营管理 → 订单中心 → 合同管理 → 合同列表/新增合同/合同到期提醒）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `business_contracts` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_no` varchar(50) NOT NULL DEFAULT '' COMMENT '合同编号 CT-YYYYMMDD-XXXX',
  `contract_name` varchar(200) NOT NULL DEFAULT '' COMMENT '合同名称',
  `contract_type` varchar(20) NOT NULL DEFAULT '' COMMENT '合同类型：sales/purchase/repair_service',
  `customer_id` int(11) DEFAULT NULL COMMENT '客户ID（销售/维修合同时必填）',
  `supplier_id` int(11) DEFAULT NULL COMMENT '供应商ID（采购合同时必填）',
  `customer_name` varchar(200) DEFAULT NULL COMMENT '客户名称（冗余）',
  `supplier_name` varchar(200) DEFAULT NULL COMMENT '供应商名称（冗余）',
  `contact_person` varchar(50) DEFAULT NULL COMMENT '联系人',
  `contact_phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `contract_amount` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '合同金额',
  `sign_date` date NOT NULL COMMENT '签订日期',
  `effective_date` date DEFAULT NULL COMMENT '生效日期',
  `expiry_date` date DEFAULT NULL COMMENT '到期日期',
  `contract_status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '合同状态：draft/pending/approved/executing/completed/terminated/voided',
  `content` text COMMENT '合同内容（条款摘要）',
  `attachments` json DEFAULT NULL COMMENT '附件列表',
  `responsible_person_id` int(11) DEFAULT NULL COMMENT '负责人ID',
  `responsible_person_name` varchar(50) DEFAULT NULL COMMENT '负责人姓名（冗余）',
  `remark` text COMMENT '备注',
  `parent_contract_id` int(11) DEFAULT NULL COMMENT '父合同ID（续签时关联原合同）',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_contract_no` (`contract_no`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_supplier_id` (`supplier_id`),
  KEY `idx_type_status` (`contract_type`, `contract_status`),
  KEY `idx_status_expiry` (`contract_status`, `expiry_date`),
  KEY `idx_sign_date` (`sign_date`),
  KEY `idx_expiry_date` (`expiry_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合同主表';

CREATE TABLE IF NOT EXISTS `business_contract_clauses` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) NOT NULL DEFAULT 0 COMMENT '合同ID',
  `clause_title` varchar(200) NOT NULL DEFAULT '' COMMENT '条款标题',
  `clause_content` text NOT NULL COMMENT '条款内容',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_contract_id` (`contract_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合同条款表';

CREATE TABLE IF NOT EXISTS `business_contract_approvals` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) NOT NULL DEFAULT 0 COMMENT '合同ID',
  `approver_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批人ID',
  `approver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '审批人姓名（冗余）',
  `approval_result` varchar(20) NOT NULL DEFAULT '' COMMENT '审批结果：pass/reject',
  `approval_comment` varchar(500) DEFAULT NULL COMMENT '审批意见',
  `approval_time` datetime DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_contract_id` (`contract_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合同审批记录表';

CREATE TABLE IF NOT EXISTS `business_contract_changes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) NOT NULL DEFAULT 0 COMMENT '合同ID',
  `change_type` varchar(20) NOT NULL DEFAULT '' COMMENT '变更类型：amount/date/content/status/renew/terminate',
  `old_value` text COMMENT '变更前值',
  `new_value` text COMMENT '变更后值',
  `change_reason` varchar(500) DEFAULT NULL COMMENT '变更原因',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_contract_id` (`contract_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合同变更记录表';

-- ========== 二、数据字典 ==========
-- 1. contract_type 合同类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('合同类型','contract_type','合同管理-合同类型',140,1,NOW(),NOW());
SET @dt_ct = (SELECT `id` FROM `dictionary_types` WHERE `code`='contract_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_ct,'销售合同','sales',1,'primary',1,NOW(),NOW()),
(@dt_ct,'采购合同','purchase',2,'success',1,NOW(),NOW()),
(@dt_ct,'维修服务合同','repair_service',3,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. contract_status 合同状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('合同状态','contract_status','合同管理-合同状态',141,1,NOW(),NOW());
SET @dt_cs = (SELECT `id` FROM `dictionary_types` WHERE `code`='contract_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt_cs,'草稿','draft',1,'info',1,NOW(),NOW()),
(@dt_cs,'待审批','pending',2,'warning',1,NOW(),NOW()),
(@dt_cs,'已生效','approved',3,'success',1,NOW(),NOW()),
(@dt_cs,'执行中','executing',4,'primary',1,NOW(),NOW()),
(@dt_cs,'已完结','completed',5,'info',1,NOW(),NOW()),
(@dt_cs,'已终止','terminated',6,'danger',1,NOW(),NOW()),
(@dt_cs,'已作废','voided',7,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('contract_no_prefix','合同编号前缀','CT','string','business','合同编号前缀（格式：{前缀}-YYYYMMDD-XXXX）',8,1,0,NOW(),NOW()),
('contract_expiry_remind_days','合同到期提醒天数','30','number','business','合同到期前N天提醒',9,1,0,NOW(),NOW()),
('contract_auto_expire_check','自动到期检查开关','true','boolean','business','是否启用合同到期自动检查',10,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('合同列表','business:contract:list',1,0,'business','/business/contract','el-icon-document',NULL,34,1,1,'合同管理-合同列表（菜单/查看）',NOW(),NOW()),
('合同新增','business:contract:add',2,0,'business',NULL,NULL,NULL,35,1,1,'新增合同/续签/复制',NOW(),NOW()),
('合同编辑','business:contract:edit',2,0,'business',NULL,NULL,NULL,36,1,1,'编辑合同/提交审批/生效/终止/作废/变更',NOW(),NOW()),
('合同删除','business:contract:delete',2,0,'business',NULL,NULL,NULL,37,1,1,'删除合同',NOW(),NOW()),
('合同审批','business:contract:approve',2,0,'business',NULL,NULL,NULL,38,1,1,'合同审批（通过/驳回）',NOW(),NOW()),
('合同导出','business:contract:export',2,0,'business',NULL,NULL,NULL,39,1,1,'导出合同列表',NOW(),NOW()),
('合同到期提醒','business:contract:remind',1,0,'business','/business/contract/remind','el-icon-bell',NULL,40,1,1,'合同到期提醒（菜单）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:contract:list','business:contract:add','business:contract:edit','business:contract:delete','business:contract:approve','business:contract:export','business:contract:remind');

-- ========== 五、菜单（经营管理 → 订单中心 → 合同管理） ==========
SET @order_menu_id = (SELECT id FROM menus WHERE name='订单中心' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0) LIMIT 1);

-- 合同管理目录
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @order_menu_id, '合同管理', '', 'el-icon-document', 'business:contract:list', 30, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='合同管理' AND deleted_at IS NULL AND parent_id=@order_menu_id AND type=1);

SET @contract_menu_id = (SELECT id FROM menus WHERE parent_id=@order_menu_id AND name='合同管理' AND deleted_at IS NULL LIMIT 1);

-- 合同列表
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @contract_menu_id, '合同列表', '/business/contract', 'el-icon-document', 'business:contract:list', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:contract:list' AND deleted_at IS NULL AND type=2);

-- 新增合同
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @contract_menu_id, '新增合同', '/business/contract/add', 'el-icon-plus', 'business:contract:add', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:contract:add' AND deleted_at IS NULL AND type=2);

-- 合同到期提醒
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @contract_menu_id, '合同到期提醒', '/business/contract/remind', 'el-icon-bell', 'business:contract:remind', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:contract:remind' AND deleted_at IS NULL AND type=2);
