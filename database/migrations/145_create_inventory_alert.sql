-- 145_create_inventory_alert.sql
-- 库存预警（仓储管理 -> 库存管理 -> 库存预警）：4 权限 + 菜单 + 预警规则配置种子
-- 说明：无新增表；warehouse_material 的 alert_ignored/alert_ignore_reason 列由执行器（信息架构检查）幂等添加
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:inventory:alert:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:inventory:alert:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:inventory:alert:%';
--   DELETE FROM system_params WHERE param_key LIKE 'warehouse_inventory_alert_%';

-- ========== 一、权限（4 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('库存预警','warehouse:inventory:alert:view',2,0,'warehouse','/warehouse/inventory/alert','el-icon-warning',NULL,80,1,1,'库存预警-查看（菜单）',NOW(),NOW()),
('库存预警处理','warehouse:inventory:alert:handle',2,0,'warehouse',NULL,NULL,NULL,81,1,1,'库存预警处理（生成采购申请/忽略）',NOW(),NOW()),
('库存预警配置','warehouse:inventory:alert:config',2,0,'warehouse',NULL,NULL,NULL,82,1,1,'库存预警规则配置（调整安全库存）',NOW(),NOW()),
('库存预警导出','warehouse:inventory:alert:export',2,0,'warehouse',NULL,NULL,NULL,83,1,1,'导出库存预警',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:inventory:alert:%';

-- ========== 二、菜单：库存管理（warehouse:inventory）-> 库存预警 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:inventory' AND deleted_at IS NULL LIMIT 1), '库存预警', '/warehouse/inventory/alert', 'el-icon-warning', 'warehouse:inventory:alert:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:inventory:alert:view' AND deleted_at IS NULL);

-- ========== 三、预警规则配置种子（system_params） ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('warehouse_inventory_alert_enabled','库存预警启用开关','1','string','warehouse','库存预警总开关：1开启 0关闭',1,1,0,NOW(),NOW()),
('warehouse_inventory_alert_threshold','低库存预警阈值比例(%)','100','string','warehouse','库存低于安全库存量的该比例时触发偏低预警（如120表示低于1.2倍即预警）',2,1,0,NOW(),NOW()),
('warehouse_inventory_alert_frequency','预警检查频率','hourly','string','warehouse','预警检查频率：realtime实时/hourly每小时/daily每天',3,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),
`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();
