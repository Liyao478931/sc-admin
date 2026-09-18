-- 209_create_assessment_template.sql
-- 考核模板管理（人事管理 -> 绩效考核 -> 考核模板管理）
-- 3 张表：assessment_templates / assessment_indicator_library / assessment_template_indicators
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('hr:assessment','assessment:template:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'assessment:%');
--   DELETE FROM permissions WHERE code LIKE 'assessment:%';
--   DROP TABLE IF EXISTS assessment_template_indicators;
--   DROP TABLE IF EXISTS assessment_indicator_library;
--   DROP TABLE IF EXISTS assessment_templates;

-- ========== 一、考核模板表 ==========
CREATE TABLE IF NOT EXISTS `assessment_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `code` varchar(50) NOT NULL COMMENT '模板编码，唯一',
  `category` varchar(50) NOT NULL DEFAULT '' COMMENT '适用岗位类别：操作工/维修工/质检员/班组长/管理人员',
  `period_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '周期类型：1月度 2季度 3年度 4半年度',
  `total_score` decimal(5,2) NOT NULL DEFAULT 100.00 COMMENT '模板总分',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认模板',
  `version` int(11) NOT NULL DEFAULT 1 COMMENT '版本号，每次修改+1',
  `description` varchar(500) DEFAULT NULL COMMENT '模板描述',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_category` (`category`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考核模板表';

-- ========== 二、全局指标库表 ==========
CREATE TABLE IF NOT EXISTS `assessment_indicator_library` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '指标名称',
  `category` varchar(50) DEFAULT NULL COMMENT '所属大类：履职情况/公共量化指标/安全/纪律行为规范',
  `default_score` decimal(5,2) NOT NULL DEFAULT 5.00 COMMENT '建议分值',
  `default_data_source` varchar(50) DEFAULT NULL COMMENT '建议数据源：attendance/production/quality/maintenance/training/exam/manual',
  `default_deduct_rule` text COMMENT '默认扣分规则（JSON）',
  `usage_count` int(11) NOT NULL DEFAULT 0 COMMENT '被模板引用次数',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='全局指标库表';

-- ========== 三、模板指标关联表 ==========
CREATE TABLE IF NOT EXISTS `assessment_template_indicators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) NOT NULL COMMENT '模板ID',
  `indicator_id` int(11) DEFAULT NULL COMMENT '指标库ID（自定义指标为NULL）',
  `parent_id` int(11) NOT NULL DEFAULT 0 COMMENT '父指标ID（0为顶级/分组）',
  `name` varchar(100) NOT NULL COMMENT '指标名称',
  `category` varchar(50) DEFAULT NULL COMMENT '所属大类',
  `score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '该项分值',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序（同一父级下）',
  `data_source` varchar(50) DEFAULT NULL COMMENT '数据源',
  `data_source_config` text COMMENT '数据源配置（JSON）',
  `scoring_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '评分类型：1扣分制 2加分制 3等级制',
  `auto_deduct_rule` text COMMENT '自动扣分规则（JSON）',
  `is_custom` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否自定义指标（非指标库引用）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_template` (`template_id`),
  KEY `idx_parent` (`parent_id`),
  KEY `idx_indicator` (`indicator_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='模板指标关联表';

-- ========== 四、预置指标库数据（12 条，幂等：按名称判空） ==========
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '迟到早退','纪律行为规范',5.00,'attendance','{"conditions":[{"field":"violation_type","operator":"eq","value":"late","deduct_per_unit":1,"max_deduct":5}],"logical_operator":"or","fallback_score":0,"remark_template":"迟到{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='迟到早退');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '旷工','纪律行为规范',5.00,'attendance','{"conditions":[{"field":"violation_type","operator":"eq","value":"absent","deduct_per_unit":5,"max_deduct":10}],"logical_operator":"or","fallback_score":0,"remark_template":"旷工{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='旷工');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '脱岗','纪律行为规范',5.00,'attendance','{"conditions":[{"field":"violation_type","operator":"eq","value":"leave_post","deduct_per_unit":5,"max_deduct":10}],"logical_operator":"or","fallback_score":0,"remark_template":"脱岗{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='脱岗');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '产品不合格','履职情况',5.00,'quality','{"conditions":[{"field":"reject_type","operator":"eq","value":"unqualified","deduct_per_unit":2,"max_deduct":10}],"logical_operator":"or","fallback_score":0,"remark_template":"不合格{{count}}件，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='产品不合格');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '生产任务未完成','履职情况',5.00,'production','{"conditions":[{"field":"task_status","operator":"eq","value":"not_finished","deduct_per_unit":1,"max_deduct":5}],"logical_operator":"or","fallback_score":0,"remark_template":"未完成{{count}}个工单，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='生产任务未完成');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '安全违规','安全',10.00,'safety','{"conditions":[{"field":"violation_level","operator":"eq","value":"normal","deduct_per_unit":3,"max_deduct":6},{"field":"violation_level","operator":"eq","value":"serious","deduct_per_unit":10,"max_deduct":10}],"logical_operator":"or","fallback_score":0,"remark_template":"{{violation_level_name}}违规{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='安全违规');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '设备未保养','履职情况',5.00,'maintenance','{"conditions":[{"field":"maintenance_status","operator":"eq","value":"missed","deduct_per_unit":5,"max_deduct":10}],"logical_operator":"or","fallback_score":0,"remark_template":"未保养{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='设备未保养');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '考试成绩不达标','公共量化指标',5.00,'exam','{"conditions":[{"field":"score","operator":"lt","value":90,"deduct_ratio":1,"max_deduct":5}],"logical_operator":"or","fallback_score":0,"remark_template":"成绩{{score}}分，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='考试成绩不达标');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '培训缺席','公共量化指标',5.00,'training','{"conditions":[{"field":"attend_status","operator":"eq","value":"absent","deduct_per_unit":2,"max_deduct":6}],"logical_operator":"or","fallback_score":0,"remark_template":"缺席{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='培训缺席');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '环境卫生不达标','纪律行为规范',2.00,'manual','{"conditions":[{"field":"check_result","operator":"eq","value":"not_pass","deduct_per_unit":2,"max_deduct":4}],"logical_operator":"or","fallback_score":0,"remark_template":"不达标{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='环境卫生不达标');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '着装不规范','纪律行为规范',2.00,'manual','{"conditions":[{"field":"check_result","operator":"eq","value":"not_pass","deduct_per_unit":2,"max_deduct":4}],"logical_operator":"or","fallback_score":0,"remark_template":"不规范{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='着装不规范');
INSERT INTO `assessment_indicator_library` (`name`,`category`,`default_score`,`default_data_source`,`default_deduct_rule`,`usage_count`,`status`,`created_by`,`created_at`,`updated_at`)
SELECT '会议违纪','纪律行为规范',3.00,'manual','{"conditions":[{"field":"violation_type","operator":"eq","value":"meeting","deduct_per_unit":3,"max_deduct":6}],"logical_operator":"or","fallback_score":0,"remark_template":"违纪{{count}}次，扣{{deduct}}分"}',0,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `assessment_indicator_library` WHERE `name`='会议违纪');

-- ========== 五、权限（9 个，幂等） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板管理','assessment:template:view',2,0,'hr','/hr/assessment/template','el-icon-document-checked',NULL,301,1,1,'考核模板管理-查看（菜单）',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板创建','assessment:template:create',2,0,'hr',NULL,NULL,NULL,302,1,1,'创建考核模板',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:create');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板编辑','assessment:template:edit',2,0,'hr',NULL,NULL,NULL,303,1,1,'编辑考核模板',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:edit');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板删除','assessment:template:delete',2,0,'hr',NULL,NULL,NULL,304,1,1,'删除考核模板',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:delete');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板启停用','assessment:template:toggle',2,0,'hr',NULL,NULL,NULL,305,1,1,'启用/停用考核模板',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:toggle');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板复制','assessment:template:duplicate',2,0,'hr',NULL,NULL,NULL,306,1,1,'复制考核模板',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:duplicate');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核模板导出','assessment:template:export',2,0,'hr',NULL,NULL,NULL,307,1,1,'导出考核模板预览',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:template:export');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '指标库管理','assessment:indicator:library:manage',2,0,'hr',NULL,NULL,NULL,308,1,1,'管理指标库（增删改）',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:indicator:library:manage');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '指标库查看','assessment:indicator:library:view',2,0,'hr',NULL,NULL,NULL,309,1,1,'查看指标库',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:indicator:library:view');

INSERT INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'assessment:%'
AND NOT EXISTS (SELECT 1 FROM `role_permissions` rp WHERE rp.role_id=r.`id` AND rp.permission_id=p.`id`);

-- ========== 六、菜单链：人事管理 -> 绩效考核（目录）-> 考核模板管理（叶子） ==========
-- 1. 确保人事管理顶级菜单存在（已存在则跳过）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '人事管理', '', 'el-icon-user', 'hr:view', 70, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL);

-- 2. 绩效考核目录（挂在人事管理下，type=1 目录）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '绩效考核', '/hr/assessment', 'el-icon-data-analysis', 'hr:assessment', 60, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:assessment' AND deleted_at IS NULL);

-- 3. 考核模板管理叶子（挂在绩效考核下，type=2 叶子）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:assessment' AND deleted_at IS NULL LIMIT 1), '考核模板管理', '/hr/assessment/template', 'el-icon-document-checked', 'assessment:template:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='assessment:template:view' AND deleted_at IS NULL);
