-- 164_create_schedule.sql
-- 生产排程（生产管理 -> 生产计划 -> 生产排程）：1 表 + 3 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='production:schedule:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'production:schedule:%');
--   DELETE FROM permissions WHERE code LIKE 'production:schedule:%';
--   DROP TABLE IF EXISTS production_schedule;

-- ========== 一、排程记录表 ==========
CREATE TABLE IF NOT EXISTS `production_schedule` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `dispatch_task_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联派工任务明细ID',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单ID',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号（冗余）',
  `process_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工序ID',
  `process_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工序名称（冗余）',
  `workstation_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工位ID',
  `workstation_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工位名称（冗余）',
  `device_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联设备ID',
  `device_name` varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）',
  `planned_start_time` datetime DEFAULT NULL COMMENT '计划开始时间',
  `planned_end_time` datetime DEFAULT NULL COMMENT '计划结束时间',
  `actual_start_time` datetime DEFAULT NULL COMMENT '实际开始时间（报工后回写）',
  `actual_end_time` datetime DEFAULT NULL COMMENT '实际结束时间（报工后回写）',
  `duration_hours` decimal(6,1) NOT NULL DEFAULT 0 COMMENT '计划工时（小时）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '排程状态：0未排程 1已排程 2执行中 3已完成',
  `sort_order` int(11) NOT NULL DEFAULT 0 COMMENT '同一工位上的执行顺序',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_schedule_task` (`dispatch_task_id`),
  KEY `idx_schedule_wo` (`work_order_id`),
  KEY `idx_schedule_ws` (`workstation_id`),
  KEY `idx_schedule_status` (`status`),
  KEY `idx_schedule_time` (`planned_start_time`,`planned_end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='生产排程记录表';

-- ========== 二、权限（3 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('生产排程','production:schedule:view',2,0,'production','/production/plan/schedule','el-icon-date',NULL,244,1,1,'生产排程-查看（菜单）',NOW(),NOW()),
('编辑排程','production:schedule:edit',2,0,'production',NULL,NULL,NULL,245,1,1,'编辑排程（拖拽/自动/确认）',NOW(),NOW()),
('导出排程','production:schedule:export',2,0,'production',NULL,NULL,NULL,246,1,1,'导出排程',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'production:schedule:%';

-- ========== 三、菜单：生产计划 -> 生产排程（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:plan' AND deleted_at IS NULL LIMIT 1), '生产排程', '/production/plan/schedule', 'el-icon-date', 'production:schedule:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:schedule:view' AND deleted_at IS NULL);
