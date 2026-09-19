-- =====================================================
-- survey_module.sql
-- 问卷管理模块：问卷表 + 题目表 + 答卷表 + 权限 + 菜单
-- 适用系统：SC Admin (ThinkPHP 8.0 + Vue 2.7)
-- =====================================================

-- ---------- 1. 问卷主表 ----------
CREATE TABLE IF NOT EXISTS `survey` (
  `id`           int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title`        varchar(200)  NOT NULL COMMENT '问卷标题',
  `description`  varchar(2000) NOT NULL DEFAULT '' COMMENT '问卷说明/引导语',
  `status`       tinyint(1)    NOT NULL DEFAULT '0' COMMENT '状态：0草稿 1发布中 2已停止',
  `anonymous`    tinyint(1)    NOT NULL DEFAULT '1' COMMENT '是否匿名：1匿名 0实名',
  `need_login`   tinyint(1)    NOT NULL DEFAULT '0' COMMENT '是否需登录才能填写：1是 0否',
  `limit_once`   tinyint(1)    NOT NULL DEFAULT '0' COMMENT '同一用户限填一次：1是 0否',
  `start_time`   datetime      DEFAULT NULL COMMENT '生效开始时间（null不限）',
  `end_time`     datetime      DEFAULT NULL COMMENT '生效结束时间（null不限）',
  `created_by`   int(11) unsigned NOT NULL DEFAULT '0' COMMENT '创建人ID',
  `created_name` varchar(50)   NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `fill_count`   int(11) unsigned NOT NULL DEFAULT '0' COMMENT '已提交份数（冗余计数）',
  `create_time`  datetime      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`  datetime      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`  datetime      DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_delete_time` (`delete_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='问卷主表';

-- ---------- 2. 问卷题目表 ----------
CREATE TABLE IF NOT EXISTS `survey_question` (
  `id`         int(11) unsigned NOT NULL AUTO_INCREMENT,
  `survey_id`  int(11) unsigned NOT NULL COMMENT '所属问卷ID',
  `type`       varchar(10) NOT NULL DEFAULT 'radio' COMMENT '题型：radio单选 multi多选 text文本 score评分',
  `title`      varchar(500) NOT NULL COMMENT '题目内容',
  `options`    json DEFAULT NULL COMMENT '选项：radio/multi存选项数组，score存[{label,max}]，text为null',
  `required`   tinyint(1)  NOT NULL DEFAULT '1' COMMENT '是否必填：1是 0否',
  `sort`       int(11)     NOT NULL DEFAULT '0' COMMENT '排序（升序）',
  `create_time` datetime   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_survey_id` (`survey_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='问卷题目表';

-- ---------- 3. 答卷表 ----------
CREATE TABLE IF NOT EXISTS `survey_answer` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
  `survey_id`   int(11) unsigned NOT NULL COMMENT '问卷ID',
  `user_id`     int(11) unsigned NOT NULL DEFAULT '0' COMMENT '填写人ID（匿名/未登录为0）',
  `user_name`   varchar(50) NOT NULL DEFAULT '' COMMENT '填写人姓名（匿名不记）',
  `answers`     json NOT NULL COMMENT '答案JSON：{题目id: 值}，radio=字符串 multi=数组 text=字符串 score={dims:[],total:n}',
  `total_score` int(11) NOT NULL DEFAULT '0' COMMENT '总分（评分题汇总，无评分题为0）',
  `source_ip`   varchar(45) NOT NULL DEFAULT '' COMMENT '提交IP',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_survey_id` (`survey_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='问卷答卷表';

-- ---------- 4. 权限定义 ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('问卷管理',       'survey:view',   1, 0, '问卷管理', '/survey/list', 'el-icon-document-checked', NULL, 200, 1, 1, '问卷管理菜单/列表', NOW(), NOW()),
('问卷统计',       'survey:stats',  1, 0, '问卷管理', '/survey/stats', 'el-icon-data-analysis', NULL, 210, 1, 1, '问卷统计查看', NOW(), NOW()),
('新建问卷',       'survey:add',    2, 0, '问卷管理', '/survey/list', NULL, NULL, 220, 1, 1, '新建问卷', NOW(), NOW()),
('编辑问卷',       'survey:edit',   2, 0, '问卷管理', '/survey/list', NULL, NULL, 230, 1, 1, '编辑问卷/题目', NOW(), NOW()),
('删除问卷',       'survey:delete', 2, 0, '问卷管理', '/survey/list', NULL, NULL, 240, 1, 1, '删除问卷', NOW(), NOW()),
('导出答卷',       'survey:export', 2, 0, '问卷管理', '/survey/list', NULL, NULL, 250, 1, 1, '导出答卷CSV', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 5. 权限分配给超级管理员角色 ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('survey:view','survey:stats','survey:add','survey:edit','survey:delete','survey:export');

-- ---------- 6. 侧边栏菜单 ----------
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT 0, '问卷管理', '/survey/list', 'el-icon-document-checked', 'survey:view', 200, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'survey:view' AND x.`deleted_at` IS NULL);

INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT 0, '问卷统计', '/survey/stats', 'el-icon-data-analysis', 'survey:stats', 210, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'survey:stats' AND x.`deleted_at` IS NULL);
