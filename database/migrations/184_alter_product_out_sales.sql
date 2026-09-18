-- 184_alter_product_out_sales.sql
-- 销售出库单列表：warehouse_product_out 加发货列 + business_orders 加出库状态列 + 8 权限 + 2 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:out:list:view' OR (name='销售管理' AND parent_id=136);
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:out:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:out:%';
--   ALTER TABLE warehouse_product_out DROP COLUMN ship_method, DROP COLUMN ship_company, DROP COLUMN ship_no, DROP COLUMN ship_date, DROP COLUMN consignee, DROP COLUMN consignee_phone;
--   ALTER TABLE business_orders DROP COLUMN out_quantity, DROP COLUMN out_status;

-- ========== 一、出库单加发货列 + 审批实例ID ==========
SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='approval_id');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `approval_id` int(11) NOT NULL DEFAULT 0 COMMENT ''关联统一审批实例ID'' AFTER `status`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='ship_method');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `ship_method` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''发货方式：1物流 2自提 3快递'' AFTER `audit_remark`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='ship_company');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `ship_company` varchar(100) DEFAULT NULL COMMENT ''物流公司'' AFTER `ship_method`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='ship_no');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `ship_no` varchar(100) DEFAULT NULL COMMENT ''物流单号'' AFTER `ship_company`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='ship_date');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `ship_date` date DEFAULT NULL COMMENT ''发货日期'' AFTER `ship_no`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='consignee');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `consignee` varchar(50) DEFAULT NULL COMMENT ''收货人'' AFTER `ship_date`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='warehouse_product_out' AND COLUMN_NAME='consignee_phone');
SET @sql := IF(@cnt=0, 'ALTER TABLE `warehouse_product_out` ADD COLUMN `consignee_phone` varchar(20) DEFAULT NULL COMMENT ''收货电话'' AFTER `consignee`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ========== 二、销售订单加出库状态列 ==========
SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_orders' AND COLUMN_NAME='out_quantity');
SET @sql := IF(@cnt=0, 'ALTER TABLE `business_orders` ADD COLUMN `out_quantity` decimal(14,2) NOT NULL DEFAULT 0 COMMENT ''已出库数量'' AFTER `order_status`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_orders' AND COLUMN_NAME='out_status');
SET @sql := IF(@cnt=0, 'ALTER TABLE `business_orders` ADD COLUMN `out_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''出库状态：0未出库 1部分出库 2全部出库'' AFTER `out_quantity`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ========== 三、权限（8 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('出库单列表','sales:out:list:view',2,0,'business','/business/sales/out/list','el-icon-box',NULL,260,1,1,'销售出库-查看（菜单）',NOW(),NOW()),
('新增出库单','sales:out:add',2,0,'business',NULL,NULL,NULL,261,1,1,'新增销售出库单',NOW(),NOW()),
('编辑出库单','sales:out:edit',2,0,'business',NULL,NULL,NULL,262,1,1,'编辑销售出库单',NOW(),NOW()),
('删除出库单','sales:out:delete',2,0,'business',NULL,NULL,NULL,263,1,1,'删除销售出库单',NOW(),NOW()),
('审核出库单','sales:out:audit',2,0,'business',NULL,NULL,NULL,264,1,1,'审核销售出库单（统一审批）',NOW(),NOW()),
('确认出库','sales:out:confirm',2,0,'business',NULL,NULL,NULL,265,1,1,'确认销售出库（扣减库存）',NOW(),NOW()),
('登记发货','sales:out:ship',2,0,'business',NULL,NULL,NULL,266,1,1,'登记销售出库发货',NOW(),NOW()),
('导出出库单','sales:out:export',2,0,'business',NULL,NULL,NULL,267,1,1,'导出销售出库单',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:out:%';

-- ========== 四、菜单：经营管理（id=136）-> 销售管理（目录）-> 出库单列表（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 136, '销售管理', NULL, 'el-icon-shopping-cart-full', '', 60, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='销售管理' AND parent_id=136 AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='销售管理' AND parent_id=136 AND deleted_at IS NULL LIMIT 1), '出库单列表', '/business/sales/out/list', 'el-icon-box', 'sales:out:list:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/out/list' AND deleted_at IS NULL);
