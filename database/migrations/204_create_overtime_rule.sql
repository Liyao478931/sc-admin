-- 204_create_overtime_rule.sql
-- 加班规则灵活配置（工资配置 -> 基本设置 -> 加班规则配置）
-- 2 张表：overtime_rule_config（规则）、holiday_config（节假日）
-- 优先级：特殊规则 > 节假日 > 默认规则
-- 幂等写法，可重复执行
-- 回滚 down：
--   DROP TABLE IF EXISTS holiday_config;
--   DROP TABLE IF EXISTS overtime_rule_config;

-- ========== 一、加班规则配置表 ==========
CREATE TABLE IF NOT EXISTS `overtime_rule_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule_name` varchar(50) NOT NULL DEFAULT '' COMMENT '规则名称',
  `rule_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=默认规则 2=节假日规则 3=特殊规则',
  `week_day` tinyint(1) NOT NULL DEFAULT 0 COMMENT '适用星期（1-7，0=全部）',
  `date_type` varchar(20) NOT NULL DEFAULT 'workday' COMMENT '日期类型：workday/weekend/holiday/special',
  `multiplier` decimal(3,1) NOT NULL DEFAULT 1.5 COMMENT '加班倍数',
  `priority` tinyint(1) NOT NULL DEFAULT 1 COMMENT '优先级（数字越大越优先）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_type` (`rule_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='加班规则配置表';

-- ========== 二、节假日配置表 ==========
CREATE TABLE IF NOT EXISTS `holiday_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `holiday_date` date NOT NULL COMMENT '日期',
  `holiday_name` varchar(50) NOT NULL DEFAULT '' COMMENT '节假日名称',
  `holiday_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=法定节假日 2=调休日 3=公司特殊日',
  `multiplier` decimal(3,1) NOT NULL DEFAULT 3.0 COMMENT '加班倍数',
  `year` int(11) NOT NULL COMMENT '年份',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_holiday_date` (`holiday_date`),
  KEY `idx_year` (`year`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='节假日配置表';

-- ========== 三、默认规则数据 ==========
INSERT INTO `overtime_rule_config` (`rule_name`,`rule_type`,`week_day`,`date_type`,`multiplier`,`priority`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('工作日加班',1,0,'workday',1.5,1,1,'周一至周五加班默认倍数',NOW(),NOW()),
('休息日加班',1,0,'weekend',2.0,1,1,'周六周日加班默认倍数',NOW(),NOW()),
('法定节假日加班',1,0,'holiday',3.0,1,1,'法定节假日默认倍数',NOW(),NOW())
ON DUPLICATE KEY UPDATE `multiplier`=VALUES(`multiplier`),`updated_at`=NOW();
