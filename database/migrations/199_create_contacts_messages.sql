-- ============================================================
-- 通讯录消息表（员工间内部消息）
-- ============================================================
CREATE TABLE IF NOT EXISTS `contacts_messages` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `sender_id` int(11) unsigned NOT NULL COMMENT '发送者用户ID',
  `receiver_id` int(11) unsigned NOT NULL COMMENT '接收者用户ID',
  `content` text NOT NULL COMMENT '消息内容',
  `is_read` tinyint(1) NOT NULL DEFAULT 0 COMMENT '接收者是否已读：0否 1是',
  `created_at` datetime NOT NULL COMMENT '发送时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_sender_receiver_created` (`sender_id`, `receiver_id`, `created_at`),
  KEY `idx_receiver_created` (`receiver_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通讯录消息表';
