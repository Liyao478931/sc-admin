-- 163_create_dispatch.sql
-- 工单派工（生产管理 -> 生产执行 -> 工单派工）：2 表 + 5 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='production:dispatch:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'production:dispatch:%');
--   DELETE FROM permissions WHERE code LIKE 'production:dispatch:%';
--   DROP TABLE IF EXISTS production_dispatch_task;
--   DROP TABLE IF EXISTS production_dispatch;

-- ========== 一、派工主表 ==========
CREATE TABLE IF NOT EXISTS `production_dispatch` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `dispatch_no` varchar(50) NOT NULL DEFAULT '' COMMENT '派工单编号 DP+YYYYMMDD+4位流水',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单ID',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号（冗余）',
  `dispatch_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '派工类型：1个人派工 2班组派工',
  `dispatcher_id` int(11) NOT NULL DEFAULT 0 COMMENT '派工人ID（车间主任/班组长）',
  `dispatcher_name` varchar(50) NOT NULL DEFAULT '' COMMENT '派工人姓名（冗余）',
  `dispatch_date` date DEFAULT NULL COMMENT '派工日期',
  `planned_start_date` date DEFAULT NULL COMMENT '计划开始日期',
  `planned_end_date` date DEFAULT NULL COMMENT '计划完成日期',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '派工状态：0草稿 1已派工 2执行中 3已完成 4已撤销',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dispatch_no` (`dispatch_no`),
  KEY `idx_dispatch_wo` (`work_order_id`),
  KEY `idx_dispatch_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工单派工主表';

-- ========== 二、派工任务明细表 ==========
CREATE TABLE IF NOT EXISTS `production_dispatch_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `dispatch_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联派工主表ID',
  `work_order_item_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单明细ID（工序任务）',
  `process_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工序ID',
  `process_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工序名称（冗余）',
  `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT '指定工位ID',
  `workstation_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工位名称（冗余）',
  `device_id` int(11) NOT NULL DEFAULT 0 COMMENT '指定设备ID',
  `device_name` varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）',
  `worker_id` int(11) NOT NULL DEFAULT 0 COMMENT '被派工人ID（个人派工）',
  `worker_name` varchar(50) NOT NULL DEFAULT '' COMMENT '被派工人姓名（冗余）',
  `team_id` int(11) NOT NULL DEFAULT 0 COMMENT '被派班组ID（班组派工）',
  `team_name` varchar(50) NOT NULL DEFAULT '' COMMENT '班组名称（冗余）',
  `planned_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '计划完成数量',
  `completed_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '已完成数量',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '任务状态：0待执行 1执行中 2已完成',
  `sort_order` int(11) NOT NULL DEFAULT 0 COMMENT '执行顺序',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_task_dispatch` (`dispatch_id`),
  KEY `idx_task_process` (`process_id`),
  KEY `idx_task_worker` (`worker_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='派工任务明细表';

-- ========== 三、权限（5 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工单派工','production:dispatch:view',2,0,'production','/production/execute/dispatch/list','el-icon-paperclip',NULL,239,1,1,'工单派工-查看（菜单）',NOW(),NOW()),
('新增派工','production:dispatch:add',2,0,'production',NULL,NULL,NULL,240,1,1,'新增派工',NOW(),NOW()),
('编辑派工','production:dispatch:edit',2,0,'production',NULL,NULL,NULL,241,1,1,'编辑派工',NOW(),NOW()),
('删除派工','production:dispatch:delete',2,0,'production',NULL,NULL,NULL,242,1,1,'删除派工',NOW(),NOW()),
('导出派工','production:dispatch:export',2,0,'production',NULL,NULL,NULL,243,1,1,'导出派工列表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'production:dispatch:%';

-- ========== 四、菜单：生产执行 -> 工单派工（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:execute' AND deleted_at IS NULL LIMIT 1), '工单派工', '/production/execute/dispatch/list', 'el-icon-paperclip', 'production:dispatch:view', 5, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:dispatch:view' AND deleted_at IS NULL);
