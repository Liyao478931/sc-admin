-- 185_create_ship_notice.sql
-- 人事/经营管理「发货通知」：2 表 + 7 权限 + 2 菜单 + 统一审批流程
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:ship:notice:view' OR (name='发货管理' AND parent_id=(SELECT id FROM menus WHERE name='销售管理' AND parent_id=136));
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:ship:notice:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:ship:notice:%';
--   DELETE FROM approval_flow WHERE biz_type='sales_ship_notice';
--   DROP TABLE IF EXISTS sales_ship_notice_item;
--   DROP TABLE IF EXISTS sales_ship_notice;

-- ========== 一、发货通知主表 ==========
CREATE TABLE IF NOT EXISTS `sales_ship_notice` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `notice_no` varchar(50) NOT NULL DEFAULT '' COMMENT '通知单编号 SN+YYYYMMDD+4位流水',
  `notice_name` varchar(100) NOT NULL DEFAULT '' COMMENT '通知单名称',
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联销售订单ID',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '销售订单编号（冗余）',
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(200) NOT NULL DEFAULT '' COMMENT '客户名称（冗余）',
  `receiver` varchar(50) NOT NULL DEFAULT '' COMMENT '收货人',
  `receiver_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '收货电话',
  `receiver_address` varchar(255) DEFAULT NULL COMMENT '收货地址',
  `ship_date` date DEFAULT NULL COMMENT '发货日期',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '通知状态：0草稿 1待审核 2已审核 3已下推 4已取消',
  `approval_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联统一审批实例ID',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `push_out_id` int(11) NOT NULL DEFAULT 0 COMMENT '下推生成出库单ID',
  `push_out_no` varchar(50) DEFAULT NULL COMMENT '下推生成出库单编号',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notice_no` (`notice_no`),
  KEY `idx_order` (`order_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发货通知主表';

-- ========== 二、发货通知明细表 ==========
CREATE TABLE IF NOT EXISTS `sales_ship_notice_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `notice_id` int(11) NOT NULL DEFAULT 0 COMMENT '通知单ID',
  `order_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联销售订单明细ID',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(50) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `specification` varchar(100) DEFAULT NULL COMMENT '规格型号（冗余）',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位（冗余）',
  `notice_quantity` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '通知数量',
  `out_quantity` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '实际出库数量（出库后回写）',
  `suggest_location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位建议ID',
  `suggest_location_name` varchar(100) DEFAULT NULL COMMENT '存放货位建议名称',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_notice` (`notice_id`),
  KEY `idx_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发货通知明细表';

-- ========== 二-B、发货通知操作日志表 ==========
CREATE TABLE IF NOT EXISTS `sales_ship_notice_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `notice_id` int(11) NOT NULL DEFAULT 0 COMMENT '通知单ID',
  `action` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6下推出库单 7取消',
  `action_label` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `before_status` tinyint(1) DEFAULT NULL COMMENT '操作前状态',
  `after_status` tinyint(1) DEFAULT NULL COMMENT '操作后状态',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `operator_time` datetime DEFAULT NULL COMMENT '操作时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_notice_id` (`notice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发货通知操作日志表';

-- ========== 三、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('发货通知','sales:ship:notice:view',2,0,'business','/business/sales/ship/notice','el-icon-truck',NULL,270,1,1,'发货通知-查看（菜单）',NOW(),NOW()),
('新增发货通知','sales:ship:notice:add',2,0,'business',NULL,NULL,NULL,271,1,1,'新增发货通知',NOW(),NOW()),
('编辑发货通知','sales:ship:notice:edit',2,0,'business',NULL,NULL,NULL,272,1,1,'编辑发货通知',NOW(),NOW()),
('删除发货通知','sales:ship:notice:delete',2,0,'business',NULL,NULL,NULL,273,1,1,'删除发货通知',NOW(),NOW()),
('审核发货通知','sales:ship:notice:audit',2,0,'business',NULL,NULL,NULL,274,1,1,'审核发货通知（统一审批）',NOW(),NOW()),
('下推出库单','sales:ship:notice:push',2,0,'business',NULL,NULL,NULL,275,1,1,'发货通知下推出库单',NOW(),NOW()),
('导出发货通知','sales:ship:notice:export',2,0,'business',NULL,NULL,NULL,276,1,1,'导出发货通知',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:ship:notice:%';

-- ========== 四、菜单：销售管理（136下）-> 发货管理（目录）-> 发货通知（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='销售管理' AND parent_id=136 AND deleted_at IS NULL LIMIT 1), '发货管理', NULL, 'el-icon-ship', '', 20, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='发货管理' AND parent_id=(SELECT id FROM menus WHERE name='销售管理' AND parent_id=136 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='发货管理' AND parent_id=(SELECT id FROM menus WHERE name='销售管理' AND parent_id=136 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL LIMIT 1), '发货通知', '/business/sales/ship/notice', 'el-icon-truck', 'sales:ship:notice:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/ship/notice' AND deleted_at IS NULL);

-- ========== 五、统一审批流程（sales_ship_notice） ==========
INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`module_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('sales_ship_notice', '发货通知', '经营管理', 1, 48, '[{"node_name":"销售主管审批","approver_type":"role","approver_value":"super_admin","approver_name":"管理员","timeout_hours":48,"timeout_action":"remind"}]', 1, '发货通知审批', NOW(), NOW());
