-- =====================================================
-- 053_risk_control.sql 管控措施模块（幂等可重复执行）
-- =====================================================
-- 一、管控措施表
CREATE TABLE IF NOT EXISTS `safety_risk_control` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `measure_code` varchar(50) NOT NULL COMMENT '措施编号 MC-YYYYMMDD-XXXX',
  `risk_id` int(11) NOT NULL COMMENT '风险ID',
  `measure_type` varchar(30) NOT NULL COMMENT '措施类型 engineering/management_control/personal_protection/emergency',
  `measure_content` text NOT NULL COMMENT '措施内容',
  `responsible_person_id` int(11) NOT NULL COMMENT '责任人ID',
  `responsible_person_name` varchar(50) NOT NULL COMMENT '责任人姓名(冗余)',
  `deadline` date NOT NULL COMMENT '完成期限',
  `implement_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '实施状态 pending/in_progress/completed/invalid',
  `verify_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '验证状态 pending/effective/ineffective',
  `implement_start_time` datetime DEFAULT NULL COMMENT '实施开始时间',
  `implement_complete_time` datetime DEFAULT NULL COMMENT '实施完成时间',
  `invalid_reason` varchar(500) DEFAULT NULL COMMENT '失效原因',
  `progress_remark` varchar(500) DEFAULT NULL COMMENT '进度备注',
  `verify_by` int(11) DEFAULT NULL COMMENT '验证人ID',
  `verify_by_name` varchar(50) DEFAULT NULL COMMENT '验证人姓名',
  `verify_time` datetime DEFAULT NULL COMMENT '验证时间',
  `verify_opinion` varchar(500) DEFAULT NULL COMMENT '验证意见',
  `remark` text DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_measure_code` (`measure_code`),
  KEY `idx_risk_id` (`risk_id`),
  KEY `idx_measure_type` (`measure_type`),
  KEY `idx_implement_status` (`implement_status`),
  KEY `idx_verify_status` (`verify_status`),
  KEY `idx_responsible_person_id` (`responsible_person_id`),
  KEY `idx_deadline` (`deadline`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='风险管控措施';

-- 二、数据字典
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('措施类型','control_measure_type','风险管控措施类型',101,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='control_measure_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'工程技术','engineering',1,'primary',1,NOW(),NOW()),
(@dt1,'管理控制','management_control',2,'success',1,NOW(),NOW()),
(@dt1,'个体防护','personal_protection',3,'warning',1,NOW(),NOW()),
(@dt1,'应急措施','emergency',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('实施状态','control_implement_status','管控措施实施状态',102,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='control_implement_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'待实施','pending',1,'info',1,NOW(),NOW()),
(@dt2,'实施中','in_progress',2,'primary',1,NOW(),NOW()),
(@dt2,'已完成','completed',3,'success',1,NOW(),NOW()),
(@dt2,'已失效','invalid',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('验证状态','control_verify_status','管控措施验证状态',103,1,NOW(),NOW());
SET @dt3=(SELECT id FROM dictionary_types WHERE code='control_verify_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt3,'待验证','pending',1,'warning',1,NOW(),NOW()),
(@dt3,'有效','effective',2,'success',1,NOW(),NOW()),
(@dt3,'无效','ineffective',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 三、系统参数
INSERT INTO `settings` (`key`,`value`,`created_at`,`updated_at`) VALUES
('control_measure_code_prefix','MC',NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('control_measure_code_prefix','MC','措施编号前缀','safety','string','措施编号前缀（MC-YYYYMMDD-XXXX）',84,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- 四、权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('管控措施列表','safety:risk:control:list',1,0,'风险管控','/safety/risk/control','el-icon-s-tools',136,1,1,'查看管控措施',NOW(),NOW()),
('措施详情查询','safety:risk:control:query',2,0,'风险管控','/safety/risk/control',NULL,137,1,1,'查询措施详情',NOW(),NOW()),
('措施新增','safety:risk:control:add',2,0,'风险管控','/safety/risk/control',NULL,138,1,1,'新增管控措施',NOW(),NOW()),
('措施编辑','safety:risk:control:edit',2,0,'风险管控','/safety/risk/control',NULL,139,1,1,'编辑管控措施',NOW(),NOW()),
('措施删除','safety:risk:control:delete',2,0,'风险管控','/safety/risk/control',NULL,140,1,1,'删除管控措施',NOW(),NOW()),
('措施验证','safety:risk:control:verify',2,0,'风险管控','/safety/risk/control',NULL,141,1,1,'验证管控措施',NOW(),NOW()),
('措施导出','safety:risk:control:export',2,0,'风险管控','/safety/risk/control',NULL,142,1,1,'导出管控措施',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'safety:risk:control:%';

-- 五、菜单：风险管控 → 管控措施
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'管控措施','/safety/risk/control','el-icon-s-tools','safety:risk:control:list',3,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:risk:identify:list' AND m.`path`='/safety/risk' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:risk:control:list' AND x.`deleted_at` IS NULL);
