-- 207_create_salary_detail.sql
-- 工资计算明细表（与 Excel 一月工资模板 43 列完全一致）
-- 1 张表：salary_detail + 社保导入记录表 salary_insurance_import_log
-- 幂等写法，可重复执行
-- 回滚 down：
--   DROP TABLE IF EXISTS salary_insurance_import_log;
--   DROP TABLE IF EXISTS salary_detail;

-- ========== 一、工资计算明细表 ==========
CREATE TABLE IF NOT EXISTS `salary_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sheet_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工资表ID',
  `year` int(11) NOT NULL DEFAULT 0 COMMENT '年份',
  `month` int(11) NOT NULL DEFAULT 0 COMMENT '月份',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '员工ID',
  `employee_no` varchar(30) DEFAULT NULL COMMENT '工号',
  `employee_name` varchar(50) NOT NULL DEFAULT '' COMMENT '姓名',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '部门ID',
  `department_name` varchar(100) DEFAULT '' COMMENT '部门',
  `position_level` varchar(30) DEFAULT NULL COMMENT '定级级别/岗位编码',
  `position_name` varchar(50) DEFAULT NULL COMMENT '岗位名称',
  `work_days` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '月出勤（天数）',
  `overtime_sat` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '周六加班',
  `overtime_sun` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '周日加班',
  `overtime_holiday` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '节假日加班',
  `overtime_other` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '其它加班',
  `leave_days` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '调休',
  `basic_wage_standard` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '基本工资标准',
  `position_wage_standard` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '职务/岗位工资',
  `daily_assessment_standard` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '日常考核工资',
  `actual_basic_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '当月基本工资',
  `overtime_pay` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '双休日/节假日/其它加班工资',
  `actual_position_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '当月职务/岗位工资',
  `actual_daily_assessment` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '当月日常考核',
  `entry_date` date DEFAULT NULL COMMENT '参加工作时间',
  `seniority_years` int(11) NOT NULL DEFAULT 0 COMMENT '工龄年限',
  `seniority_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '工龄工资',
  `education_subsidy` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '学历补助',
  `title_subsidy` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '职称补助',
  `night_shift_subsidy` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '夜班补助',
  `duty_subsidy` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '值班补助',
  `driver_allowance` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '司机津贴',
  `other_allowance` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '其它补助',
  `assessment_score` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '扣分/加分',
  `assessment_deduction` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '考核扣款/奖励',
  `piece_points` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '本月累计工分',
  `piece_unit_price` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工分单价（元/分）',
  `piece_wage` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '计件金额',
  `supplement` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '补差',
  `total_income` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '应税收入合计',
  `insurance_pension` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '基本养老保险费',
  `insurance_medical` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '基本医疗保险费',
  `insurance_unemployment` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '失业保险费',
  `insurance_housing_fund` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '住房公积金',
  `insurance_annuity` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '年金',
  `insurance_company` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '代扣社保集体部分（预留）',
  `union_fee` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '会员费',
  `serious_illness` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '大病',
  `income_tax` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '个税',
  `net_pay` decimal(15,2) NOT NULL DEFAULT 0 COMMENT '实发工资',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=草稿 1=已确认',
  `detail_json` json DEFAULT NULL COMMENT '计算明细快照',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sheet_id` (`sheet_id`),
  KEY `idx_user_month` (`user_id`, `year`, `month`),
  KEY `idx_year_month` (`year`, `month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工资计算明细表（与Excel模板一致）';

-- ========== 二、社保公积金导入记录表 ==========
CREATE TABLE IF NOT EXISTS `salary_insurance_import_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sheet_id` int(11) NOT NULL DEFAULT 0 COMMENT '工资表ID',
  `year` int(11) NOT NULL DEFAULT 0,
  `month` int(11) NOT NULL DEFAULT 0,
  `file_name` varchar(255) DEFAULT NULL COMMENT '导入文件名',
  `import_count` int(11) NOT NULL DEFAULT 0 COMMENT '导入条数',
  `import_by` int(11) NOT NULL DEFAULT 0 COMMENT '导入人ID',
  `import_at` datetime DEFAULT NULL COMMENT '导入时间',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社保导入记录表';
