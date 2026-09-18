-- =============================================
-- 997_create_user_login_devices_table.sql
-- 登录设备记录表（database.sql 快照缺失，补齐）
-- 幂等：IF NOT EXISTS，不 DROP
-- =============================================
CREATE TABLE IF NOT EXISTS `user_login_devices` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `device_key` varchar(64) NOT NULL DEFAULT '',
  `jti` varchar(64) DEFAULT NULL,
  `device_name` varchar(100) NOT NULL DEFAULT '',
  `os` varchar(50) NOT NULL DEFAULT '',
  `browser` varchar(80) NOT NULL DEFAULT '',
  `ip` varchar(45) NOT NULL DEFAULT '',
  `location` varchar(100) NOT NULL DEFAULT '',
  `login_type` varchar(20) NOT NULL DEFAULT 'mobile',
  `login_time` datetime DEFAULT NULL,
  `last_active_time` datetime DEFAULT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`,`status`),
  KEY `idx_device` (`device_key`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4;
