-- 154_create_production_order.sql
-- 工单列表（生产管理 -> 生产计划 -> 生产工单）：2 表 + 10 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('production:order:list:view','production:plan','production:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'production:order:%');
--   DELETE FROM permissions WHERE code LIKE 'production:order:%';
--   DROP TABLE IF EXISTS production_order_item;
--   DROP TABLE IF EXISTS production_order;

-- ========== 一、工单主表 ==========
CREATE TABLE IF NOT EXISTS `production_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号 PO+YYYYMMDD+4位流水',
  `order_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '工单类型：1生产工单 2维修工单',
  `source_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '来源类型：1销售订单 2维修订单 0手工',
  `source_id` int(11) NOT NULL DEFAULT 0 COMMENT '来源单据ID',
  `source_no` varchar(50) NOT NULL DEFAULT '' COMMENT '来源单据编号（冗余）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID（business_products）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '产品规格型号（冗余）',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID（维修工单时必填）',
  `customer_name` varchar(50) NOT NULL DEFAULT '' COMMENT '客户名称（冗余）',
  `plan_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '计划数量',
  `completed_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '完成数量',
  `progress` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '进度百分比（完成/计划*100）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0待派工 1已派工 2进行中 3待质检 4已完成 5已关闭',
  `priority` tinyint(1) NOT NULL DEFAULT 1 COMMENT '优先级：1普通 2紧急 3特急',
  `planned_start_date` date DEFAULT NULL COMMENT '计划开始日期',
  `planned_end_date` date DEFAULT NULL COMMENT '计划完成日期',
  `actual_start_date` date DEFAULT NULL COMMENT '实际开始日期',
  `actual_end_date` date DEFAULT NULL COMMENT '实际完成日期',
  `responsible_person_id` int(11) NOT NULL DEFAULT 0 COMMENT '负责人ID',
  `responsible_person_name` varchar(50) NOT NULL DEFAULT '' COMMENT '负责人姓名（冗余）',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '负责部门ID',
  `department_name` varchar(50) NOT NULL DEFAULT '' COMMENT '负责部门名称（冗余）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_status` (`status`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_source_no` (`source_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='生产/维修工单主表';

-- ========== 二、工单明细表 ==========
CREATE TABLE IF NOT EXISTS `production_order_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单主表ID',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID（warehouse_material）',
  `material_code` varchar(50) NOT NULL DEFAULT '' COMMENT '物料编码（冗余）',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称（冗余）',
  `specification` varchar(100) NOT NULL DEFAULT '' COMMENT '规格型号（冗余）',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `plan_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '计划用量',
  `actual_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '实际用量',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工单明细表（物料清单）';

-- ========== 三、权限（10 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('生产工单','production:order:list:view',2,0,'production','/production/plan/order/list','el-icon-document',NULL,210,1,1,'工单列表-查看（菜单）',NOW(),NOW()),
('生产工单详情','production:order:view',2,0,'production',NULL,NULL,NULL,211,1,1,'查看工单详情',NOW(),NOW()),
('新建工单','production:order:create',2,0,'production',NULL,NULL,NULL,212,1,1,'新建工单',NOW(),NOW()),
('编辑工单','production:order:edit',2,0,'production',NULL,NULL,NULL,213,1,1,'编辑工单',NOW(),NOW()),
('删除工单','production:order:delete',2,0,'production',NULL,NULL,NULL,214,1,1,'删除工单',NOW(),NOW()),
('工单派工','production:order:dispatch',2,0,'production',NULL,NULL,NULL,215,1,1,'工单派工',NOW(),NOW()),
('工单报工','production:order:report',2,0,'production',NULL,NULL,NULL,216,1,1,'工单报工',NOW(),NOW()),
('工单质检','production:order:quality',2,0,'production',NULL,NULL,NULL,217,1,1,'工单质检（申请/通过/驳回）',NOW(),NOW()),
('关闭工单','production:order:close',2,0,'production',NULL,NULL,NULL,218,1,1,'关闭工单',NOW(),NOW()),
('导出工单','production:order:export',2,0,'production',NULL,NULL,NULL,219,1,1,'导出工单列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'production:order:%';

-- ========== 四、菜单链：生产管理 -> 生产计划 -> 生产工单 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '生产管理', '', 'el-icon-set-up', 'production:view', 17, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:view' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:view' AND deleted_at IS NULL LIMIT 1), '生产计划', '', 'el-icon-date', 'production:plan', 10, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:plan' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:plan' AND deleted_at IS NULL LIMIT 1), '生产工单', '/production/plan/order/list', 'el-icon-document', 'production:order:list:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:order:list:view' AND deleted_at IS NULL);
