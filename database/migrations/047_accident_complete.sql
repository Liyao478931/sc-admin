-- =====================================================
-- 047_accident_complete.sql 事故登记模块（幂等可重复执行）
-- =====================================================
-- 一、事故表
CREATE TABLE IF NOT EXISTS `safety_accident` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `accident_code` varchar(50) NOT NULL COMMENT '事故编号 A-YYYYMMDD-XXXX',
  `accident_name` varchar(200) NOT NULL COMMENT '事故名称',
  `accident_type` varchar(30) NOT NULL COMMENT '事故类型 personal_injury/equipment_damage/fire/explosion/leakage/other',
  `accident_level` varchar(20) NOT NULL COMMENT '事故等级 general/major/serious/critical',
  `happen_time` datetime NOT NULL COMMENT '发生时间',
  `happen_location` varchar(200) NOT NULL COMMENT '发生地点',
  `happen_department` int(11) DEFAULT NULL COMMENT '发生部门ID',
  `happen_department_name` varchar(100) DEFAULT NULL COMMENT '发生部门名称(冗余)',
  `accident_process` text NOT NULL COMMENT '事故经过',
  `accident_cause` text NOT NULL COMMENT '事故原因',
  `death_count` int(11) NOT NULL DEFAULT 0 COMMENT '死亡人数',
  `serious_injury_count` int(11) NOT NULL DEFAULT 0 COMMENT '重伤人数',
  `minor_injury_count` int(11) NOT NULL DEFAULT 0 COMMENT '轻伤人数',
  `economic_loss` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '直接经济损失(万元)',
  `responsible_person` varchar(50) DEFAULT NULL COMMENT '责任人姓名',
  `responsible_department` varchar(100) DEFAULT NULL COMMENT '责任人部门',
  `responsible_position` varchar(100) DEFAULT NULL COMMENT '责任人岗位',
  `handle_opinion` varchar(500) DEFAULT NULL COMMENT '处理意见',
  `registrant_id` int(11) NOT NULL COMMENT '登记人ID',
  `registrant_name` varchar(50) NOT NULL COMMENT '登记人姓名',
  `attachments` json DEFAULT NULL COMMENT '附件列表',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态 pending/investigating/closed/archived',
  `remark` text DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_accident_code` (`accident_code`),
  KEY `idx_accident_type` (`accident_type`),
  KEY `idx_accident_level` (`accident_level`),
  KEY `idx_happen_time` (`happen_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='事故登记';

-- 二、数据字典
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('事故类型','safety_accident_type','事故类型',90,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='safety_accident_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'人身伤害','personal_injury',1,'danger',1,NOW(),NOW()),
(@dt1,'设备损坏','equipment_damage',2,'warning',1,NOW(),NOW()),
(@dt1,'火灾','fire',3,'danger',1,NOW(),NOW()),
(@dt1,'爆炸','explosion',4,'danger',1,NOW(),NOW()),
(@dt1,'泄漏','leakage',5,'warning',1,NOW(),NOW()),
(@dt1,'其他','other',6,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('事故等级','safety_accident_level','事故等级',91,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='safety_accident_level');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'一般','general',1,'primary',1,NOW(),NOW()),
(@dt2,'较大','major',2,'warning',1,NOW(),NOW()),
(@dt2,'重大','serious',3,'danger',1,NOW(),NOW()),
(@dt2,'特别重大','critical',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('事故状态','safety_accident_status','事故状态',92,1,NOW(),NOW());
SET @dt3=(SELECT id FROM dictionary_types WHERE code='safety_accident_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt3,'待调查','pending',1,'warning',1,NOW(),NOW()),
(@dt3,'调查中','investigating',2,'primary',1,NOW(),NOW()),
(@dt3,'已结案','closed',3,'success',1,NOW(),NOW()),
(@dt3,'已归档','archived',4,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 三、系统参数
INSERT INTO `settings` (`key`,`value`,`created_at`,`updated_at`) VALUES
('accident_code_prefix','A',NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('accident_code_prefix','A','事故编号前缀','safety','string','事故编号前缀（A-YYYYMMDD-XXXX）',75,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- 四、权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('事故登记查看','safety:accident:list',1,0,'事故管理','/safety/accident/register','el-icon-warning',110,1,1,'查看事故登记',NOW(),NOW()),
('事故详情查询','safety:accident:query',2,0,'事故管理','/safety/accident/register',NULL,111,1,1,'查询事故详情',NOW(),NOW()),
('事故新增','safety:accident:add',2,0,'事故管理','/safety/accident/register',NULL,112,1,1,'新增事故',NOW(),NOW()),
('事故编辑','safety:accident:edit',2,0,'事故管理','/safety/accident/register',NULL,113,1,1,'编辑事故',NOW(),NOW()),
('事故删除','safety:accident:delete',2,0,'事故管理','/safety/accident/register',NULL,114,1,1,'删除事故',NOW(),NOW()),
('事故导出','safety:accident:export',2,0,'事故管理','/safety/accident/register',NULL,115,1,1,'导出事故',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` IN ('safety:accident:list','safety:accident:query','safety:accident:add','safety:accident:edit','safety:accident:delete','safety:accident:export');

-- 五、菜单：安全管理 → 事故管理 → 事故登记
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'事故管理','/safety/accident','el-icon-warning','safety:accident:list',6,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:accident:list' AND x.`path`='/safety/accident' AND x.`deleted_at` IS NULL);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'事故登记','/safety/accident/register','el-icon-warning','safety:accident:list',1,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:accident:list' AND m.`path`='/safety/accident' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:accident:list' AND x.`path`='/safety/accident/register' AND x.`deleted_at` IS NULL);
