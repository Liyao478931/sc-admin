-- =====================================================
-- 102_alter_attendance_points.sql
-- 打卡点管理增强：新增 department_ids（关联部门）、sort（排序）字段
-- 幂等写法：重复执行时 Duplicate column/key 会被迁移脚本忽略
-- =====================================================

ALTER TABLE `attendance_points`
  ADD COLUMN `department_ids` text DEFAULT NULL COMMENT '关联部门ID列表（JSON数组，空=全部部门）' AFTER `weekdays`,
  ADD COLUMN `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序（数字越小越靠前）' AFTER `status`;

ALTER TABLE `attendance_points`
  ADD KEY `idx_sort` (`sort`);
