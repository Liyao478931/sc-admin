-- 117_create_purchase_arrival.sql
-- 经营管理 -> 采购管理 -> 采购到货 / 到货记录
-- 1. 建表：business_purchase_arrival（到货单）/ business_purchase_arrival_item（明细）/ business_purchase_arrival_notice（通知记录）
-- 2. business_purchase_order 增加到货进度字段（arrive_status / arrived_quantity，8.1 回写）
-- 3. 权限：business:purchase:arrival:view/add/edit/delete/notice/quality/warehouse/record:view/record:export（9条）并授权 super_admin
-- 4. 菜单：采购到货（/business/purchase/arrival/list）、到货记录（/business/purchase/arrival/record）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('business:purchase:arrival:view','business:purchase:arrival:record:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:purchase:arrival:%');
--   DELETE FROM permissions WHERE code LIKE 'business:purchase:arrival:%';
--   DROP TABLE IF EXISTS business_purchase_arrival_notice;
--   DROP TABLE IF EXISTS business_purchase_arrival_item;
--   DROP TABLE IF EXISTS business_purchase_arrival;
--   ALTER TABLE business_purchase_order DROP COLUMN arrived_quantity, DROP COLUMN arrive_status;

-- ========== 一、采购到货单主表 ==========
CREATE TABLE IF NOT EXISTS `business_purchase_arrival` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `arrival_no` varchar(30) NOT NULL DEFAULT '' COMMENT '到货单编号 AR+YYYYMMDD+XXXX',
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联采购订单ID',
  `order_no` varchar(30) NOT NULL DEFAULT '' COMMENT '关联采购订单编号（冗余）',
  `supplier_id` int(11) NOT NULL DEFAULT 0 COMMENT '供应商ID',
  `supplier_name` varchar(200) NOT NULL DEFAULT '' COMMENT '供应商名称（冗余）',
  `arrival_date` date DEFAULT NULL COMMENT '到货日期',
  `logistics_company` varchar(100) DEFAULT NULL COMMENT '物流公司名称',
  `track_no` varchar(60) DEFAULT NULL COMMENT '物流单号',
  `receiver` varchar(50) DEFAULT NULL COMMENT '收货人（签收人）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '到货状态：0待质检 1质检中 2质检合格 3质检不合格 4待入库 5已入库',
  `quality_remark` varchar(500) DEFAULT NULL COMMENT '质检结果备注（整体结论）',
  `remark` text COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_arrival_no` (`arrival_no`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_status` (`status`),
  KEY `idx_arrival_date` (`arrival_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购到货单主表';

-- ========== 二、采购到货明细表 ==========
CREATE TABLE IF NOT EXISTS `business_purchase_arrival_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `arrival_id` int(11) NOT NULL DEFAULT 0 COMMENT '到货单ID',
  `order_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '采购订单明细ID（行级追溯）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）',
  `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '规格型号（冗余）',
  `product_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（冗余）',
  `order_quantity` int(11) NOT NULL DEFAULT 0 COMMENT '订单数量',
  `arrival_quantity` int(11) NOT NULL DEFAULT 0 COMMENT '到货数量',
  `qualified_quantity` int(11) NOT NULL DEFAULT 0 COMMENT '质检合格数量',
  `unqualified_quantity` int(11) NOT NULL DEFAULT 0 COMMENT '质检不合格数量',
  `quality_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '质检状态：0待检 1合格 2不合格',
  `unqualified_reason` varchar(255) DEFAULT NULL COMMENT '不合格原因',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_arrival_id` (`arrival_id`),
  KEY `idx_order_item` (`order_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购到货明细表';

-- ========== 三、到货通知记录表 ==========
CREATE TABLE IF NOT EXISTS `business_purchase_arrival_notice` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `arrival_id` int(11) NOT NULL DEFAULT 0 COMMENT '到货单ID',
  `notice_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '通知类型：1到货通知 2质检完成通知 3入库完成通知',
  `target_user_id` int(11) NOT NULL DEFAULT 0 COMMENT '通知对象ID',
  `target_user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '通知对象姓名（冗余）',
  `notice_way` varchar(30) NOT NULL DEFAULT '1' COMMENT '通知方式：1站内信 2邮件 3短信 4多种组合',
  `content` text COMMENT '通知内容',
  `send_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '发送状态：0待发送 1已发送 2发送失败',
  `send_time` datetime DEFAULT NULL COMMENT '发送时间',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_arrival_id` (`arrival_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购到货通知记录表';

-- ========== 四、采购订单增加 到货进度 字段（8.1 回写） ==========
ALTER TABLE `business_purchase_order`
  ADD COLUMN `arrive_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '到货状态：0未到货 1部分到货 2全部到货' AFTER `received_quantity`,
  ADD COLUMN `arrived_quantity` int(11) NOT NULL DEFAULT 0 COMMENT '已到货总数量' AFTER `arrive_status`;

-- ========== 五、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('采购到货','business:purchase:arrival:view',1,0,'business','/business/purchase/arrival/list','el-icon-van',NULL,60,1,1,'采购到货-列表/详情（菜单/查看）',NOW(),NOW()),
('采购到货新增','business:purchase:arrival:add',2,0,'business',NULL,NULL,NULL,61,1,1,'新增到货登记',NOW(),NOW()),
('采购到货编辑','business:purchase:arrival:edit',2,0,'business',NULL,NULL,NULL,62,1,1,'编辑到货单',NOW(),NOW()),
('采购到货删除','business:purchase:arrival:delete',2,0,'business',NULL,NULL,NULL,63,1,1,'删除到货单',NOW(),NOW()),
('采购到货通知','business:purchase:arrival:notice',2,0,'business',NULL,NULL,NULL,64,1,1,'发送到货通知',NOW(),NOW()),
('采购到货质检','business:purchase:arrival:quality',2,0,'business',NULL,NULL,NULL,65,1,1,'执行质检操作',NOW(),NOW()),
('采购到货生成入库单','business:purchase:arrival:warehouse',2,0,'business',NULL,NULL,NULL,66,1,1,'生成入库单',NOW(),NOW()),
('到货记录查看','business:purchase:arrival:record:view',1,0,'business','/business/purchase/arrival/record','el-icon-notebook-2',NULL,67,1,1,'到货记录-查看（菜单）',NOW(),NOW()),
('到货记录导出','business:purchase:arrival:record:export',2,0,'business',NULL,NULL,NULL,68,1,1,'导出到货记录',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:purchase:arrival:view','business:purchase:arrival:add','business:purchase:arrival:edit','business:purchase:arrival:delete','business:purchase:arrival:notice','business:purchase:arrival:quality','business:purchase:arrival:warehouse','business:purchase:arrival:record:view','business:purchase:arrival:record:export');

-- ========== 六、菜单（经营管理 -> 采购管理 -> 采购到货 / 到货记录） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);
SET @purchase_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='采购管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @purchase_menu_id, '采购到货', '/business/purchase/arrival/list', 'el-icon-van', 'business:purchase:arrival:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:arrival:view' AND deleted_at IS NULL AND type=2);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @purchase_menu_id, '到货记录', '/business/purchase/arrival/record', 'el-icon-notebook-2', 'business:purchase:arrival:record:view', 50, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:arrival:record:view' AND deleted_at IS NULL AND type=2);
