-- ============================================================
-- 系统更新历史表（apply 写更新记录依赖）
-- 历史环境缺失该表会导致系统更新报"服务器内部错误"。
-- CREATE TABLE IF NOT EXISTS 幂等。
-- ============================================================

CREATE TABLE IF NOT EXISTS `system_updates` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `version_no` varchar(32) NOT NULL COMMENT '版本号',
  `title` varchar(128) NOT NULL DEFAULT '' COMMENT '标题',
  `changelog` text COMMENT '更新日志',
  `force_update` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否强制',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0待更新 1已更新 2失败 3已回滚',
  `applied_at` datetime DEFAULT NULL COMMENT '更新时间',
  `rollback_at` datetime DEFAULT NULL COMMENT '回滚时间',
  `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统更新历史';