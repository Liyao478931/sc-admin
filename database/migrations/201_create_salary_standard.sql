-- 201_create_salary_standard.sql
-- 薪酬标准表（人事管理 -> 薪酬管理 -> 薪酬标准表）
-- 参考《大运能董发（2025）16号关于调整薪酬方案的通知》，29 个岗位等级
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='salary:standard:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'salary:standard:%');
--   DELETE FROM permissions WHERE code LIKE 'salary:standard:%';
--   DROP TABLE IF EXISTS salary_standard;

-- ========== 一、薪酬标准表 ==========
CREATE TABLE IF NOT EXISTS `salary_standard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `position_code` varchar(20) NOT NULL COMMENT '岗位编码',
  `position_name` varchar(50) NOT NULL COMMENT '岗位名称',
  `category` varchar(10) DEFAULT NULL COMMENT '等级类别（A/B）',
  `basic_wage` decimal(15,2) DEFAULT 0 COMMENT '基本工资（元/月）',
  `position_wage` decimal(15,2) DEFAULT 0 COMMENT '岗位工资（元/月）',
  `daily_assessment` decimal(15,2) DEFAULT 0 COMMENT '日常考核工资（元/月）',
  `effective_year` int(11) NOT NULL COMMENT '生效年份',
  `sort` int(11) DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) DEFAULT 1 COMMENT '0=停用 1=启用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_position_code_year` (`position_code`, `effective_year`),
  KEY `idx_effective_year` (`effective_year`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='薪酬标准表';

-- ========== 二、29 个岗位初始数据（2026 年） ==========
INSERT INTO `salary_standard` (`position_code`,`position_name`,`category`,`basic_wage`,`position_wage`,`daily_assessment`,`effective_year`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('A-01','董事长','A',3881.00,2268.00,9800.00,2026,1,1,NOW(),NOW()),
('A-02','经理','B',3548.00,2074.00,8960.00,2026,2,1,NOW(),NOW()),
('A-03','副经理','A',3216.00,1879.00,8120.00,2026,3,1,NOW(),NOW()),
('B-01','一类科长A','A',1705.00,996.00,4305.00,2026,4,1,NOW(),NOW()),
('B-02','一类科长B','B',1611.00,941.00,4067.00,2026,5,1,NOW(),NOW()),
('B-03','二类科长A','A',1608.00,940.00,4060.00,2026,6,1,NOW(),NOW()),
('B-04','二类科长B','B',1514.00,885.00,3822.00,2026,7,1,NOW(),NOW()),
('B-05','一类副科长A','A',1444.00,844.00,3647.00,2026,8,1,NOW(),NOW()),
('B-06','一类副科长B','B',1350.00,789.00,3409.00,2026,9,1,NOW(),NOW()),
('B-07','二类副科长A','A',1464.00,855.00,3696.00,2026,10,1,NOW(),NOW()),
('B-08','二类副科长B','B',1369.00,800.00,3458.00,2026,11,1,NOW(),NOW()),
('C-01','一类一级科员A','A',2017.00,1179.00,3735.00,2026,12,1,NOW(),NOW()),
('C-02','一类一级科员B','B',1875.00,1096.00,3473.00,2026,13,1,NOW(),NOW()),
('C-03','一类二级科员A','A',1663.00,972.00,3080.00,2026,14,1,NOW(),NOW()),
('C-04','一类二级科员B','B',1522.00,889.00,2818.00,2026,15,1,NOW(),NOW()),
('C-05','一类三级科员A','A',1168.00,683.00,2164.00,2026,16,1,NOW(),NOW()),
('C-06','一类三级科员B','B',1027.00,600.00,1902.00,2026,17,1,NOW(),NOW()),
('C-07','一类四级科员',NULL,744.00,435.00,1378.00,2026,18,1,NOW(),NOW()),
('C-08','二类一级科员A','A',1734.00,1013.00,3211.00,2026,19,1,NOW(),NOW()),
('C-09','二类一级科员B','B',1593.00,931.00,2949.00,2026,20,1,NOW(),NOW()),
('C-10','二类二级科员A','A',1380.00,807.00,2556.00,2026,21,1,NOW(),NOW()),
('C-11','二类二级科员B','B',1239.00,724.00,2295.00,2026,22,1,NOW(),NOW()),
('C-12','二类三级科员A','A',1027.00,600.00,1902.00,2026,23,1,NOW(),NOW()),
('C-13','二类三级科员B','B',886.00,518.00,1640.00,2026,24,1,NOW(),NOW()),
('C-14','二类四级科员',NULL,603.00,352.00,1117.00,2026,25,1,NOW(),NOW()),
('D-01','一级岗位工',NULL,1767.00,1033.00,3273.00,2026,26,1,NOW(),NOW()),
('D-02','二级岗位工',NULL,1555.00,909.00,2880.00,2026,27,1,NOW(),NOW()),
('D-03','三级岗位工',NULL,1272.00,744.00,2356.00,2026,28,1,NOW(),NOW()),
('D-04','四级岗位工',NULL,848.00,496.00,1571.00,2026,29,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `position_name`=VALUES(`position_name`),`category`=VALUES(`category`),
`basic_wage`=VALUES(`basic_wage`),`position_wage`=VALUES(`position_wage`),
`daily_assessment`=VALUES(`daily_assessment`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

-- ========== 三、权限（6 个） ==========
INSERT IGNORE INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('薪酬标准表','salary:standard:view',2,0,'hr','/hr/salary/standard','el-icon-s-data',NULL,201,1,1,'薪酬标准表-查看（菜单）',NOW(),NOW()),
('薪酬标准新增','salary:standard:create',2,0,'hr',NULL,NULL,NULL,202,1,1,'新增薪酬标准',NOW(),NOW()),
('薪酬标准编辑','salary:standard:edit',2,0,'hr',NULL,NULL,NULL,203,1,1,'编辑薪酬标准',NOW(),NOW()),
('薪酬标准删除','salary:standard:delete',2,0,'hr',NULL,NULL,NULL,204,1,1,'删除薪酬标准',NOW(),NOW()),
('薪酬标准导入','salary:standard:import',2,0,'hr',NULL,NULL,NULL,205,1,1,'导入薪酬标准',NOW(),NOW()),
('薪酬标准导出','salary:standard:export',2,0,'hr',NULL,NULL,NULL,206,1,1,'导出薪酬标准',NOW(),NOW());

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'salary:standard:%';

-- ========== 四、菜单：薪酬管理（hr:salary）-> 薪酬标准表 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21 LIMIT 1), '薪酬标准表', '/hr/salary/standard', 'el-icon-s-data', 'salary:standard:view', 25, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='salary:standard:view' AND deleted_at IS NULL);
