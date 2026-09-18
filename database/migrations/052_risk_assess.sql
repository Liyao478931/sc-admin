-- =====================================================
-- 052_risk_assess.sql 风险评估模块（幂等可重复执行）
-- =====================================================
-- 一、风险主表新增评估字段（幂等）
SET @c = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_risk' AND column_name='l_score');
SET @s = IF(@c=0,
'ALTER TABLE `safety_risk`
  ADD COLUMN `l_score` decimal(3,1) DEFAULT NULL COMMENT ''可能性评分'' AFTER `control_effectiveness`,
  ADD COLUMN `e_score` decimal(3,1) DEFAULT NULL COMMENT ''暴露频率评分'' AFTER `l_score`,
  ADD COLUMN `c_score` decimal(5,1) DEFAULT NULL COMMENT ''后果严重性评分'' AFTER `e_score`,
  ADD COLUMN `d_score` decimal(5,1) DEFAULT NULL COMMENT ''风险值(LEC)'' AFTER `c_score`,
  ADD COLUMN `assessor_id` int(11) DEFAULT NULL COMMENT ''评估人ID'' AFTER `d_score`,
  ADD COLUMN `assessor_name` varchar(50) DEFAULT NULL COMMENT ''评估人姓名'' AFTER `assessor_id`,
  ADD COLUMN `assess_date` date DEFAULT NULL COMMENT ''评估日期'' AFTER `assessor_name`,
  ADD COLUMN `review_date` date DEFAULT NULL COMMENT ''下次复评日期'' AFTER `assess_date`',
'SET @skip=1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- 二、评估历史表
CREATE TABLE IF NOT EXISTS `safety_risk_assessment_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `risk_id` int(11) NOT NULL COMMENT '风险ID',
  `assessment_code` varchar(50) NOT NULL COMMENT '评估编号 RA-YYYYMMDD-XXXX',
  `l_score` decimal(3,1) NOT NULL COMMENT '可能性评分',
  `e_score` decimal(3,1) NOT NULL COMMENT '暴露频率评分',
  `c_score` decimal(5,1) NOT NULL COMMENT '后果严重性评分',
  `d_score` decimal(5,1) NOT NULL COMMENT '风险值',
  `risk_level` varchar(20) NOT NULL COMMENT '风险等级 low/general/major/critical',
  `assessor_id` int(11) NOT NULL COMMENT '评估人ID',
  `assessor_name` varchar(50) NOT NULL COMMENT '评估人姓名',
  `assess_date` date NOT NULL COMMENT '评估日期',
  `review_date` date DEFAULT NULL COMMENT '下次复评日期',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_assessment_code` (`assessment_code`),
  KEY `idx_risk_id` (`risk_id`),
  KEY `idx_assess_date` (`assess_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='风险评估历史';

-- 三、数据字典（LEC 评分）
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('L可能性评分','lec_l','LEC法可能性评分',98,1,NOW(),NOW());
SET @dl=(SELECT id FROM dictionary_types WHERE code='lec_l');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dl,'完全可以预料到','10',1,'danger',1,NOW(),NOW()),
(@dl,'相当可能','6',2,'warning',1,NOW(),NOW()),
(@dl,'可能但不经常','3',3,'warning',1,NOW(),NOW()),
(@dl,'可能性小完全意外','1',4,'primary',1,NOW(),NOW()),
(@dl,'很不可能可以设想','0.5',5,'info',1,NOW(),NOW()),
(@dl,'极不可能','0.2',6,'info',1,NOW(),NOW()),
(@dl,'实际不可能','0.1',7,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('E暴露频率评分','lec_e','LEC法暴露频率评分',99,1,NOW(),NOW());
SET @de=(SELECT id FROM dictionary_types WHERE code='lec_e');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@de,'连续暴露','10',1,'danger',1,NOW(),NOW()),
(@de,'每天工作时间内暴露','6',2,'warning',1,NOW(),NOW()),
(@de,'每周一次','3',3,'warning',1,NOW(),NOW()),
(@de,'每月一次','2',4,'primary',1,NOW(),NOW()),
(@de,'每年几次','1',5,'info',1,NOW(),NOW()),
(@de,'非常罕见','0.5',6,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('C后果严重性评分','lec_c','LEC法后果严重性评分',100,1,NOW(),NOW());
SET @dc=(SELECT id FROM dictionary_types WHERE code='lec_c');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dc,'大灾难许多人死亡','100',1,'danger',1,NOW(),NOW()),
(@dc,'灾难数人死亡','40',2,'danger',1,NOW(),NOW()),
(@dc,'非常严重一人死亡','15',3,'danger',1,NOW(),NOW()),
(@dc,'严重重伤','7',4,'warning',1,NOW(),NOW()),
(@dc,'重大致残','3',5,'warning',1,NOW(),NOW()),
(@dc,'轻伤','1',6,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 四、系统参数
INSERT INTO `settings` (`key`,`value`,`created_at`,`updated_at`) VALUES
('risk_assessment_code_prefix','RA',NOW(),NOW()),
('risk_review_months_low','12',NOW(),NOW()),
('risk_review_months_general','6',NOW(),NOW()),
('risk_review_months_major','3',NOW(),NOW()),
('risk_review_months_critical','1',NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('risk_assessment_code_prefix','RA','评估编号前缀','safety','string','评估编号前缀（RA-YYYYMMDD-XXXX）',79,0,1,NOW(),NOW()),
('risk_review_months_low','12','低风险复评月数','safety','number','低风险下次复评月数',80,0,1,NOW(),NOW()),
('risk_review_months_general','6','一般风险复评月数','safety','number','一般风险下次复评月数',81,0,1,NOW(),NOW()),
('risk_review_months_major','3','较大风险复评月数','safety','number','较大风险下次复评月数',82,0,1,NOW(),NOW()),
('risk_review_months_critical','1','重大风险复评月数','safety','number','重大风险下次复评月数',83,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- 五、权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('风险评估列表','safety:risk:assess:list',1,0,'风险管控','/safety/risk/assess','el-icon-s-data',132,1,1,'查看风险评估',NOW(),NOW()),
('评估详情查询','safety:risk:assess:query',2,0,'风险管控','/safety/risk/assess',NULL,133,1,1,'查询评估详情与历史',NOW(),NOW()),
('评估新增','safety:risk:assess:add',2,0,'风险管控','/safety/risk/assess',NULL,134,1,1,'提交风险评估',NOW(),NOW()),
('评估导出','safety:risk:assess:export',2,0,'风险管控','/safety/risk/assess',NULL,135,1,1,'导出待评估风险',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'safety:risk:assess:%';

-- 六、菜单：风险管控 → 风险评估
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'风险评估','/safety/risk/assess','el-icon-s-data','safety:risk:assess:list',2,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:risk:identify:list' AND m.`path`='/safety/risk' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:risk:assess:list' AND x.`deleted_at` IS NULL);
