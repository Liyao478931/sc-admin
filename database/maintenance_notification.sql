-- ============================================================
-- 设备保养 · 通知推送功能 数据库脚本
-- 数据库：ly478931
-- ============================================================

-- 站内信通知表
DROP TABLE IF EXISTS `device_maintenance_notification`;
CREATE TABLE `device_maintenance_notification` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL COMMENT '接收人用户ID',
  `notify_type` varchar(30) NOT NULL COMMENT '类型 task_assign任务分配/remind到期提醒/overdue逾期/verify_result验收结果',
  `title` varchar(200) NOT NULL COMMENT '标题',
  `content` text NOT NULL COMMENT '内容',
  `task_id` int(11) unsigned DEFAULT NULL COMMENT '关联任务ID',
  `record_id` int(11) unsigned DEFAULT NULL COMMENT '关联记录ID',
  `is_read` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已读',
  `channel` varchar(30) NOT NULL DEFAULT 'inbox' COMMENT '渠道 inbox站内信/email邮件',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_is_read` (`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养通知表';
