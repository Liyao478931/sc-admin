-- ============================================================
-- 设备保养 · 保养记录功能 数据库升级脚本
-- 在现有 device_maintenance_record 表基础上补齐需求字段
-- 数据库：ly478931
-- ============================================================

-- 新增字段（需求标准字段，兼容现有 status）
ALTER TABLE `device_maintenance_record`
  ADD COLUMN `plan_name` varchar(100) NOT NULL DEFAULT '' COMMENT '计划名称（冗余）' AFTER `plan_id`,
  ADD COLUMN `execute_time` datetime DEFAULT NULL COMMENT '执行时间' AFTER `remark`,
  ADD COLUMN `serious_count` int(11) NOT NULL DEFAULT 0 COMMENT '严重异常项数量' AFTER `abnormal_count`,
  ADD COLUMN `total_count` int(11) NOT NULL DEFAULT 0 COMMENT '总项目数量' AFTER `serious_count`,
  ADD COLUMN `accept_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '验收状态 pending待验收/approved已通过/rejected已驳回' AFTER `attachments`,
  ADD COLUMN `accept_time` datetime DEFAULT NULL COMMENT '验收时间' AFTER `accept_status`,
  ADD COLUMN `accept_remark` varchar(255) NOT NULL DEFAULT '' COMMENT '验收意见' AFTER `accept_time`,
  ADD COLUMN `reject_count` int(11) NOT NULL DEFAULT 0 COMMENT '驳回次数' AFTER `reject_reason`,
  ADD COLUMN `reject_history` json DEFAULT NULL COMMENT '驳回历史';

-- 同步现有 status 数据到 accept_status（历史兼容）
UPDATE `device_maintenance_record` SET `accept_status` = CASE
  WHEN `status` = 'passed' THEN 'approved'
  WHEN `status` = 'rejected' THEN 'rejected'
  ELSE 'pending'
END WHERE `accept_status` = 'pending';
