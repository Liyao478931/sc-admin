-- 系统安装记录表
CREATE TABLE IF NOT EXISTS `system_install_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `install_time` datetime NOT NULL COMMENT '安装完成时间',
  `php_version` varchar(20) NOT NULL COMMENT 'PHP版本',
  `db_version` varchar(20) NOT NULL COMMENT '数据库版本',
  `admin_username` varchar(50) NOT NULL COMMENT '管理员用户名',
  `admin_email` varchar(100) NOT NULL COMMENT '管理员邮箱',
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统安装记录表';
