-- =====================================================
-- 035_alter_safety_training_online.sql
-- 培训记录线上线下差异化：record.is_online + attendee 培训完成字段 + 观看记录表 + 字典
-- =====================================================

-- 培训记录表：增加 is_online 字段 + 索引
ALTER TABLE `safety_training_record`
  ADD COLUMN `is_online` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否线上培训：1线上 0线下' AFTER `training_mode`,
  ADD INDEX `idx_is_online` (`is_online`);

-- 参训人员表：增加培训完成字段 + 索引
ALTER TABLE `safety_training_attendee`
  ADD COLUMN `is_trained` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已完成培训：1完成 0未完成（线上培训）' AFTER `position`,
  ADD COLUMN `watch_progress` int(11) NOT NULL DEFAULT 0 COMMENT '观看进度百分比（线上培训）' AFTER `checkin_deviation`,
  ADD COLUMN `complete_time` datetime DEFAULT NULL COMMENT '完成时间' AFTER `watch_progress`,
  ADD INDEX `idx_is_trained` (`is_trained`);

-- ========== 培训课件观看记录表 ==========
CREATE TABLE IF NOT EXISTS `safety_training_watch_log` (
  `id`               int(11) unsigned NOT NULL AUTO_INCREMENT,
  `record_id`        int(11)      NOT NULL COMMENT '培训记录ID',
  `user_id`          int(11)      NOT NULL COMMENT '用户ID',
  `courseware_id`    int(11)      NOT NULL COMMENT '课件ID',
  `watch_status`     varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '观看状态 pending/watching/completed',
  `watch_duration`   int(11)      NOT NULL DEFAULT 0 COMMENT '已观看时长（秒）',
  `total_duration`   int(11)      NOT NULL DEFAULT 0 COMMENT '总时长（秒）',
  `watch_percent`    int(11)      NOT NULL DEFAULT 0 COMMENT '观看百分比',
  `first_watch_time` datetime     DEFAULT NULL COMMENT '首次观看时间',
  `last_watch_time`  datetime     DEFAULT NULL COMMENT '最后观看时间',
  `create_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_record_id` (`record_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_courseware_id` (`courseware_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训课件观看记录';

-- ========== 数据字典：观看状态 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('课件观看状态','watch_status','培训课件观看状态',83,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='watch_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'未开始','pending',1,'info',1,NOW(),NOW()),
(@dt1,'观看中','watching',2,'warning',1,NOW(),NOW()),
(@dt1,'已完成','completed',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();
