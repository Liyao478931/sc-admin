-- 172_create_proxy.sql
-- 统一审批「审批代理设置」：approval_proxy 表 + 权限 + 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/approval/proxy';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='approval:proxy:set');
--   DELETE FROM permissions WHERE code='approval:proxy:set';
--   DROP TABLE IF EXISTS approval_proxy;

-- ========== 一、审批代理记录表 ==========
CREATE TABLE IF NOT EXISTS `approval_proxy` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `proxy_no` varchar(50) NOT NULL DEFAULT '' COMMENT '代理编号 AP+YYYYMMDD+4位流水',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '被代理人ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '被代理人姓名（冗余）',
  `proxy_user_id` int(11) NOT NULL DEFAULT 0 COMMENT '代理人ID',
  `proxy_user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '代理人姓名（冗余）',
  `start_time` datetime DEFAULT NULL COMMENT '代理开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '代理结束时间',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0待生效 1生效中 2已过期 3已取消',
  `reason` varchar(200) DEFAULT NULL COMMENT '代理原因',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_proxy_no` (`proxy_no`),
  KEY `idx_user` (`user_id`),
  KEY `idx_proxy_user` (`proxy_user_id`),
  KEY `idx_time` (`start_time`, `end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批代理记录表';

-- ========== 二、权限（approval:proxy:set） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('审批代理设置','approval:proxy:set',2,0,'approval','/approval/proxy','el-icon-user',NULL,309,1,1,'审批代理设置（查看/新增/取消代理）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code`='approval:proxy:set';

-- ========== 三、菜单：统一审批 -> 审批代理设置（叶子，path 幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='approval:view' AND deleted_at IS NULL LIMIT 1), '审批代理设置', '/approval/proxy', 'el-icon-user', 'approval:proxy:set', 50, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/approval/proxy' AND deleted_at IS NULL);
