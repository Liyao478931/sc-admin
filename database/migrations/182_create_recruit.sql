-- 182_create_recruit.sql
-- 人事管理「招聘管理」：5 表 + 7 权限 + 6 菜单 + 2 统一审批流程
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission LIKE 'hr:recruit:%';
--   DELETE FROM menus WHERE name='招聘管理' AND parent_id=21;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:recruit:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:recruit:%';
--   DELETE FROM approval_flow WHERE biz_type IN ('recruit_requirement','recruit_offer');
--   DROP TABLE IF EXISTS recruit_offer;
--   DROP TABLE IF EXISTS recruit_interview;
--   DROP TABLE IF EXISTS recruit_resume;
--   DROP TABLE IF EXISTS recruit_position;
--   DROP TABLE IF EXISTS recruit_requirement;

-- ========== 一、招聘需求表 ==========
CREATE TABLE IF NOT EXISTS `recruit_requirement` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `requirement_no` varchar(50) NOT NULL DEFAULT '' COMMENT '需求编号 RQ+YYYYMMDD+4位流水',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '需求部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '需求部门名称（冗余）',
  `position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '招聘岗位名称',
  `position_category` tinyint(1) NOT NULL DEFAULT 5 COMMENT '岗位类别：1工人 2技术员 3业务员 4管理人员 5其他',
  `position_count` int(11) NOT NULL DEFAULT 1 COMMENT '招聘人数',
  `urgency` tinyint(1) NOT NULL DEFAULT 1 COMMENT '紧急程度：1普通 2紧急 3特急',
  `reason` varchar(500) DEFAULT NULL COMMENT '招聘原因',
  `requirements` text COMMENT '岗位要求（技能、经验、学历等）',
  `salary_range_min` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '薪资范围-最低',
  `salary_range_max` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '薪资范围-最高',
  `expected_join_date` date DEFAULT NULL COMMENT '期望到岗日期',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '需求状态：0草稿 1待审批 2已通过 3已驳回 4已关闭',
  `approval_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联统一审批实例ID',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_no` (`requirement_no`),
  KEY `idx_status` (`status`),
  KEY `idx_dept` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='招聘需求表';

-- ========== 二、招聘职位表 ==========
CREATE TABLE IF NOT EXISTS `recruit_position` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `position_no` varchar(50) NOT NULL DEFAULT '' COMMENT '职位编号 POS+YYYYMMDD+4位流水',
  `requirement_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联招聘需求ID（可选）',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '所属部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '部门名称（冗余）',
  `position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '职位名称',
  `position_category` tinyint(1) NOT NULL DEFAULT 5 COMMENT '岗位类别：1工人 2技术员 3业务员 4管理人员 5其他',
  `recruit_count` int(11) NOT NULL DEFAULT 1 COMMENT '招聘人数',
  `hired_count` int(11) NOT NULL DEFAULT 0 COMMENT '已录用人数',
  `work_location` varchar(100) DEFAULT NULL COMMENT '工作地点',
  `job_description` text COMMENT '职位描述',
  `requirements` text COMMENT '任职要求',
  `salary_range_min` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '薪资范围-最低',
  `salary_range_max` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '薪资范围-最高',
  `publish_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '发布状态：0未发布 1已发布 2已下架 3已关闭',
  `publish_time` datetime DEFAULT NULL COMMENT '发布时间',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `channel` varchar(50) DEFAULT NULL COMMENT '发布渠道',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_position_no` (`position_no`),
  KEY `idx_publish` (`publish_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='招聘职位表';

-- ========== 三、简历表 ==========
CREATE TABLE IF NOT EXISTS `recruit_resume` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `resume_no` varchar(50) NOT NULL DEFAULT '' COMMENT '简历编号 RS+YYYYMMDD+4位流水',
  `position_id` int(11) NOT NULL DEFAULT 0 COMMENT '应聘职位ID',
  `position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '职位名称（冗余）',
  `candidate_name` varchar(50) NOT NULL DEFAULT '' COMMENT '应聘者姓名',
  `candidate_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '联系电话',
  `candidate_email` varchar(100) DEFAULT NULL COMMENT '电子邮箱',
  `candidate_gender` tinyint(1) NOT NULL DEFAULT 0 COMMENT '性别：1男 2女',
  `candidate_age` int(11) NOT NULL DEFAULT 0 COMMENT '年龄',
  `education` tinyint(1) NOT NULL DEFAULT 0 COMMENT '学历：1初中及以下 2高中/中专 3大专 4本科 5硕士及以上',
  `school` varchar(100) DEFAULT NULL COMMENT '毕业院校',
  `major` varchar(100) DEFAULT NULL COMMENT '专业',
  `graduation_year` int(11) NOT NULL DEFAULT 0 COMMENT '毕业年份',
  `work_experience` int(11) NOT NULL DEFAULT 0 COMMENT '工作年限（年）',
  `last_company` varchar(100) DEFAULT NULL COMMENT '上一份工作单位',
  `last_position` varchar(100) DEFAULT NULL COMMENT '上一份工作岗位',
  `skills` text COMMENT '技能特长',
  `resume_file` varchar(500) DEFAULT NULL COMMENT '简历附件文件路径',
  `source` tinyint(1) NOT NULL DEFAULT 1 COMMENT '简历来源：1招聘网站 2内部推荐 3校园招聘 4人才市场 5自主投递 6其他',
  `recommender` varchar(50) DEFAULT NULL COMMENT '推荐人姓名（内部推荐时填写）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '简历状态：0待筛选 1待面试 2待复试 3已录用 4淘汰 5已放弃',
  `screening_remark` varchar(500) DEFAULT NULL COMMENT '筛选备注',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_resume_no` (`resume_no`),
  KEY `idx_status` (`status`),
  KEY `idx_position` (`position_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='简历表';

-- ========== 四、面试记录表 ==========
CREATE TABLE IF NOT EXISTS `recruit_interview` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `resume_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联简历ID',
  `resume_no` varchar(50) NOT NULL DEFAULT '' COMMENT '简历编号（冗余）',
  `candidate_name` varchar(50) NOT NULL DEFAULT '' COMMENT '应聘者姓名（冗余）',
  `position_id` int(11) NOT NULL DEFAULT 0 COMMENT '应聘职位ID（冗余）',
  `position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '职位名称（冗余）',
  `interview_round` tinyint(1) NOT NULL DEFAULT 1 COMMENT '面试轮次：1初试 2复试 3终试',
  `interview_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '面试类型：1现场 2电话 3视频',
  `interview_time` datetime DEFAULT NULL COMMENT '面试时间',
  `interview_duration` int(11) NOT NULL DEFAULT 60 COMMENT '面试时长（分钟）',
  `interviewer_id` int(11) NOT NULL DEFAULT 0 COMMENT '面试官ID',
  `interviewer_name` varchar(50) NOT NULL DEFAULT '' COMMENT '面试官姓名（冗余）',
  `interview_location` varchar(200) DEFAULT NULL COMMENT '面试地点',
  `interview_remark` varchar(500) DEFAULT NULL COMMENT '面试备注',
  `result` tinyint(1) NOT NULL DEFAULT 0 COMMENT '面试结果：0待评价 1通过 2不通过 3待定',
  `evaluation` text COMMENT '面试评价',
  `score` decimal(3,1) NOT NULL DEFAULT 0 COMMENT '评分（1-5分）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '记录状态：0已安排 1已完成 2已取消',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_resume` (`resume_id`),
  KEY `idx_interviewer` (`interviewer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='面试记录表';

-- ========== 五、录用审批表 ==========
CREATE TABLE IF NOT EXISTS `recruit_offer` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `offer_no` varchar(50) NOT NULL DEFAULT '' COMMENT '录用编号 OF+YYYYMMDD+4位流水',
  `resume_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联简历ID',
  `resume_no` varchar(50) NOT NULL DEFAULT '' COMMENT '简历编号（冗余）',
  `candidate_name` varchar(50) NOT NULL DEFAULT '' COMMENT '应聘者姓名（冗余）',
  `position_id` int(11) NOT NULL DEFAULT 0 COMMENT '录用职位ID',
  `position_name` varchar(100) NOT NULL DEFAULT '' COMMENT '录用职位名称（冗余）',
  `department_id` int(11) NOT NULL DEFAULT 0 COMMENT '录用部门ID',
  `department_name` varchar(100) NOT NULL DEFAULT '' COMMENT '录用部门名称（冗余）',
  `offer_salary` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '录用薪资（元/月）',
  `offer_date` date DEFAULT NULL COMMENT '录用日期',
  `expected_join_date` date DEFAULT NULL COMMENT '预计入职日期',
  `probation_period` int(11) NOT NULL DEFAULT 3 COMMENT '试用期（月）',
  `probation_salary` decimal(12,2) NOT NULL DEFAULT 0 COMMENT '试用期薪资',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '录用状态：0草稿 1待审批 2已通过 3已驳回 4已接受 5已拒绝',
  `approval_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联统一审批实例ID',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approval_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `notice_time` datetime DEFAULT NULL COMMENT '录用通知发送时间',
  `accept_time` datetime DEFAULT NULL COMMENT '接受时间（生成档案后）',
  `reject_time` datetime DEFAULT NULL COMMENT '拒绝时间',
  `reject_reason` varchar(500) DEFAULT NULL COMMENT '拒绝原因',
  `employee_profile_id` int(11) NOT NULL DEFAULT 0 COMMENT '生成员工档案ID',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_offer_no` (`offer_no`),
  KEY `idx_resume` (`resume_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='录用审批表';

-- ========== 六、权限（7 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('招聘管理','hr:recruit:view',2,0,'hr','/hr/recruit/requirement','el-icon-s-custom',NULL,200,1,1,'招聘管理-查看（菜单）',NOW(),NOW()),
('招聘新增','hr:recruit:add',2,0,'hr',NULL,NULL,NULL,201,1,1,'新增招聘需求/职位/简历/录用',NOW(),NOW()),
('招聘编辑','hr:recruit:edit',2,0,'hr',NULL,NULL,NULL,202,1,1,'编辑招聘记录',NOW(),NOW()),
('招聘删除','hr:recruit:delete',2,0,'hr',NULL,NULL,NULL,203,1,1,'删除招聘记录',NOW(),NOW()),
('招聘审批','hr:recruit:approve',2,0,'hr',NULL,NULL,NULL,204,1,1,'审批招聘相关申请',NOW(),NOW()),
('招聘导出','hr:recruit:export',2,0,'hr',NULL,NULL,NULL,205,1,1,'导出招聘数据',NOW(),NOW()),
('招聘统计','hr:recruit:statistics:view',2,0,'hr',NULL,NULL,NULL,206,1,1,'招聘统计数据',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'hr:recruit:%';

-- ========== 七、菜单：人事管理（id=21）-> 招聘管理（目录）-> 5 叶子 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 21, '招聘管理', NULL, 'el-icon-s-custom', '', 50, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='招聘管理' AND parent_id=21 AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='招聘管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '招聘需求', '/hr/recruit/requirement', 'el-icon-document', 'hr:recruit:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/hr/recruit/requirement' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='招聘管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '职位管理', '/hr/recruit/position', 'el-icon-office-building', 'hr:recruit:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/hr/recruit/position' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='招聘管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '简历管理', '/hr/recruit/resume', 'el-icon-user', 'hr:recruit:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/hr/recruit/resume' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='招聘管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '录用管理', '/hr/recruit/offer', 'el-icon-s-check', 'hr:recruit:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/hr/recruit/offer' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='招聘管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '招聘统计', '/hr/recruit/statistics', 'el-icon-data-analysis', 'hr:recruit:statistics:view', 50, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/hr/recruit/statistics' AND deleted_at IS NULL);

-- ========== 八、统一审批流程（2 个） ==========
INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`module_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('recruit_requirement', '招聘需求', '人事管理', 1, 48, '[{"node_name":"人事管理员审批","approver_type":"role","approver_value":"super_admin","approver_name":"管理员","timeout_hours":48,"timeout_action":"remind"}]', 1, '招聘需求审批', NOW(), NOW()),
('recruit_offer', '录用审批', '人事管理', 1, 48, '[{"node_name":"人事管理员审批","approver_type":"role","approver_value":"super_admin","approver_name":"管理员","timeout_hours":48,"timeout_action":"remind"}]', 1, '录用审批', NOW(), NOW());
