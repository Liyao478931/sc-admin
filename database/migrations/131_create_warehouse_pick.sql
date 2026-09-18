-- 131_create_warehouse_pick.sql
-- 仓储管理 -> 配件出入库 -> 配件领用（车间领料）
-- 1. 建表：warehouse_pick（领料单主表）/ warehouse_pick_item（领料明细）/ warehouse_pick_version（版本快照）/ warehouse_pick_log（操作日志）
-- 2. 权限：warehouse:pick:view/add/edit/delete/audit/confirm/export/version:view/version:restore（9条）并授权 super_admin
-- 3. 菜单：配件出入库 -> 配件领用
-- 幂等写法，可重复执行
-- 回滚 down：删除菜单/权限/角色授权 + DROP 4 表

CREATE TABLE IF NOT EXISTS `warehouse_pick` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pick_no` varchar(30) NOT NULL DEFAULT '' COMMENT '领料单编号 PK+YYYYMMDD+XXXX',
  `pick_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '领料类型：1生产领料 2维修领料 3研发领料 4其他领料',
  `production_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联生产工单ID',
  `production_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '关联生产工单编号（冗余）',
  `repair_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联维修工单ID',
  `repair_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '关联维修工单编号（冗余）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联产品ID',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '领料部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '领料部门名称（冗余）',
  `picker_id` int(11) NOT NULL DEFAULT 0 COMMENT '领料人ID',
  `picker_name` varchar(50) NOT NULL DEFAULT '' COMMENT '领料人姓名（冗余）',
  `pick_date` date DEFAULT NULL COMMENT '领料日期',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '领料状态：0草稿 1待审核 2已审核 3已领料 4已驳回 5已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注/驳回原因',
  `purpose` varchar(500) NOT NULL DEFAULT '' COMMENT '用途说明',
  `version` int(11) NOT NULL DEFAULT 1 COMMENT '主版本号',
  `version_sub` int(11) NOT NULL DEFAULT 0 COMMENT '次版本号',
  `latest_version_id` int(11) NOT NULL DEFAULT 0 COMMENT '最新版本快照ID',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pick_no` (`pick_no`),
  KEY `idx_status` (`status`),
  KEY `idx_pick_date` (`pick_date`),
  KEY `idx_production_order` (`production_order_id`),
  KEY `idx_repair_order` (`repair_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件领料单主表';

CREATE TABLE IF NOT EXISTS `warehouse_pick_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pick_id` int(11) NOT NULL DEFAULT 0 COMMENT '领料单ID',
  `production_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联生产工单明细ID',
  `repair_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联维修工单明细ID',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID',
  `material_code` varchar(30) NOT NULL DEFAULT '' COMMENT '物料编码（冗余）',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称（冗余）',
  `spec` varchar(200) DEFAULT NULL COMMENT '规格型号（冗余）',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `apply_quantity` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '申请数量',
  `actual_quantity` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '实际领料数量',
  `out_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '出库单价（加权平均价）',
  `out_total` decimal(18,4) NOT NULL DEFAULT 0 COMMENT '出库总价',
  `picker` varchar(50) DEFAULT NULL COMMENT '领取人',
  `pick_date` date DEFAULT NULL COMMENT '领取日期',
  `location_id` int(11) NOT NULL DEFAULT 0 COMMENT '存放货位ID（出库货位）',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pick_id` (`pick_id`),
  KEY `idx_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件领料明细表';

CREATE TABLE IF NOT EXISTS `warehouse_pick_version` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pick_id` int(11) NOT NULL DEFAULT 0 COMMENT '领料单ID',
  `version_no` varchar(10) NOT NULL DEFAULT '' COMMENT '版本号 V1.0',
  `snapshot` json DEFAULT NULL COMMENT '完整数据快照（主表+明细）',
  `change_fields` json DEFAULT NULL COMMENT '变更字段列表',
  `change_summary` varchar(500) DEFAULT NULL COMMENT '变更摘要',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pick_id` (`pick_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件领料单版本快照表';

CREATE TABLE IF NOT EXISTS `warehouse_pick_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pick_id` int(11) NOT NULL DEFAULT 0 COMMENT '领料单ID',
  `action_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6确认发料 7撤销 8删除 9版本恢复',
  `action_label` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `from_status` tinyint(1) DEFAULT NULL COMMENT '操作前状态',
  `to_status` tinyint(1) DEFAULT NULL COMMENT '操作后状态',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `action_time` datetime DEFAULT NULL COMMENT '操作时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `field_snapshot` json DEFAULT NULL COMMENT '变更字段快照',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pick_id` (`pick_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配件领料单操作日志表';

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('配件领用查看','warehouse:pick:view',2,0,'warehouse','/warehouse/parts/pick/list','el-icon-sold-out',NULL,45,1,1,'配件领用-查看（菜单）',NOW(),NOW()),
('配件领用新增','warehouse:pick:add',2,0,'warehouse',NULL,NULL,NULL,46,1,1,'新增领料单',NOW(),NOW()),
('配件领用编辑','warehouse:pick:edit',2,0,'warehouse',NULL,NULL,NULL,47,1,1,'编辑领料单',NOW(),NOW()),
('配件领用删除','warehouse:pick:delete',2,0,'warehouse',NULL,NULL,NULL,48,1,1,'删除领料单',NOW(),NOW()),
('配件领用审核','warehouse:pick:audit',2,0,'warehouse',NULL,NULL,NULL,49,1,1,'审核领料单（通过/驳回）',NOW(),NOW()),
('配件领用发料','warehouse:pick:confirm',2,0,'warehouse',NULL,NULL,NULL,50,1,1,'确认发料',NOW(),NOW()),
('配件领用导出','warehouse:pick:export',2,0,'warehouse',NULL,NULL,NULL,51,1,1,'导出领料单',NOW(),NOW()),
('领料版本查看','warehouse:pick:version:view',2,0,'warehouse',NULL,NULL,NULL,52,1,1,'查看版本历史与详情',NOW(),NOW()),
('领料版本恢复','warehouse:pick:version:restore',2,0,'warehouse',NULL,NULL,NULL,53,1,1,'恢复历史版本',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:pick:%';

-- 菜单：配件出入库 -> 配件领用
SET @parts_menu_id = (SELECT id FROM menus WHERE permission='warehouse:parts' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @parts_menu_id, '配件领用', '/warehouse/parts/pick/list', 'el-icon-sold-out', 'warehouse:pick:view', 15, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:pick:view' AND deleted_at IS NULL AND parent_id=@parts_menu_id);
