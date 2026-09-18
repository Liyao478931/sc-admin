-- 180_create_diff.sql
-- 仓储管理「库存盘点 - 盘点差异」：inventory_result 加处理状态字段 + 3 权限 + 1 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/warehouse/check/diff';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:check:diff:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:check:diff:%';
--   ALTER TABLE inventory_result DROP COLUMN process_status, DROP COLUMN process_remark, DROP COLUMN process_by, DROP COLUMN process_at, DROP COLUMN adjust_order_no;

-- ========== 一、inventory_result 增加处理状态字段（幂等） ==========
SET @cnt := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='inventory_result' AND COLUMN_NAME IN ('process_status','process_remark','process_by','process_at','adjust_order_no'));
SET @sql := IF(@cnt = 0,
'ALTER TABLE `inventory_result`
  ADD COLUMN `process_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''处理状态：0待处理 1已处理 2已忽略'' AFTER `status`,
  ADD COLUMN `process_remark` varchar(500) DEFAULT NULL COMMENT ''处理备注'' AFTER `process_status`,
  ADD COLUMN `process_by` int(11) NOT NULL DEFAULT 0 COMMENT ''处理人ID'' AFTER `process_remark`,
  ADD COLUMN `process_at` datetime DEFAULT NULL COMMENT ''处理时间'' AFTER `process_by`,
  ADD COLUMN `adjust_order_no` varchar(50) DEFAULT NULL COMMENT ''关联调整单编号'' AFTER `process_at`',
'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 二、权限（3 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('盘点差异','warehouse:check:diff:view',2,0,'warehouse','/warehouse/check/diff','el-icon-difference',NULL,60,1,1,'盘点差异-查看（菜单）',NOW(),NOW()),
('处理盘点差异','warehouse:check:diff:process',2,0,'warehouse',NULL,NULL,NULL,61,1,1,'处理/忽略差异，生成调整单',NOW(),NOW()),
('导出盘点差异','warehouse:check:diff:export',2,0,'warehouse',NULL,NULL,NULL,62,1,1,'导出差异报表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'warehouse:check:diff:%';

-- ========== 三、菜单（库存盘点 -> 盘点差异，path 幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:check:plan:module' AND deleted_at IS NULL LIMIT 1), '盘点差异', '/warehouse/check/diff', 'el-icon-difference', 'warehouse:check:diff:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/warehouse/check/diff' AND deleted_at IS NULL);
