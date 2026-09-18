-- =====================================================
-- 034_alter_safety_training_record.sql
-- 培训记录扫码签到增强：补充签到地点/时间/位置字段 + 系统参数
-- =====================================================

-- 培训记录表：补充签到时间/地点/经纬度/范围字段
ALTER TABLE `safety_training_record`
  ADD COLUMN `checkin_start_time` datetime     DEFAULT NULL COMMENT '签到开始时间' AFTER `training_end_time`,
  ADD COLUMN `checkin_end_time`   datetime     DEFAULT NULL COMMENT '签到结束时间' AFTER `checkin_start_time`,
  ADD COLUMN `checkin_location`   varchar(200) DEFAULT NULL COMMENT '签到地点名称' AFTER `checkin_end_time`,
  ADD COLUMN `checkin_lat`        decimal(10,7) DEFAULT NULL COMMENT '签到地点纬度' AFTER `checkin_location`,
  ADD COLUMN `checkin_lng`        decimal(10,7) DEFAULT NULL COMMENT '签到地点经度' AFTER `checkin_lat`,
  ADD COLUMN `checkin_radius`     int(11)      NOT NULL DEFAULT 100 COMMENT '签到范围（米）' AFTER `checkin_lng`;

-- 参训人员表：补充签到位置/偏差字段
ALTER TABLE `safety_training_attendee`
  ADD COLUMN `checkin_lat`       decimal(10,7) DEFAULT NULL COMMENT '实际签到纬度' AFTER `checkin_time`,
  ADD COLUMN `checkin_lng`       decimal(10,7) DEFAULT NULL COMMENT '实际签到经度' AFTER `checkin_lat`,
  ADD COLUMN `checkin_address`   varchar(255)  DEFAULT NULL COMMENT '实际签到地址' AFTER `checkin_lng`,
  ADD COLUMN `checkin_deviation` int(11)       DEFAULT NULL COMMENT '偏差距离（米）' AFTER `checkin_address`;

-- 系统参数：签到默认范围（米）
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('training_checkin_default_radius', '100', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('training_checkin_default_radius', '100', '签到默认范围（米）', 'safety', 'number', '培训扫码签到默认允许范围（米）', 56, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();
