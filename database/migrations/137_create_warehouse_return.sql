-- 137_create_warehouse_return.sql
-- 配件退库（退库管理）：3 张表 + 7 权限 + 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:return:view' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:return:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:return:%';
--   DROP TABLE IF EXISTS warehouse_return_log;
--   DROP TABLE IF EXISTS warehouse_return_item;
--   DROP TABLE IF EXISTS warehouse_return;

-- ========== 一、退库单主表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_return` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `return_no` varchar(30) NOT NULL DEFAULT '' COMMENT '退库单编号 RT0001',
  `pick_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联领料单ID',
  `pick_no` varchar(30) NOT NULL DEFAULT '' COMMENT '关联领料单编号（冗余）',
  `return_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '退库类型：1生产 2维修 3质量 4其他',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '退库部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '退库部门名称（从领料单带出）',
  `returner_id` int(11) NOT NULL DEFAULT 0 COMMENT '退库人ID',
  `returner_name` varchar(50) NOT NULL DEFAULT '' COMMENT '退库人姓名',
  `return_date` date DEFAULT NULL COMMENT '退库日期',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审核 2已审核 3已退库 4已驳回 5已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `return_reason` varchar(500) NOT NULL DEFAULT '' COMMENT '退库原因',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_return_no` (`return_no`),
  KEY `idx_pick_id` (`pick_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件退库单主表';

-- ========== 二、退库明细表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_return_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `return_id` int(11) NOT NULL DEFAULT 0 COMMENT '退库单ID',
  `pick_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联领料单明细ID',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID',
  `material_code` varchar(30) NOT NULL DEFAULT '' COMMENT '物料编码',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称',
  `spec` varchar(200) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `pick_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '领料数量（只读参考）',
  `returned_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '已退库数量（只读参考）',
  `return_quantity` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '本次退库数量',
  `return_price` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '退库单价（当前加权平均价）',
  `return_total` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '退库总价',
  `material_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '物料状态：1完好 2待检 3报废',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位ID',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_return_id` (`return_id`),
  KEY `idx_pick_item_id` (`pick_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件退库明细表';

-- ========== 三、退库操作日志表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_return_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `return_id` int(11) NOT NULL DEFAULT 0 COMMENT '退库单ID',
  `action_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6确认退库 7撤销 8删除',
  `action_label` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `from_status` tinyint(1) DEFAULT NULL COMMENT '操作前状态',
  `to_status` tinyint(1) DEFAULT NULL COMMENT '操作后状态',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `action_time` datetime DEFAULT NULL COMMENT '操作时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `field_snapshot` json DEFAULT NULL COMMENT '变更字段快照（JSON）',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_return_id` (`return_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件退库操作日志表';

-- ========== 四、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('配件退库查看','warehouse:return:view',2,0,'warehouse','/warehouse/parts/return/list','el-icon-refresh-left',NULL,41,1,1,'配件退库-查看（菜单）',NOW(),NOW()),
('配件退库新增','warehouse:return:add',2,0,'warehouse',NULL,NULL,NULL,42,1,1,'新增退库单',NOW(),NOW()),
('配件退库编辑','warehouse:return:edit',2,0,'warehouse',NULL,NULL,NULL,43,1,1,'编辑退库单',NOW(),NOW()),
('配件退库删除','warehouse:return:delete',2,0,'warehouse',NULL,NULL,NULL,44,1,1,'删除退库单',NOW(),NOW()),
('配件退库审核','warehouse:return:audit',2,0,'warehouse',NULL,NULL,NULL,45,1,1,'审核退库单（通过/驳回）',NOW(),NOW()),
('配件退库确认','warehouse:return:confirm',2,0,'warehouse',NULL,NULL,NULL,46,1,1,'确认退库（入库）',NOW(),NOW()),
('配件退库导出','warehouse:return:export',2,0,'warehouse',NULL,NULL,NULL,47,1,1,'导出退库单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:return:%';

-- ========== 五、菜单：配件出入库 -> 配件退库 ==========
SET @parts_menu_id = (SELECT id FROM menus WHERE permission='warehouse:parts' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @parts_menu_id, '配件退库', '/warehouse/parts/return/list', 'el-icon-refresh-left', 'warehouse:return:view', 15, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:return:view' AND deleted_at IS NULL AND parent_id=@parts_menu_id);
