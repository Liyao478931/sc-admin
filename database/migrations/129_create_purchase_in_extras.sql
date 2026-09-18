-- 129_create_purchase_in_extras.sql
-- 采购入库补充：入库冲销日志表 + 入库单附件表 + 权限（reverse / attachment:upload / attachment:delete）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN
--     ('warehouse:purchase:in:reverse','warehouse:purchase:in:attachment:upload','warehouse:purchase:in:attachment:delete'));
--   DELETE FROM permissions WHERE code IN
--     ('warehouse:purchase:in:reverse','warehouse:purchase:in:attachment:upload','warehouse:purchase:in:attachment:delete');
--   DROP TABLE IF EXISTS warehouse_in_attachment;
--   DROP TABLE IF EXISTS warehouse_reverse_log;

CREATE TABLE IF NOT EXISTS `warehouse_reverse_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `in_no` varchar(30) NOT NULL DEFAULT '' COMMENT '入库单编号（冗余）',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `reverse_time` datetime DEFAULT NULL COMMENT '冲销时间',
  `reason` varchar(500) DEFAULT NULL COMMENT '冲销原因',
  `snapshot` json DEFAULT NULL COMMENT '冲销前数据快照',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_in_id` (`in_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='入库冲销日志表';

CREATE TABLE IF NOT EXISTS `warehouse_in_attachment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `in_id` int(11) NOT NULL DEFAULT 0 COMMENT '入库单ID',
  `file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '文件名',
  `file_path` varchar(500) NOT NULL DEFAULT '' COMMENT '文件路径',
  `file_size` int(11) NOT NULL DEFAULT 0 COMMENT '文件大小（字节）',
  `file_type` varchar(50) NOT NULL DEFAULT '' COMMENT '文件类型（扩展名）',
  `uploader_id` int(11) NOT NULL DEFAULT 0 COMMENT '上传人ID',
  `uploader_name` varchar(50) NOT NULL DEFAULT '' COMMENT '上传人姓名',
  `upload_time` datetime DEFAULT NULL COMMENT '上传时间',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_in_id` (`in_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='入库单附件表';

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('采购入库冲销','warehouse:purchase:in:reverse',2,0,'warehouse',NULL,NULL,NULL,41,1,1,'冲销/撤回入库',NOW(),NOW()),
('入库单附件上传','warehouse:purchase:in:attachment:upload',2,0,'warehouse',NULL,NULL,NULL,42,1,1,'上传入库单附件',NOW(),NOW()),
('入库单附件删除','warehouse:purchase:in:attachment:delete',2,0,'warehouse',NULL,NULL,NULL,43,1,1,'删除入库单附件',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('warehouse:purchase:in:reverse','warehouse:purchase:in:attachment:upload','warehouse:purchase:in:attachment:delete');
