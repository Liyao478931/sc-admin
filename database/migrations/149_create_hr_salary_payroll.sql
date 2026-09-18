-- 149_create_hr_salary_payroll.sql
-- 工资计算与工资配置（人事管理 -> 薪酬管理 -> 工资核算 -> 工资计算）：3 表 + 8 权限 + 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:salary:payroll:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:salary:payroll:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:salary:payroll:%';
--   DROP TABLE IF EXISTS hr_salary_detail;
--   DROP TABLE IF EXISTS hr_salary_calculation;
--   DROP TABLE IF EXISTS hr_salary_config;

-- ========== 一、工资配置表 ==========
CREATE TABLE IF NOT EXISTS `hr_salary_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `config_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '配置类型：1基本工资 2工分单价 3津贴 4扣款 5其他',
  `config_name` varchar(50) NOT NULL DEFAULT '' COMMENT '配置名称',
  `config_key` varchar(50) NOT NULL DEFAULT '' COMMENT '配置键（唯一）',
  `dimension_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '维度类型：1全局 2按岗位 3按职级 4按部门',
  `dimension_value` varchar(50) NOT NULL DEFAULT '' COMMENT '维度值（岗位/职级/部门ID，全局为空）',
  `dimension_label` varchar(50) NOT NULL DEFAULT '' COMMENT '维度标签',
  `value_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '值类型：1固定金额 2百分比 3公式',
  `value` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '配置值',
  `unit` varchar(20) NOT NULL DEFAULT '' COMMENT '单位（元/%/分）',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用：1启用 0停用',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`),
  KEY `idx_config_type` (`config_type`),
  KEY `idx_dimension` (`dimension_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资配置表';

-- ========== 二、工资计算主表 ==========
CREATE TABLE IF NOT EXISTS `hr_salary_calculation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `calc_no` varchar(30) NOT NULL DEFAULT '' COMMENT '计算编号 SC+YYYYMM+XXXX',
  `calc_month` varchar(7) NOT NULL DEFAULT '' COMMENT '计算月份 YYYY-MM',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：0草稿 1已计算 2已确认 3已发放',
  `total_employee` int(11) NOT NULL DEFAULT 0 COMMENT '总人数',
  `total_base_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '基本工资合计',
  `total_piecework_wage` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '计件工资合计',
  `total_allowance` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '津贴合计',
  `total_deduction` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '扣款合计',
  `total_gross_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '应发工资合计',
  `total_net_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '实发工资合计',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_calc_month` (`calc_month`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资计算主表';

-- ========== 三、工资计算明细表 ==========
CREATE TABLE IF NOT EXISTS `hr_salary_detail` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `calc_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工资计算主表ID',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '员工ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '员工姓名',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '部门名称',
  `rank_id` int(11) NOT NULL DEFAULT 0 COMMENT '职级ID',
  `rank_name` varchar(50) NOT NULL DEFAULT '' COMMENT '职级名称',
  `position_id` int(11) NOT NULL DEFAULT 0 COMMENT '岗位ID',
  `position_name` varchar(50) NOT NULL DEFAULT '' COMMENT '岗位名称',
  `base_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '基本工资',
  `piecework_score` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '工分',
  `piecework_price` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工分单价',
  `piecework_wage` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '计件工资',
  `attendance_days` decimal(5,1) NOT NULL DEFAULT 0 COMMENT '出勤天数',
  `allowance_json` json DEFAULT NULL COMMENT '津贴明细JSON',
  `allowance_total` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '津贴合计',
  `deduction_json` json DEFAULT NULL COMMENT '扣款明细JSON',
  `deduction_total` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '扣款合计',
  `gross_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '应发工资',
  `net_salary` decimal(14,2) NOT NULL DEFAULT 0 COMMENT '实发工资',
  `detail_json` json DEFAULT NULL COMMENT '完整明细快照',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_calc_id` (`calc_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资计算明细表';

-- ========== 四、权限（8 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工资计算','hr:salary:payroll:view',2,0,'hr','/hr/salary/calculate/payroll','el-icon-money',NULL,183,1,1,'工资计算-查看（菜单）',NOW(),NOW()),
('工资计算执行','hr:salary:payroll:calculate',2,0,'hr',NULL,NULL,NULL,184,1,1,'执行工资计算',NOW(),NOW()),
('工资计算确认','hr:salary:payroll:confirm',2,0,'hr',NULL,NULL,NULL,185,1,1,'确认工资',NOW(),NOW()),
('工资计算导出','hr:salary:payroll:export',2,0,'hr',NULL,NULL,NULL,186,1,1,'导出工资报表',NOW(),NOW()),
('工资配置查看','hr:salary:payroll:config:view',2,0,'hr',NULL,NULL,NULL,187,1,1,'工资配置-查看',NOW(),NOW()),
('工资配置新增','hr:salary:payroll:config:add',2,0,'hr',NULL,NULL,NULL,188,1,1,'新增工资配置',NOW(),NOW()),
('工资配置编辑','hr:salary:payroll:config:edit',2,0,'hr',NULL,NULL,NULL,189,1,1,'编辑工资配置',NOW(),NOW()),
('工资配置删除','hr:salary:payroll:config:delete',2,0,'hr',NULL,NULL,NULL,190,1,1,'删除工资配置',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'hr:salary:payroll:%';

-- ========== 五、菜单：工资核算（hr:salary:calculate）-> 工资计算 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary:calculate' AND deleted_at IS NULL LIMIT 1), '工资计算', '/hr/salary/calculate/payroll', 'el-icon-money', 'hr:salary:payroll:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:payroll:view' AND deleted_at IS NULL);
