-- 138_create_warehouse_scrap.sql
-- 报废出库：2 张表（单物料报废单主表 + 操作日志）+ 7 权限 + 菜单
-- 说明：报废单为单物料设计（主表含物料/数量/单价/总价），无需明细表
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:scrap:view' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:scrap:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:scrap:%';
--   DROP TABLE IF EXISTS warehouse_scrap_log;
--   DROP TABLE IF EXISTS warehouse_scrap;

-- ========== 一、报废单主表（单物料） ==========
CREATE TABLE IF NOT EXISTS `warehouse_scrap` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `scrap_no` varchar(30) NOT NULL DEFAULT '' COMMENT '报废单编号 SC0001',
  `pick_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联领料单ID（可选）',
  `pick_no` varchar(30) NOT NULL DEFAULT '' COMMENT '关联领料单编号（冗余）',
  `scrap_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '报废类型：1质量 2过期 3技术淘汰 4事故损坏 5其他',
  `material_id` int(11) NOT NULL DEFAULT 0 COMMENT '物料ID',
  `material_code` varchar(30) NOT NULL DEFAULT '' COMMENT '物料编码',
  `material_name` varchar(200) NOT NULL DEFAULT '' COMMENT '物料名称',
  `spec` varchar(200) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '报废部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '报废部门名称',
  `applicant_id` int(11) NOT NULL DEFAULT 0 COMMENT '报废申请人ID',
  `applicant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '报废申请人姓名',
  `scrap_date` date DEFAULT NULL COMMENT '报废日期',
  `scrap_quantity` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '报废数量',
  `scrap_price` decimal(14,4) NOT NULL DEFAULT 0.0000 COMMENT '报废单价（当前加权平均价）',
  `scrap_total` decimal(18,4) NOT NULL DEFAULT 0.0000 COMMENT '报废总价',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1待审核 2已审核 3已报废 4已驳回 5已撤销',
  `auditor_id` int(11) NOT NULL DEFAULT 0 COMMENT '审核人ID',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
  `disposal_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '处理方式：1销毁 2退回供应商 3废品回收 4其他',
  `scrap_reason` varchar(500) NOT NULL DEFAULT '' COMMENT '报废原因',
  `remark` varchar(500) DEFAULT NULL COMMENT '整体备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_scrap_no` (`scrap_no`),
  KEY `idx_material_id` (`material_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报废出库单主表';

-- ========== 二、报废操作日志表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_scrap_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `scrap_id` int(11) NOT NULL DEFAULT 0 COMMENT '报废单ID',
  `action_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作类型：1创建 2编辑 3提交审核 4审核通过 5审核驳回 6确认报废 7撤销 8删除',
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
  KEY `idx_scrap_id` (`scrap_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报废出库操作日志表';

-- ========== 三、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('报废出库查看','warehouse:scrap:view',2,0,'warehouse','/warehouse/parts/scrap/list','el-icon-delete',NULL,48,1,1,'报废出库-查看（菜单）',NOW(),NOW()),
('报废出库新增','warehouse:scrap:add',2,0,'warehouse',NULL,NULL,NULL,49,1,1,'新增报废单',NOW(),NOW()),
('报废出库编辑','warehouse:scrap:edit',2,0,'warehouse',NULL,NULL,NULL,50,1,1,'编辑报废单',NOW(),NOW()),
('报废出库删除','warehouse:scrap:delete',2,0,'warehouse',NULL,NULL,NULL,51,1,1,'删除报废单',NOW(),NOW()),
('报废出库审核','warehouse:scrap:audit',2,0,'warehouse',NULL,NULL,NULL,52,1,1,'审核报废单（通过/驳回）',NOW(),NOW()),
('报废出库确认','warehouse:scrap:confirm',2,0,'warehouse',NULL,NULL,NULL,53,1,1,'确认报废（出库）',NOW(),NOW()),
('报废出库导出','warehouse:scrap:export',2,0,'warehouse',NULL,NULL,NULL,54,1,1,'导出报废单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:scrap:%';

-- ========== 四、菜单：配件出入库 -> 报废出库 ==========
SET @parts_menu_id = (SELECT id FROM menus WHERE permission='warehouse:parts' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @parts_menu_id, '报废出库', '/warehouse/parts/scrap/list', 'el-icon-delete', 'warehouse:scrap:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:scrap:view' AND deleted_at IS NULL AND parent_id=@parts_menu_id);
