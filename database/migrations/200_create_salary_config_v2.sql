-- 200_create_salary_config_v2.sql
-- 工资配置 V2（参考「华能数智 · 工资配置」页面 + 工资模板 Excel）
-- 3 张表：salary_config（配置主表）、salary_config_items（工资项目）、salary_grade_standard（等级标准）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('hr:salary:config:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:salary:config:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:salary:config:%';
--   DROP TABLE IF EXISTS salary_grade_standard;
--   DROP TABLE IF EXISTS salary_config_items;
--   DROP TABLE IF EXISTS salary_config;

-- ========== 一、工资配置主表 ==========
CREATE TABLE IF NOT EXISTS `salary_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `config_name` varchar(50) NOT NULL DEFAULT '' COMMENT '配置名称（如：2026年1月工资配置）',
  `config_year` int(11) NOT NULL DEFAULT 0 COMMENT '适用年份',
  `config_month` int(11) NOT NULL DEFAULT 0 COMMENT '适用月份',
  `config_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=草稿 1=生效 2=历史',
  `standard_work_days` int(11) NOT NULL DEFAULT 22 COMMENT '标准出勤天数',
  `overtime_rates` json DEFAULT NULL COMMENT '加班费率（周六/周日/节假日）',
  `seniority_thresholds` json DEFAULT NULL COMMENT '工龄工资阶梯',
  `insurance_rates` json DEFAULT NULL COMMENT '社保公积金费率',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_year_month` (`config_year`, `config_month`),
  KEY `idx_status` (`config_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资配置主表';

-- ========== 二、工资项目配置表 ==========
CREATE TABLE IF NOT EXISTS `salary_config_items` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `config_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联配置ID（0=系统默认模板）',
  `item_code` varchar(30) NOT NULL DEFAULT '' COMMENT '项目编码（如 basic_wage）',
  `item_name` varchar(50) NOT NULL DEFAULT '' COMMENT '项目名称（如 基本工资）',
  `item_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=收入项 2=扣除项',
  `category` varchar(30) NOT NULL DEFAULT '' COMMENT '分类：basic_wage/allowance/piece/assessment/insurance/other/tax',
  `calculation_type` varchar(20) NOT NULL DEFAULT 'manual' COMMENT 'fixed(固定值)/ratio(比例)/formula(公式)/manual(手动录入)',
  `formula_expression` text DEFAULT NULL COMMENT '公式表达式（JSON）',
  `depends_on` json DEFAULT NULL COMMENT '依赖的项目列表',
  `default_value` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '默认值',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '显示排序',
  `is_visible` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=隐藏 1=显示',
  `is_editable` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=不可编辑 1=可编辑',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_config_id` (`config_id`),
  KEY `idx_item_code` (`item_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资项目配置表';

-- ========== 三、工资等级标准表 ==========
CREATE TABLE IF NOT EXISTS `salary_grade_standard` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `config_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联配置ID（0=系统默认模板）',
  `grade_code` varchar(30) NOT NULL DEFAULT '' COMMENT '等级编码（如 A-01）',
  `grade_name` varchar(50) NOT NULL DEFAULT '' COMMENT '等级名称（如 一类科长（B））',
  `basic_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '基本工资标准',
  `position_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '岗位工资标准',
  `daily_assessment_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '日常考核工资标准',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_config_id` (`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资等级标准表';

-- ========== 四、预置系统默认工资项目（config_id=0 模板） ==========
INSERT INTO `salary_config_items` (`config_id`,`item_code`,`item_name`,`item_type`,`category`,`calculation_type`,`formula_expression`,`depends_on`,`default_value`,`sort`,`is_visible`,`is_editable`,`status`,`created_at`,`updated_at`) VALUES
(0,'basic_wage','基本工资',1,'basic_wage','formula','{"type":"reference","source":"grade.basic_wage"}',NULL,0,1,1,1,1,NOW(),NOW()),
(0,'position_wage','岗位工资',1,'basic_wage','formula','{"type":"reference","source":"grade.position_wage"}',NULL,0,2,1,1,1,NOW(),NOW()),
(0,'daily_assessment','日常考核工资',1,'basic_wage','formula','{"type":"reference","source":"grade.daily_assessment_wage"}',NULL,0,3,1,1,1,NOW(),NOW()),
(0,'overtime_pay','加班工资',1,'allowance','formula','{"type":"conditional","field":"overtime_hours","condition":">","threshold":0,"then":"overtime_hours * hourly_rate","else":"0"}',NULL,0,4,1,1,1,NOW(),NOW()),
(0,'seniority_wage','工龄工资',1,'allowance','formula','{"type":"reference","source":"seniority"}',NULL,0,5,1,1,1,NOW(),NOW()),
(0,'education_subsidy','学历补助',1,'allowance','fixed',NULL,NULL,0,6,1,1,1,NOW(),NOW()),
(0,'title_subsidy','职称补助',1,'allowance','fixed',NULL,NULL,0,7,1,1,1,NOW(),NOW()),
(0,'night_shift_subsidy','夜班补助',1,'allowance','fixed',NULL,NULL,0,8,1,1,1,NOW(),NOW()),
(0,'duty_subsidy','值班补助',1,'allowance','fixed',NULL,NULL,0,9,1,1,1,NOW(),NOW()),
(0,'driver_allowance','司机津贴',1,'allowance','fixed',NULL,NULL,0,10,1,1,1,NOW(),NOW()),
(0,'other_allowance','其它补助',1,'allowance','manual',NULL,NULL,0,11,1,1,1,NOW(),NOW()),
(0,'piece_wage','计件工资',1,'piece','manual',NULL,NULL,0,12,1,1,1,NOW(),NOW()),
(0,'assessment_deduction','考核扣款',2,'assessment','formula','{"type":"fixed","value":0}',NULL,0,13,1,1,1,NOW(),NOW()),
(0,'insurance_pension','养老保险',2,'insurance','ratio','{"rate":8.00}',NULL,0,14,1,1,1,NOW(),NOW()),
(0,'insurance_medical','医疗保险',2,'insurance','ratio','{"rate":2.00}',NULL,0,15,1,1,1,NOW(),NOW()),
(0,'insurance_unemployment','失业保险',2,'insurance','ratio','{"rate":0.30}',NULL,0,16,1,1,1,NOW(),NOW()),
(0,'insurance_housing_fund','住房公积金',2,'insurance','ratio','{"rate":12.00}',NULL,0,17,1,1,1,NOW(),NOW()),
(0,'insurance_annuity','年金',2,'insurance','ratio','{"rate":4.00}',NULL,0,18,1,1,1,NOW(),NOW()),
(0,'union_fee','会员费',2,'other','fixed',NULL,NULL,0,19,1,1,1,NOW(),NOW()),
(0,'serious_illness','大病',2,'other','fixed',NULL,NULL,0,20,1,1,1,NOW(),NOW()),
(0,'income_tax','个税',2,'tax','formula','{"type":"tax_calculator"}',NULL,0,21,1,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `item_name`=VALUES(`item_name`),`updated_at`=NOW();

-- ========== 五、预置系统默认等级标准（config_id=0 模板，参考工资模板） ==========
INSERT INTO `salary_grade_standard` (`config_id`,`grade_code`,`grade_name`,`basic_wage`,`position_wage`,`daily_assessment_wage`,`created_at`,`updated_at`) VALUES
(0,'A-01','一类科长（B）',1611.00,941.00,4067.00,NOW(),NOW()),
(0,'A-02','二类科长',1500.00,800.00,3500.00,NOW(),NOW()),
(0,'B-01','一级科员',1200.00,600.00,2800.00,NOW(),NOW())
ON DUPLICATE KEY UPDATE `grade_name`=VALUES(`grade_name`),`updated_at`=NOW();

-- ========== 六、预置一条默认工资配置（草稿） ==========
INSERT INTO `salary_config` (`config_name`,`config_year`,`config_month`,`config_status`,`standard_work_days`,`overtime_rates`,`seniority_thresholds`,`insurance_rates`,`remark`,`created_by`,`created_at`,`updated_at`)
SELECT '默认工资配置',2026,1,0,22,
  JSON_OBJECT('sat',2.0,'sun',2.0,'holiday',3.0),
  JSON_ARRAY(JSON_OBJECT('min',0,'max',9,'amount',10),JSON_OBJECT('min',10,'max',14,'amount',20),JSON_OBJECT('min',15,'max',19,'amount',30),JSON_OBJECT('min',20,'max',null,'amount',40)),
  JSON_OBJECT('pension',8.00,'medical',2.00,'unemployment',0.30,'housing_fund',12.00,'annuity',4.00),
  '基于工资模板的系统默认工资配置',0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM salary_config WHERE deleted_at IS NULL AND id = (SELECT MAX(id) FROM salary_config));

-- ========== 七、菜单/权限：工资配置（复用现有 hr:salary:config:view 菜单，权限已存在则跳过） ==========
-- 现有菜单：人事管理(21) -> 薪酬管理(hr:salary) -> 工资配置(/hr/salary/config)
-- 权限 hr:salary:config:view/add/edit/delete 已由 150_rework_salary_rules.sql 创建，此处幂等补充
INSERT IGNORE INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工资配置','hr:salary:config:view',2,0,'hr','/hr/salary/config','el-icon-set-up',NULL,191,1,1,'工资配置-查看（菜单）',NOW(),NOW()),
('工资配置新增','hr:salary:config:add',2,0,'hr',NULL,NULL,NULL,192,1,1,'新增工资配置',NOW(),NOW()),
('工资配置编辑','hr:salary:config:edit',2,0,'hr',NULL,NULL,NULL,193,1,1,'编辑工资配置',NOW(),NOW()),
('工资配置删除','hr:salary:config:delete',2,0,'hr',NULL,NULL,NULL,194,1,1,'删除工资配置',NOW(),NOW());

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'hr:salary:config:%';
