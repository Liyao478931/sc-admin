-- 121_create_warehouse.sql
-- 仓储管理 -> 基础设置 -> 仓库管理（仓库档案，仓储模块基础）
-- 1. 建表：warehouse（仓库表）
-- 2. 权限：warehouse:setting:warehouse:view/add/edit/delete（4条）并授权 super_admin
-- 3. 菜单：仓储管理 -> 基础设置 -> 仓库管理
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:setting:warehouse:view' OR permission='warehouse:setting' OR permission='warehouse:module';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:%';
--   DROP TABLE IF EXISTS warehouse;

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `warehouse` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `warehouse_code` varchar(30) NOT NULL DEFAULT '' COMMENT '仓库编码 WH001',
  `warehouse_name` varchar(100) NOT NULL DEFAULT '' COMMENT '仓库名称',
  `warehouse_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '仓库类型：1原材料仓 2半成品仓 3成品仓 4备件仓 5待检仓 6报废仓',
  `address` varchar(200) DEFAULT NULL COMMENT '仓库地址',
  `manager_id` int(11) NOT NULL DEFAULT 0 COMMENT '负责人ID',
  `manager_name` varchar(50) NOT NULL DEFAULT '' COMMENT '负责人姓名（冗余）',
  `phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_warehouse_code` (`warehouse_code`),
  KEY `idx_type` (`warehouse_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='仓库表';

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('仓储管理','warehouse:module',1,0,'warehouse','','el-icon-s-shop',NULL,40,1,1,'仓储管理（顶级菜单）',NOW(),NOW()),
('基础设置','warehouse:setting',1,0,'warehouse','','el-icon-setting',NULL,10,1,1,'仓储-基础设置（分组）',NOW(),NOW()),
('仓库查看','warehouse:setting:warehouse:view',2,0,'warehouse','/warehouse/setting/warehouse','el-icon-office-building',NULL,11,1,1,'仓库管理-查看（菜单）',NOW(),NOW()),
('仓库新增','warehouse:setting:warehouse:add',2,0,'warehouse',NULL,NULL,NULL,12,1,1,'新增仓库',NOW(),NOW()),
('仓库编辑','warehouse:setting:warehouse:edit',2,0,'warehouse',NULL,NULL,NULL,13,1,1,'编辑仓库',NOW(),NOW()),
('仓库删除','warehouse:setting:warehouse:delete',2,0,'warehouse',NULL,NULL,NULL,14,1,1,'删除仓库',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` LIKE 'warehouse:%';

-- ========== 三、菜单（仓储管理 -> 基础设置 -> 仓库管理） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '仓储管理', '', 'el-icon-s-shop', 'warehouse:module', 40, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0);

SET @warehouse_menu_id = (SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @warehouse_menu_id, '基础设置', '', 'el-icon-setting', 'warehouse:setting', 10, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:setting' AND deleted_at IS NULL AND parent_id=@warehouse_menu_id);

SET @setting_menu_id = (SELECT id FROM menus WHERE permission='warehouse:setting' AND deleted_at IS NULL AND parent_id=@warehouse_menu_id LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @setting_menu_id, '仓库管理', '/warehouse/setting/warehouse', 'el-icon-office-building', 'warehouse:setting:warehouse:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:setting:warehouse:view' AND deleted_at IS NULL AND parent_id=@setting_menu_id);
