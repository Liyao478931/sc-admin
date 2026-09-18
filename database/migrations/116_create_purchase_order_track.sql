-- 116_create_purchase_order_track.sql
-- 经营管理 -> 采购管理 -> 采购订单跟踪
-- 1. 建表：business_purchase_order_logistics（物流跟踪）/ business_purchase_order_reminder（催货记录）
-- 2. 权限：business:purchase:order:track:view / export / remind 并授权 super_admin
-- 3. 菜单：经营管理 -> 采购管理 -> 采购订单跟踪
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='business:purchase:order:track:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:purchase:order:track:%');
--   DELETE FROM permissions WHERE code LIKE 'business:purchase:order:track:%';
--   DROP TABLE IF EXISTS business_purchase_order_reminder;
--   DROP TABLE IF EXISTS business_purchase_order_logistics;

-- ========== 一、采购订单物流跟踪表 ==========
CREATE TABLE IF NOT EXISTS `business_purchase_order_logistics` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '采购订单ID',
  `track_no` varchar(60) NOT NULL DEFAULT '' COMMENT '快递单号',
  `express_code` varchar(30) NOT NULL DEFAULT '' COMMENT '快递公司编码（标准码）',
  `express_name` varchar(50) NOT NULL DEFAULT '' COMMENT '快递公司名称',
  `logistics_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '物流状态：0未发货 1已揽收 2运输中 3派送中 4已签收 5异常',
  `logistics_status_label` varchar(50) NOT NULL DEFAULT '' COMMENT '物流状态标签',
  `traces` text COMMENT '物流轨迹数据（JSON数组，完整时间轴）',
  `ship_date` date DEFAULT NULL COMMENT '发货日期',
  `predict_date` date DEFAULT NULL COMMENT '预计送达日期',
  `signed_date` date DEFAULT NULL COMMENT '实际签收日期',
  `express_phone` varchar(50) DEFAULT NULL COMMENT '物流公司客服电话',
  `error_reason` varchar(255) DEFAULT NULL COMMENT '异常原因',
  `last_update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_track_no` (`track_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购订单物流跟踪表';

-- ========== 二、采购订单催货记录表 ==========
CREATE TABLE IF NOT EXISTS `business_purchase_order_reminder` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '采购订单ID',
  `remind_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '催货类型：1电话催货 2邮件催货 3系统自动提醒',
  `content` varchar(500) NOT NULL DEFAULT '' COMMENT '催货内容',
  `contact` varchar(50) DEFAULT NULL COMMENT '联系人',
  `contact_way` varchar(100) DEFAULT NULL COMMENT '联系方式',
  `reminder` varchar(50) NOT NULL DEFAULT '' COMMENT '催货人',
  `remind_time` datetime DEFAULT NULL COMMENT '催货时间',
  `is_replied` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已回复：0否 1是',
  `reply_content` varchar(500) DEFAULT NULL COMMENT '回复内容',
  `reply_time` datetime DEFAULT NULL COMMENT '回复时间',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='采购订单催货记录表';

-- ========== 三、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('采购订单跟踪','business:purchase:order:track:view',1,0,'business','/business/purchase/order/track','el-icon-monitor',NULL,56,1,1,'采购订单跟踪-查看（菜单）',NOW(),NOW()),
('采购订单跟踪导出','business:purchase:order:track:export',2,0,'business',NULL,NULL,NULL,57,1,1,'导出跟踪报表',NOW(),NOW()),
('采购订单跟踪催货','business:purchase:order:track:remind',2,0,'business',NULL,NULL,NULL,58,1,1,'催货操作',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:purchase:order:track:view','business:purchase:order:track:export','business:purchase:order:track:remind');

-- ========== 四、菜单（经营管理 -> 采购管理 -> 采购订单跟踪） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);
SET @purchase_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='采购管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @purchase_menu_id, '采购订单跟踪', '/business/purchase/order/track', 'el-icon-monitor', 'business:purchase:order:track:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:order:track:view' AND deleted_at IS NULL AND type=2);
