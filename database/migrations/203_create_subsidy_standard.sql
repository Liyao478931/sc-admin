-- 203_create_subsidy_standard.sql
-- 学历补助与职称补助标准（人事管理 -> 薪酬管理 -> 补助标准配置）
-- 2 张表：education_subsidy_standard、title_subsidy_standard
-- employee_profiles 增加学历/职称字段
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='salary:subsidy:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'salary:subsidy:%');
--   DELETE FROM permissions WHERE code LIKE 'salary:subsidy:%';
--   DROP TABLE IF EXISTS education_subsidy_standard;
--   DROP TABLE IF EXISTS title_subsidy_standard;

-- ========== 一、学历补助标准表 ==========
CREATE TABLE IF NOT EXISTS `education_subsidy_standard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `education_level` varchar(30) NOT NULL COMMENT '学历等级',
  `education_code` varchar(20) NOT NULL COMMENT '学历编码',
  `subsidy_amount` decimal(15,2) DEFAULT 0 COMMENT '补助金额（元/月）',
  `effective_year` int(11) NOT NULL COMMENT '生效年份',
  `sort` int(11) DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) DEFAULT 1 COMMENT '0=停用 1=启用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_education_code_year` (`education_code`, `effective_year`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学历补助标准表';

-- ========== 二、职称补助标准表 ==========
CREATE TABLE IF NOT EXISTS `title_subsidy_standard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title_level` varchar(30) NOT NULL COMMENT '职称等级',
  `title_code` varchar(20) NOT NULL COMMENT '职称编码',
  `subsidy_amount` decimal(15,2) DEFAULT 0 COMMENT '补助金额（元/月）',
  `effective_year` int(11) NOT NULL COMMENT '生效年份',
  `sort` int(11) DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) DEFAULT 1 COMMENT '0=停用 1=启用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_title_code_year` (`title_code`, `effective_year`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='职称补助标准表';

-- ========== 三、员工档案增加学历/职称字段 ==========
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employee_profiles' AND COLUMN_NAME = 'education_level');
SET @sql := IF(@exist = 0, 'ALTER TABLE `employee_profiles` ADD COLUMN `education_level` varchar(30) DEFAULT NULL COMMENT ''学历'' AFTER `position_level`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist2 := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employee_profiles' AND COLUMN_NAME = 'education_code');
SET @sql2 := IF(@exist2 = 0, 'ALTER TABLE `employee_profiles` ADD COLUMN `education_code` varchar(20) DEFAULT NULL COMMENT ''学历编码'' AFTER `education_level`', 'SELECT 1');
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;

SET @exist3 := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employee_profiles' AND COLUMN_NAME = 'title_level');
SET @sql3 := IF(@exist3 = 0, 'ALTER TABLE `employee_profiles` ADD COLUMN `title_level` varchar(30) DEFAULT NULL COMMENT ''职称'' AFTER `education_code`', 'SELECT 1');
PREPARE stmt3 FROM @sql3; EXECUTE stmt3; DEALLOCATE PREPARE stmt3;

SET @exist4 := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employee_profiles' AND COLUMN_NAME = 'title_code');
SET @sql4 := IF(@exist4 = 0, 'ALTER TABLE `employee_profiles` ADD COLUMN `title_code` varchar(20) DEFAULT NULL COMMENT ''职称编码'' AFTER `title_level`', 'SELECT 1');
PREPARE stmt4 FROM @sql4; EXECUTE stmt4; DEALLOCATE PREPARE stmt4;

-- ========== 四、初始数据（2026 年） ==========
INSERT INTO `education_subsidy_standard` (`education_level`,`education_code`,`subsidy_amount`,`effective_year`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('本科','bachelor',200.00,2026,1,1,NOW(),NOW()),
('硕士','master',400.00,2026,2,1,NOW(),NOW()),
('博士','doctor',600.00,2026,3,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `education_level`=VALUES(`education_level`),`subsidy_amount`=VALUES(`subsidy_amount`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT INTO `title_subsidy_standard` (`title_level`,`title_code`,`subsidy_amount`,`effective_year`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('助理工程师','assistant_engineer',200.00,2026,1,1,NOW(),NOW()),
('工程师','engineer',400.00,2026,2,1,NOW(),NOW()),
('高级工程师','senior_engineer',600.00,2026,3,1,NOW(),NOW()),
('经济师','economist',400.00,2026,4,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `title_level`=VALUES(`title_level`),`subsidy_amount`=VALUES(`subsidy_amount`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

-- ========== 五、权限（4 个） ==========
INSERT IGNORE INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('补助标准配置','salary:subsidy:view',2,0,'hr','/hr/salary/subsidy','el-icon-price-tag',NULL,207,1,1,'补助标准配置-查看（菜单）',NOW(),NOW()),
('补助标准新增','salary:subsidy:create',2,0,'hr',NULL,NULL,NULL,208,1,1,'新增补助标准',NOW(),NOW()),
('补助标准编辑','salary:subsidy:edit',2,0,'hr',NULL,NULL,NULL,209,1,1,'编辑补助标准',NOW(),NOW()),
('补助标准删除','salary:subsidy:delete',2,0,'hr',NULL,NULL,NULL,210,1,1,'删除补助标准',NOW(),NOW());

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'salary:subsidy:%';

-- ========== 六、菜单：薪酬管理（hr:salary）-> 补助标准配置 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21 LIMIT 1), '补助标准配置', '/hr/salary/subsidy', 'el-icon-price-tag', 'salary:subsidy:view', 27, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='salary:subsidy:view' AND deleted_at IS NULL);
