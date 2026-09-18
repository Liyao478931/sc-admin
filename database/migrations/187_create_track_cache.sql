-- 187_create_track_cache.sql
-- 经营管理「物流跟踪」：1 表 + 3 权限 + 1 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:track:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:track:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:track:%';
--   DROP TABLE IF EXISTS logistics_track_cache;

-- ========== 一、物流轨迹缓存表 ==========
CREATE TABLE IF NOT EXISTS `logistics_track_cache` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ship_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联发货单ID',
  `tracking_no` varchar(100) NOT NULL DEFAULT '' COMMENT '物流单号（冗余便于查询）',
  `logistics_code` varchar(50) DEFAULT NULL COMMENT '物流公司编码（如 SF）',
  `track_data` json DEFAULT NULL COMMENT '完整物流节点列表（JSON）',
  `latest_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '最新物流状态：1已揽收 2运输中 3派送中 4已签收 5异常',
  `latest_context` varchar(500) DEFAULT NULL COMMENT '最新状态描述',
  `last_update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `next_update_strategy` varchar(50) DEFAULT NULL COMMENT '下次更新策略',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ship_order` (`ship_order_id`),
  KEY `idx_tracking_no` (`tracking_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='物流轨迹缓存表';

-- ========== 二、权限（3 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('物流跟踪','sales:track:view',2,0,'business','/business/sales/ship/track','el-icon-truck',NULL,290,1,1,'物流跟踪-查看（菜单）',NOW(),NOW()),
('刷新物流轨迹','sales:track:refresh',2,0,'business',NULL,NULL,NULL,291,1,1,'刷新物流轨迹（单个/批量）',NOW(),NOW()),
('导出物流跟踪','sales:track:export',2,0,'business',NULL,NULL,NULL,292,1,1,'导出物流跟踪列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:track:%';

-- ========== 三、菜单：发货管理（id=260）-> 物流跟踪（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 260, '物流跟踪', '/business/sales/ship/track', 'el-icon-truck', 'sales:track:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/ship/track' AND deleted_at IS NULL);
