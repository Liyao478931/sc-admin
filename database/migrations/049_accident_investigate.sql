-- =====================================================
-- 049_accident_investigate.sql 事故调查模块（幂等可重复执行）
-- =====================================================
-- 一、事故调查表
CREATE TABLE IF NOT EXISTS `safety_accident_investigation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `accident_id` int(11) NOT NULL COMMENT '事故ID',
  `investigation_code` varchar(50) NOT NULL COMMENT '调查编号 I-YYYYMMDD-XXXX',
  `investigator_id` int(11) DEFAULT NULL COMMENT '调查人ID',
  `investigator_name` varchar(50) DEFAULT NULL COMMENT '调查人姓名',
  `investigation_deadline` date DEFAULT NULL COMMENT '调查期限',
  `assigned_at` datetime DEFAULT NULL COMMENT '分配时间',
  `started_at` datetime DEFAULT NULL COMMENT '开始调查时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成调查时间',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '调查状态 pending/investigating/closed',
  `direct_cause` text COMMENT '直接原因',
  `indirect_cause` text COMMENT '间接原因',
  `root_cause` text COMMENT '根本原因',
  `responsible_person` varchar(50) DEFAULT NULL COMMENT '责任人',
  `responsible_department` varchar(100) DEFAULT NULL COMMENT '责任部门',
  `responsibility_opinion` text COMMENT '责任认定',
  `handle_suggestion` text COMMENT '处理建议',
  `corrective_measures` json DEFAULT NULL COMMENT '整改措施列表',
  `conclusion` text COMMENT '调查结论',
  `attachments` json DEFAULT NULL COMMENT '附件列表',
  `submit_status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '审批状态 draft/pending/approved/rejected',
  `approver_id` int(11) DEFAULT NULL COMMENT '审批人ID',
  `approver_name` varchar(50) DEFAULT NULL COMMENT '审批人姓名',
  `approved_at` datetime DEFAULT NULL COMMENT '审批时间',
  `reject_reason` varchar(500) DEFAULT NULL COMMENT '驳回原因',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_investigation_code` (`investigation_code`),
  KEY `idx_accident_id` (`accident_id`),
  KEY `idx_investigator_id` (`investigator_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='事故调查';

-- 二、调查时间线表
CREATE TABLE IF NOT EXISTS `safety_accident_timeline` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `accident_id` int(11) NOT NULL COMMENT '事故ID',
  `action` varchar(30) NOT NULL COMMENT '操作类型 assigned/started/submitted/approved/rejected/completed',
  `operator_id` int(11) NOT NULL COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL COMMENT '操作人姓名',
  `description` varchar(255) NOT NULL COMMENT '操作描述',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_accident_id` (`accident_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='事故调查时间线';

-- 三、数据字典
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('调查状态','investigation_status','事故调查状态',93,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='investigation_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'待分配','pending',1,'warning',1,NOW(),NOW()),
(@dt1,'调查中','investigating',2,'primary',1,NOW(),NOW()),
(@dt1,'已结案','closed',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('审批状态','submit_status','调查报告审批状态',94,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='submit_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'草稿','draft',1,'info',1,NOW(),NOW()),
(@dt2,'待审批','pending',2,'warning',1,NOW(),NOW()),
(@dt2,'已通过','approved',3,'success',1,NOW(),NOW()),
(@dt2,'已驳回','rejected',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 四、系统参数
INSERT INTO `settings` (`key`,`value`,`created_at`,`updated_at`) VALUES
('investigation_code_prefix','I',NOW(),NOW()),
('investigation_default_deadline_days','15',NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('investigation_code_prefix','I','调查编号前缀','safety','string','调查编号前缀（I-YYYYMMDD-XXXX）',76,0,1,NOW(),NOW()),
('investigation_default_deadline_days','15','默认调查期限（天）','safety','number','分配调查人时的默认调查期限',77,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- 五、权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('事故调查列表','safety:accident:investigate:list',1,0,'事故管理','/safety/accident/investigate','el-icon-search',116,1,1,'查看事故调查',NOW(),NOW()),
('调查详情查询','safety:accident:investigate:query',2,0,'事故管理','/safety/accident/investigate',NULL,117,1,1,'查询调查详情',NOW(),NOW()),
('分配调查人','safety:accident:investigate:assign',2,0,'事故管理','/safety/accident/investigate',NULL,118,1,1,'分配调查人',NOW(),NOW()),
('开始调查','safety:accident:investigate:start',2,0,'事故管理','/safety/accident/investigate',NULL,119,1,1,'开始调查',NOW(),NOW()),
('调查编辑','safety:accident:investigate:edit',2,0,'事故管理','/safety/accident/investigate',NULL,120,1,1,'编辑调查报告',NOW(),NOW()),
('提交审批','safety:accident:investigate:submit',2,0,'事故管理','/safety/accident/investigate',NULL,121,1,1,'提交审批',NOW(),NOW()),
('审批调查','safety:accident:investigate:approve',2,0,'事故管理','/safety/accident/investigate',NULL,122,1,1,'审批调查报告',NOW(),NOW()),
('调查导出','safety:accident:investigate:export',2,0,'事故管理','/safety/accident/investigate',NULL,123,1,1,'导出调查报告',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'safety:accident:investigate:%';

-- 六、菜单：事故管理 → 事故调查
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'事故调查','/safety/accident/investigate','el-icon-search','safety:accident:investigate:list',2,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:accident:list' AND m.`path`='/safety/accident' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:accident:investigate:list' AND x.`deleted_at` IS NULL);
