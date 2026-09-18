-- =====================================================
-- 051_risk_identify.sql 风险辨识模块（幂等可重复执行）
-- =====================================================
-- 一、风险表
CREATE TABLE IF NOT EXISTS `safety_risk` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `risk_code` varchar(50) NOT NULL COMMENT '风险编号 R-YYYYMMDD-XXXX',
  `risk_name` varchar(200) NOT NULL COMMENT '风险名称',
  `risk_type` varchar(30) NOT NULL COMMENT '风险类型 physical/chemical/biological/ergonomic/management/other',
  `risk_level` varchar(20) NOT NULL DEFAULT 'low' COMMENT '风险等级 low/general/major/critical',
  `area` varchar(200) NOT NULL COMMENT '所属区域',
  `department_id` int(11) DEFAULT NULL COMMENT '所属部门ID',
  `department_name` varchar(100) DEFAULT NULL COMMENT '所属部门名称(冗余)',
  `responsible_person_id` int(11) DEFAULT NULL COMMENT '责任人ID',
  `responsible_person_name` varchar(50) DEFAULT NULL COMMENT '责任人姓名(冗余)',
  `hazard_source` text NOT NULL COMMENT '危险源描述',
  `consequence` text NOT NULL COMMENT '可能导致的后果',
  `impact_scope` varchar(500) DEFAULT NULL COMMENT '影响范围',
  `current_controls` text DEFAULT NULL COMMENT '现有控制措施',
  `control_effectiveness` varchar(20) DEFAULT NULL COMMENT '控制措施有效性 effective/partial/ineffective',
  `identifier_id` int(11) NOT NULL COMMENT '辨识人ID',
  `identifier_name` varchar(50) NOT NULL COMMENT '辨识人姓名',
  `identify_date` date NOT NULL COMMENT '辨识日期',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态 pending/assessed/controlled',
  `attachments` json DEFAULT NULL COMMENT '附件列表',
  `remark` text DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_risk_code` (`risk_code`),
  KEY `idx_risk_type` (`risk_type`),
  KEY `idx_risk_level` (`risk_level`),
  KEY `idx_status` (`status`),
  KEY `idx_identify_date` (`identify_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='风险辨识';

-- 二、数据字典
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('风险类型','safety_risk_type','风险辨识风险类型',95,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='safety_risk_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'物理风险','physical',1,'primary',1,NOW(),NOW()),
(@dt1,'化学风险','chemical',2,'warning',1,NOW(),NOW()),
(@dt1,'生物风险','biological',3,'success',1,NOW(),NOW()),
(@dt1,'人机工程风险','ergonomic',4,'info',1,NOW(),NOW()),
(@dt1,'管理风险','management',5,'warning',1,NOW(),NOW()),
(@dt1,'其他','other',6,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('风险等级','safety_risk_level','风险辨识风险等级',96,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='safety_risk_level');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'低风险','low',1,'success',1,NOW(),NOW()),
(@dt2,'一般风险','general',2,'primary',1,NOW(),NOW()),
(@dt2,'较大风险','major',3,'warning',1,NOW(),NOW()),
(@dt2,'重大风险','critical',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('风险状态','safety_risk_status','风险辨识风险状态',97,1,NOW(),NOW());
SET @dt3=(SELECT id FROM dictionary_types WHERE code='safety_risk_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt3,'待评估','pending',1,'warning',1,NOW(),NOW()),
(@dt3,'已评估','assessed',2,'success',1,NOW(),NOW()),
(@dt3,'已管控','controlled',3,'primary',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 三、系统参数
INSERT INTO `settings` (`key`,`value`,`created_at`,`updated_at`) VALUES
('risk_code_prefix','R',NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('risk_code_prefix','R','风险编号前缀','safety','string','风险编号前缀（R-YYYYMMDD-XXXX）',78,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- 四、权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('风险辨识列表','safety:risk:identify:list',1,0,'风险管控','/safety/risk/identify','el-icon-search',126,1,1,'查看风险辨识',NOW(),NOW()),
('风险详情查询','safety:risk:identify:query',2,0,'风险管控','/safety/risk/identify',NULL,127,1,1,'查询风险详情',NOW(),NOW()),
('风险新增','safety:risk:identify:add',2,0,'风险管控','/safety/risk/identify',NULL,128,1,1,'新增风险',NOW(),NOW()),
('风险编辑','safety:risk:identify:edit',2,0,'风险管控','/safety/risk/identify',NULL,129,1,1,'编辑风险',NOW(),NOW()),
('风险删除','safety:risk:identify:delete',2,0,'风险管控','/safety/risk/identify',NULL,130,1,1,'删除风险',NOW(),NOW()),
('风险导出','safety:risk:identify:export',2,0,'风险管控','/safety/risk/identify',NULL,131,1,1,'导出风险',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'safety:risk:identify:%';

-- 五、菜单：安全管理 → 风险管控 → 风险辨识
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'风险管控','/safety/risk','el-icon-search','safety:risk:identify:list',7,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:risk:identify:list' AND x.`path`='/safety/risk' AND x.`deleted_at` IS NULL);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'风险辨识','/safety/risk/identify','el-icon-search','safety:risk:identify:list',1,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:risk:identify:list' AND m.`path`='/safety/risk' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:risk:identify:list' AND x.`path`='/safety/risk/identify' AND x.`deleted_at` IS NULL);
