-- =====================================================
-- 041_exam_question_complete.sql
-- 题库管理模块补全：建表(幂等) + 补索引 + 字典 + 参数 + 题库管理菜单 + 权限(幂等)
-- 兼容 040 已执行/未执行两种情况，可重复执行
-- =====================================================

-- ========== 一、题库表（幂等，040已执行则跳过） ==========
CREATE TABLE IF NOT EXISTS `safety_exam_question` (
  `id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `question_code`  varchar(50)  NOT NULL COMMENT '题目编号 Q-YYYYMMDD-XXXX',
  `question_type`  varchar(20)  NOT NULL COMMENT '题型 single/multiple/judge',
  `question_text`  text         NOT NULL COMMENT '题目内容',
  `options`        json         NOT NULL COMMENT '选项列表 [{"label":"A","text":"..."}]',
  `answer`         varchar(50)  NOT NULL COMMENT '正确答案（单选A/多选A,B/判断"正确"或"错误"）',
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

-- ========== 二、补 category_id 普通索引（不存在才添加，幂等） ==========
SET @has_idx = (SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema = DATABASE() AND table_name = 'safety_exam_question' AND index_name = 'idx_category_id');
SET @sql_idx = IF(@has_idx = 0,
  'ALTER TABLE `safety_exam_question` ADD INDEX `idx_category_id` (`category_id`)', 'SET @idx_skip = 1');
PREPARE stmt_idx FROM @sql_idx; EXECUTE stmt_idx; DEALLOCATE PREPARE stmt_idx;

-- ========== 三、数据字典（幂等） ==========
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

-- ========== 四、系统参数（settings 运行时 + system_params 管理界面，幂等） ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('exam_question_import_template', '题型,题目内容,选项A,选项B,选项C,选项D,选项E,正确答案,解析,难度,分类编码', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('exam_question_code_prefix', 'Q', '题目编号前缀', 'safety', 'string', '题目编号前缀（Q-YYYYMMDD-XXXX）', 70, 0, 1, NOW(), NOW()),
('exam_question_import_template', '题型,题目内容,选项A,选项B,选项C,选项D,选项E,正确答案,解析,难度,分类编码', '导入模板字段映射', 'safety', 'string', '题目 Excel 导入模板列', 71, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、权限定义（幂等） ==========
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

-- ========== 六、超级管理员授权（幂等） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('safety:training:exam:list','safety:training:exam:query','safety:training:exam:add',
                   'safety:training:exam:edit','safety:training:exam:delete','safety:training:exam:export');

-- ========== 七、侧边栏菜单（安全培训 → 培训考试 → 题库管理） ==========
-- 1) 培训考试（父菜单，若 040 未执行则补插）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '培训考试', '/safety/training/exam', 'el-icon-edit-outline', 'safety:training:exam:list', 5, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:exam:list' AND x.`path` = '/safety/training/exam' AND x.`deleted_at` IS NULL);
-- 2) 题库管理（子菜单）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '题库管理', '/safety/training/exam/question', 'el-icon-document', 'safety:training:exam:list', 1, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'safety:training:exam:list' AND m.`path` = '/safety/training/exam' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'safety:training:exam:list' AND x.`path` = '/safety/training/exam/question' AND x.`deleted_at` IS NULL);
