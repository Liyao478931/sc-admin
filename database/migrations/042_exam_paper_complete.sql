-- =====================================================
-- 042_exam_paper_complete.sql  试卷配置模块补全（幂等可重复执行）
-- 补建 试卷/考试记录/答卷 三表（040 未执行时自包含）+ 参数 + 菜单
-- =====================================================

-- ========== 一、试卷表（含 question_config 列，幂等） ==========
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
  `question_config`  json         DEFAULT NULL COMMENT '组卷配置(自动组卷:题型数量/难度比例)',
  `status`           varchar(20)  NOT NULL DEFAULT 'draft' COMMENT '状态 draft草稿 published已发布',
  `create_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`      datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_paper_code` (`paper_code`),
  KEY `idx_training_type_id` (`training_type_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试试卷';

-- 兼容：表已存在但缺 question_config 列时补列（幂等）
SET @has_col = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE table_schema=DATABASE() AND table_name='safety_exam_paper' AND column_name='question_config');
SET @sql_col = IF(@has_col=0,
  'ALTER TABLE `safety_exam_paper` ADD COLUMN `question_config` json DEFAULT NULL COMMENT ''组卷配置(自动组卷:题型数量/难度比例)'' AFTER `question_ids`',
  'SET @col_skip = 1');
PREPARE stmt_col FROM @sql_col; EXECUTE stmt_col; DEALLOCATE PREPARE stmt_col;

-- ========== 二、考试记录表（幂等，供考试管理/删除保护使用） ==========
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

-- ========== 三、考生答卷表（幂等） ==========
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

-- ========== 四、系统参数（settings + system_params，幂等） ==========
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('exam_paper_code_prefix','P','试卷编号前缀','safety','string','试卷编号前缀（P-YYYYMMDD-XXXX）',72,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、菜单：培训考试 → 试卷配置（幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'试卷配置','/safety/training/exam/paper','el-icon-document-checked','safety:training:exam:list',2,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:training:exam:list' AND m.`path`='/safety/training/exam' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:training:exam:list' AND x.`path`='/safety/training/exam/paper' AND x.`deleted_at` IS NULL);
