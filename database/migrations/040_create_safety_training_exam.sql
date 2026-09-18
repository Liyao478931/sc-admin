-- =====================================================
-- 040_create_safety_training_exam.sql
-- 培训考试模块：题库 + 试卷 + 考试记录 + 考生答卷 四表 + 字典 + 参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、题库表 ==========
CREATE TABLE IF NOT EXISTS `safety_exam_question` (
  `id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `question_code`  varchar(50)  NOT NULL COMMENT '题目编号 Q-YYYYMMDD-XXXX',
  `question_type`  varchar(20)  NOT NULL COMMENT '题型 single/multiple/judge',
  `question_text`  text         NOT NULL COMMENT '题目内容',
  `options`        json         NOT NULL COMMENT '选项列表 [{"label":"A","text":"..."}]',
  `answer`         varchar(50)  NOT NULL COMMENT '正确答案（单选A/多选A,B/判断对/错）',
  `analysis`       text         DEFAULT NULL COMMENT '题目解析',
  `difficulty`     varchar(20)  NOT NULL DEFAULT 'normal' COMMENT '难度 easy/normal/hard',
  `category_id`    int(11)      DEFAULT NULL COMMENT '分类ID（培训类型）',
  `sort`           int(11)      NOT NULL DEFAULT 0 COMMENT '排序',
  `status`         tinyint(1)   NOT NULL DEFAULT 1 COMMENT '状态 1启用 0停用',
  `create_time`    datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`    datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_question_code` (`question_code`),
  KEY `idx_question_type` (`question_type`),
  KEY `idx_difficulty` (`difficulty`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试题库';

-- ========== 二、试卷表 ==========
CREATE TABLE IF NOT EXISTS `safety_exam_paper` (
  `id`               int(11) unsigned NOT NULL AUTO_INCREMENT,
  `paper_code`       varchar(50)  NOT NULL COMMENT '试卷编号 P-YYYYMMDD-XXXX',
  `paper_name`       varchar(100) NOT NULL COMMENT '试卷名称',
  `training_type_id` int(11)      DEFAULT NULL COMMENT '关联培训类型ID',
  `total_questions`  int(11)      NOT NULL DEFAULT 0 COMMENT '题目总数',
  `total_score`      int(11)      NOT NULL DEFAULT 100 COMMENT '总分',
  `pass_score`       int(11)      NOT NULL DEFAULT 60 COMMENT '及格分数',
  `duration_minutes` int(11)      NOT NULL DEFAULT 60 COMMENT '考试时长（分钟）',
  `question_ids`     json         DEFAULT NULL COMMENT '题目ID数组',
  `status`           varchar(20)  NOT NULL DEFAULT 'draft' COMMENT '状态 draft草稿 published已发布',
  `create_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`      datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_paper_code` (`paper_code`),
  KEY `idx_training_type_id` (`training_type_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试试卷';

-- ========== 三、考试记录表 ==========
CREATE TABLE IF NOT EXISTS `safety_exam_record` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `exam_code`          varchar(50)  NOT NULL COMMENT '考试编号 E-YYYYMMDD-XXXX',
  `paper_id`           int(11)      NOT NULL COMMENT '试卷ID',
  `paper_name`         varchar(100) NOT NULL COMMENT '试卷名称（冗余）',
  `training_record_id` int(11)      DEFAULT NULL COMMENT '培训记录ID',
  `exam_type`          varchar(20)  NOT NULL DEFAULT 'formal' COMMENT '考试类型 formal正式 practice练习',
  `start_time`         datetime     NOT NULL COMMENT '考试开始时间',
  `end_time`           datetime     NOT NULL COMMENT '考试结束时间',
  `duration_minutes`   int(11)      NOT NULL DEFAULT 60 COMMENT '考试时长（分钟）',
  `status`             varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态 pending/in_progress/ended',
  `total_participants` int(11)      NOT NULL DEFAULT 0 COMMENT '应考人数',
  `actual_participants` int(11)     NOT NULL DEFAULT 0 COMMENT '实考人数',
  `pass_count`         int(11)      NOT NULL DEFAULT 0 COMMENT '通过人数',
  `create_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_exam_code` (`exam_code`),
  KEY `idx_paper_id` (`paper_id`),
  KEY `idx_training_record_id` (`training_record_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试记录';

-- ========== 四、考生答卷表 ==========
CREATE TABLE IF NOT EXISTS `safety_exam_answer` (
  `id`            int(11) unsigned NOT NULL AUTO_INCREMENT,
  `exam_id`       int(11)      NOT NULL COMMENT '考试记录ID',
  `user_id`       int(11)      NOT NULL COMMENT '员工ID',
  `user_name`     varchar(50)  NOT NULL COMMENT '员工姓名（冗余）',
  `answers`       json         DEFAULT NULL COMMENT '答案列表 [{question_id,question_type,selected,is_correct}]',
  `score`         int(11)      NOT NULL DEFAULT 0 COMMENT '得分',
  `is_pass`       tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否合格',
  `submit_time`   datetime     DEFAULT NULL COMMENT '交卷时间',
  `exam_duration` int(11)      NOT NULL DEFAULT 0 COMMENT '答题耗时（秒）',
  `is_marked`     tinyint(1)   NOT NULL DEFAULT 1 COMMENT '是否已批改（自动）',
  `review_time`   datetime     DEFAULT NULL COMMENT '查看错题时间',
  `create_time`   datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`   datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_is_pass` (`is_pass`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考生答卷';

-- ========== 五、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('题目题型','exam_question_type','培训考试题目题型',86,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='exam_question_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'单选题','single',1,'primary',1,NOW(),NOW()),
(@dt1,'多选题','multiple',2,'warning',1,NOW(),NOW()),
(@dt1,'判断题','judge',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('题目难度','exam_difficulty','培训考试题目难度',87,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='exam_difficulty');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'简单','easy',1,'success',1,NOW(),NOW()),
(@dt2,'中等','normal',2,'warning',1,NOW(),NOW()),
(@dt2,'困难','hard',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('考试状态','exam_status','培训考试状态',88,1,NOW(),NOW());
SET @dt3=(SELECT id FROM dictionary_types WHERE code='exam_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt3,'待开始','pending',1,'info',1,NOW(),NOW()),
(@dt3,'进行中','in_progress',2,'primary',1,NOW(),NOW()),
(@dt3,'已结束','ended',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('考试类型','exam_type','培训考试类型',89,1,NOW(),NOW());
SET @dt4=(SELECT id FROM dictionary_types WHERE code='exam_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt4,'正式考试','formal',1,'danger',1,NOW(),NOW()),
(@dt4,'练习模式','practice',2,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 六、系统参数 ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('exam_question_code_prefix', 'Q',   NOW(), NOW()),
('exam_paper_code_prefix',    'P',   NOW(), NOW()),
('exam_record_code_prefix',   'E',   NOW(), NOW()),
('exam_max_retry_count',      '2',   NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('exam_question_code_prefix', 'Q', '题目编号前缀', 'safety', 'string', '题目编号前缀（Q-YYYYMMDD-XXXX）', 70, 0, 1, NOW(), NOW()),
('exam_paper_code_prefix',    'P', '试卷编号前缀', 'safety', 'string', '试卷编号前缀（P-YYYYMMDD-XXXX）', 71, 0, 1, NOW(), NOW()),
('exam_record_code_prefix',   'E', '考试编号前缀', 'safety', 'string', '考试编号前缀（E-YYYYMMDD-XXXX）', 72, 0, 1, NOW(), NOW()),
('exam_max_retry_count',      '2', '最大重考次数', 'safety', 'number', '员工最大重考次数', 73, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 七、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('培训考试查看',   'safety:training:exam:list',   1, 0, '安全培训', '/safety/training/exam', 'el-icon-edit-outline', NULL, 100, 1, 1, '查看培训考试', NOW(), NOW()),
('培训考试详情',   'safety:training:exam:query',  2, 0, '安全培训', '/safety/training/exam', NULL, NULL, 101, 1, 1, '查看考试详情', NOW(), NOW()),
('培训考试新增',   'safety:training:exam:add',    2, 0, '安全培训', '/safety/training/exam', NULL, NULL, 102, 1, 1, '新增题目/试卷/考试', NOW(), NOW()),
('培训考试编辑',   'safety:training:exam:edit',   2, 0, '安全培训', '/safety/training/exam', NULL, NULL, 103, 1, 1, '编辑题目/试卷/考试', NOW(), NOW()),
('培训考试删除',   'safety:training:exam:delete', 2, 0, '安全培训', '/safety/training/exam', NULL, NULL, 104, 1, 1, '删除题目/试卷', NOW(), NOW()),
('培训考试导出',   'safety:training:exam:export', 2, 0, '安全培训', '/safety/training/exam', NULL, NULL, 105, 1, 1, '导出题目/成绩', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 八、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:training:exam:list','safety:training:exam:query','safety:training:exam:add',
                   'safety:training:exam:edit','safety:training:exam:delete','safety:training:exam:export');

-- ========== 九、侧边栏菜单（安全培训下新增"培训考试"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '培训考试', '/safety/training/exam', 'el-icon-edit-outline', 'safety:training:exam:list', 5, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:exam:list' AND x.`deleted_at` IS NULL);
