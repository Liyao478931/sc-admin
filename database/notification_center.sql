-- =====================================================
-- notification_center.sql
-- 消息通知中心：建表 + 字典 + 系统参数 + 权限菜单（幂等）
-- 执行方式：面板【数据库】→ ly478931 → 管理 → 导入 该文件
-- 说明：本文件不含任何凭据
-- =====================================================

-- ---------- 1. 建表 system_notification ----------
CREATE TABLE IF NOT EXISTS `system_notification` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `msg_id` varchar(32) NOT NULL COMMENT '消息唯一标识',
  `to_user_id` int(11) NOT NULL COMMENT '接收人ID',
  `from_user_id` int(11) NOT NULL DEFAULT 0 COMMENT '发送人ID(0=系统)',
  `msg_type` tinyint(4) NOT NULL DEFAULT 1 COMMENT '1系统公告 2任务指派 3审批通知 4预警提醒 5培训通知 6工单通知',
  `title` varchar(200) NOT NULL COMMENT '消息标题',
  `content` text NOT NULL COMMENT '消息内容(支持HTML)',
  `link_url` varchar(500) DEFAULT NULL COMMENT '跳转链接',
  `link_text` varchar(50) DEFAULT NULL COMMENT '链接文字',
  `attachments` json DEFAULT NULL COMMENT '附件列表',
  `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '0未读 1已读 2已删除',
  `read_at` datetime DEFAULT NULL COMMENT '阅读时间',
  `send_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `is_top` tinyint(4) NOT NULL DEFAULT 0 COMMENT '是否置顶',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_msg_id` (`msg_id`),
  KEY `idx_user_status_time` (`to_user_id`,`status`,`send_time`),
  KEY `idx_send_time` (`send_time`),
  KEY `idx_msg_type` (`msg_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统消息通知';

-- ---------- 2. 数据字典：消息类型（独立字典，避免污染现有"通知发送方式"） ----------
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('消息类型','notification_msg_type','系统消息类型（通知中心）',46,1,NOW(),NOW());

SET @nty = (SELECT `id` FROM `dictionary_types` WHERE `code`='notification_msg_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@nty,'系统公告','system',1,'info',1,NOW(),NOW()),
(@nty,'任务指派','task',2,'primary',1,NOW(),NOW()),
(@nty,'审批通知','approval',3,'warning',1,NOW(),NOW()),
(@nty,'预警提醒','alert',4,'danger',1,NOW(),NOW()),
(@nty,'培训通知','training',5,'success',1,NOW(),NOW()),
(@nty,'工单通知','order',6,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ---------- 3. 系统参数 ----------
INSERT IGNORE INTO `system_params` (`param_key`,`param_value`,`name`,`param_group`,`param_type`) VALUES
('notification_unread_polling_interval','5','未读数轮询间隔(秒)','notification','number'),
('notification_retention_days','90','消息保留天数','notification','number');

-- ---------- 4. 权限与菜单 ----------
INSERT INTO `permissions`
(`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
VALUES ('消息列表查看','notification:list',1,0,'系统管理','/system/notification/messages','el-icon-message',140,1,1,'查看消息列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`module`=VALUES(`module`),`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='notification:list';

-- 消息通知目录（挂"系统管理"下，找不到则顶级）
SET @sys_menu = (SELECT `id` FROM `menus` WHERE `name`='系统管理' AND `deleted_at` IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT COALESCE(@sys_menu,0),'消息通知','','el-icon-message','',50,1,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `name`='消息通知' AND `deleted_at` IS NULL);

SET @ntf_dir = (SELECT `id` FROM `menus` WHERE `name`='消息通知' AND `deleted_at` IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ntf_dir,'消息列表','/system/notification/messages','el-icon-message','notification:list',1,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='notification:list' AND `deleted_at` IS NULL);
