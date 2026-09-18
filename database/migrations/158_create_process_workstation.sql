-- 158_create_process_workstation.sql
-- 工序管理 + 工位管理（生产管理 -> 基础设置 -> 工序管理/工位管理）：4 表 + 预置工序 + 10 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('production:process:view','production:workstation:view','production:setting');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'production:process:%' OR code LIKE 'production:workstation:%');
--   DELETE FROM permissions WHERE code LIKE 'production:process:%' OR code LIKE 'production:workstation:%';
--   DROP TABLE IF EXISTS production_workstation_staff;
--   DROP TABLE IF EXISTS production_workstation_device;
--   DROP TABLE IF EXISTS production_workstation;
--   DROP TABLE IF EXISTS production_process;

-- ========== 一、工序表 ==========
CREATE TABLE IF NOT EXISTS `production_process` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `process_code` varchar(50) NOT NULL DEFAULT '' COMMENT '工序编码（唯一）',
  `process_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工序名称',
  `process_group` varchar(50) NOT NULL DEFAULT '' COMMENT '工序组',
  `product_type` varchar(50) NOT NULL DEFAULT '' COMMENT '适用产品类型',
  `sort_order` int(11) NOT NULL DEFAULT 0 COMMENT '工序执行顺序',
  `is_required` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否必须工序：1是 0否',
  `standard_score` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工分定额',
  `standard_hours` decimal(6,2) NOT NULL DEFAULT 0 COMMENT '标准工时（小时）',
  `description` varchar(500) DEFAULT NULL COMMENT '工序描述',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_process_code` (`process_code`),
  KEY `idx_group` (`process_group`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工序表';

-- ========== 二、工位表 ==========
CREATE TABLE IF NOT EXISTS `production_workstation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `workstation_code` varchar(50) NOT NULL DEFAULT '' COMMENT '工位编码（唯一）',
  `workstation_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工位名称',
  `workstation_type` tinyint(1) NOT NULL DEFAULT 10 COMMENT '工位类型：1拆解 2清洗 3检测 4电镀 5加工 6组装 7测试 8喷漆 9质检 10其他',
  `workshop` varchar(50) NOT NULL DEFAULT '' COMMENT '所属车间',
  `responsible_person_id` int(11) NOT NULL DEFAULT 0 COMMENT '负责人ID',
  `responsible_person_name` varchar(50) NOT NULL DEFAULT '' COMMENT '负责人姓名（冗余）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `current_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '占用状态：0空闲 1占用中 2维护中',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ws_code` (`workstation_code`),
  KEY `idx_ws_type` (`workstation_type`),
  KEY `idx_ws_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工位表';

-- ========== 三、工位设备关联表 ==========
CREATE TABLE IF NOT EXISTS `production_workstation_device` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT '工位ID',
  `device_id` int(11) NOT NULL DEFAULT 0 COMMENT '设备ID（device_assets）',
  `device_code` varchar(50) NOT NULL DEFAULT '' COMMENT '设备编码（冗余）',
  `device_name` varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）',
  `device_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '设备规格型号（冗余）',
  `is_primary` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否主设备：1是 0否',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_wsd_ws` (`workstation_id`),
  KEY `idx_wsd_device` (`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工位设备关联表';

-- ========== 四、工位员工关联表 ==========
CREATE TABLE IF NOT EXISTS `production_workstation_staff` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT '工位ID',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '员工ID（users）',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '员工姓名（冗余）',
  `role_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '角色类型：1主操作员 2副操作员 3辅助人员',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_wss_ws` (`workstation_id`),
  KEY `idx_wss_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工位员工关联表';

-- ========== 五、预置油缸立柱标准工序（幂等） ==========
INSERT INTO `production_process` (`process_code`,`process_name`,`process_group`,`product_type`,`sort_order`,`is_required`,`standard_score`,`standard_hours`,`description`,`status`,`remark`,`creator`,`created_at`,`updated_at`) VALUES
('PRC-001','拆解','拆解工序','油缸、立柱',1,1,8.00,1.50,'整机拆解为零部件',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-002','清洗','清洗工序','油缸、立柱',2,1,4.00,0.50,'零部件清洗除垢',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-003','检测/探伤','检测工序','油缸、立柱',3,1,6.00,1.00,'尺寸检测与探伤',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-004','电镀/修复','电镀工序','油缸、立柱',4,0,15.00,2.00,'电镀或表面修复',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-005','精加工','加工工序','油缸、立柱',5,0,12.00,2.00,'车磨精加工',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-006','组装','组装工序','油缸、立柱',6,1,10.00,1.50,'零部件组装',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-007','试压测试','测试工序','油缸、立柱',7,1,6.00,0.50,'耐压与性能测试',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-008','喷漆','喷漆工序','油缸、立柱',8,0,5.00,0.50,'表面喷漆防护',1,'油缸立柱维修标准工序',0,NOW(),NOW()),
('PRC-009','质检','质检工序','油缸、立柱',9,1,4.00,0.50,'出厂质量检验',1,'油缸立柱维修标准工序',0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `process_name`=VALUES(`process_name`),`process_group`=VALUES(`process_group`),
`product_type`=VALUES(`product_type`),`sort_order`=VALUES(`sort_order`),`is_required`=VALUES(`is_required`),
`standard_score`=VALUES(`standard_score`),`standard_hours`=VALUES(`standard_hours`),`status`=VALUES(`status`),`updated_at`=NOW();

-- ========== 六、权限（10 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工序管理','production:process:view',2,0,'production','/production/setting/process','el-icon-set-up',NULL,227,1,1,'工序管理-查看（菜单）',NOW(),NOW()),
('新增工序','production:process:add',2,0,'production',NULL,NULL,NULL,228,1,1,'新增工序',NOW(),NOW()),
('编辑工序','production:process:edit',2,0,'production',NULL,NULL,NULL,229,1,1,'编辑工序',NOW(),NOW()),
('删除工序','production:process:delete',2,0,'production',NULL,NULL,NULL,230,1,1,'删除工序',NOW(),NOW()),
('工位管理','production:workstation:view',2,0,'production','/production/setting/workstation','el-icon-office-building',NULL,231,1,1,'工位管理-查看（菜单）',NOW(),NOW()),
('新增工位','production:workstation:add',2,0,'production',NULL,NULL,NULL,232,1,1,'新增工位',NOW(),NOW()),
('编辑工位','production:workstation:edit',2,0,'production',NULL,NULL,NULL,233,1,1,'编辑工位',NOW(),NOW()),
('删除工位','production:workstation:delete',2,0,'production',NULL,NULL,NULL,234,1,1,'删除工位',NOW(),NOW()),
('工位设备管理','production:workstation:device:manage',2,0,'production',NULL,NULL,NULL,235,1,1,'管理工位关联设备',NOW(),NOW()),
('工位员工管理','production:workstation:staff:manage',2,0,'production',NULL,NULL,NULL,236,1,1,'管理工位关联员工',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND (p.`code` LIKE 'production:process:%' OR p.`code` LIKE 'production:workstation:%');

-- ========== 七、菜单链：生产管理 -> 基础设置 -> 工序管理/工位管理 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:view' AND deleted_at IS NULL LIMIT 1), '基础设置', '', 'el-icon-setting', 'production:setting', 5, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:setting' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:setting' AND deleted_at IS NULL LIMIT 1), '工序管理', '/production/setting/process', 'el-icon-set-up', 'production:process:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:process:view' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:setting' AND deleted_at IS NULL LIMIT 1), '工位管理', '/production/setting/workstation', 'el-icon-office-building', 'production:workstation:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:workstation:view' AND deleted_at IS NULL);
