-- 122_create_warehouse_location.sql
-- 仓储管理 -> 基础设置 -> 货位管理（依赖仓库档案 warehouse 表）
-- 1. 建表：warehouse_location（货位表）
-- 2. 权限：warehouse:setting:location:view/add/edit/delete（4条）并授权 super_admin
-- 3. 菜单：仓储管理 -> 基础设置 -> 货位管理
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:setting:location:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:setting:location:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:setting:location:%';
--   DROP TABLE IF EXISTS warehouse_location;

-- ========== 一、建表 ==========
CREATE TABLE IF NOT EXISTS `warehouse_location` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `warehouse_id` int(11) NOT NULL DEFAULT 0 COMMENT '仓库ID',
  `location_code` varchar(50) NOT NULL DEFAULT '' COMMENT '货位编码 WH001-A-01（同一仓库内唯一）',
  `location_name` varchar(100) NOT NULL DEFAULT '' COMMENT '货位名称',
  `location_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '货位类型：1普通货位 2货架 3堆场 4托盘位',
  `area` varchar(30) DEFAULT NULL COMMENT '区域（A区/B区/C区）',
  `capacity` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '承载能力（kg）',
  `occupancy_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '占用状态：0空闲 1部分占用 2已满（系统自动维护）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_warehouse_id` (`warehouse_id`),
  KEY `idx_type` (`location_type`),
  KEY `idx_occupancy` (`occupancy_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='货位表';

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('货位查看','warehouse:setting:location:view',2,0,'warehouse','/warehouse/setting/location','el-icon-map-location',NULL,15,1,1,'货位管理-查看（菜单）',NOW(),NOW()),
('货位新增','warehouse:setting:location:add',2,0,'warehouse',NULL,NULL,NULL,16,1,1,'新增货位',NOW(),NOW()),
('货位编辑','warehouse:setting:location:edit',2,0,'warehouse',NULL,NULL,NULL,17,1,1,'编辑货位',NOW(),NOW()),
('货位删除','warehouse:setting:location:delete',2,0,'warehouse',NULL,NULL,NULL,18,1,1,'删除货位',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` LIKE 'warehouse:setting:location:%';

-- ========== 三、菜单（基础设置 -> 货位管理） ==========
SET @setting_menu_id = (SELECT id FROM menus WHERE permission='warehouse:setting' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @setting_menu_id, '货位管理', '/warehouse/setting/location', 'el-icon-map-location', 'warehouse:setting:location:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:setting:location:view' AND deleted_at IS NULL AND parent_id=@setting_menu_id);
