-- =====================================================
-- 084_create_ai_publish.sql
-- AI 智能平台：智能体发布
--   1. 两张核心表：ai_agent_versions（版本）/ ai_agent_publish_approvals（审批记录）
--   2. 数据字典（发布状态/审批状态/发布渠道/发布类型）
--   3. 系统参数（审批开关/默认审批人/灰度观察期/最大版本数/安全扫描开关）
--   4. 权限（ai:agent:publish 系列）
--   5. 菜单（智能体中心 → 智能体发布，hidden 由前端路由控制）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、两张核心表 ==========
CREATE TABLE IF NOT EXISTS `ai_agent_versions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `version_id` varchar(32) NOT NULL DEFAULT '' COMMENT '版本唯一标识(UUID)',
  `agent_id` varchar(32) NOT NULL DEFAULT '' COMMENT '智能体ID（关联 ai_agents）',
  `version_number` varchar(20) NOT NULL DEFAULT '' COMMENT '版本号（如 1.0.0）',
  `version_name` varchar(100) DEFAULT NULL COMMENT '版本名称',
  `version_desc` varchar(500) DEFAULT NULL COMMENT '版本描述',
  `config_snapshot` json NOT NULL COMMENT '配置快照（该版本的完整智能体配置）',
  `status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '状态：draft/reviewing/approved/published/offline',
  `publish_type` varchar(20) DEFAULT NULL COMMENT '发布类型：full（全量）/gray（灰度）',
  `gray_ratio` int(11) NOT NULL DEFAULT 0 COMMENT '灰度比例（0-100）',
  `gray_users` json DEFAULT NULL COMMENT '灰度用户列表(JSON数组)',
  `channels` json DEFAULT NULL COMMENT '发布渠道配置(JSON，各渠道配置与状态)',
  `is_current` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否当前版本：1是 0否',
  `published_by` int(11) DEFAULT NULL COMMENT '发布人ID',
  `published_by_name` varchar(50) DEFAULT NULL COMMENT '发布人姓名',
  `published_at` datetime DEFAULT NULL COMMENT '发布时间',
  `reviewed_by` int(11) DEFAULT NULL COMMENT '审核人ID',
  `reviewed_by_name` varchar(50) DEFAULT NULL COMMENT '审核人姓名',
  `reviewed_at` datetime DEFAULT NULL COMMENT '审核时间',
  `review_comment` varchar(500) DEFAULT NULL COMMENT '审核意见',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_version_id` (`version_id`),
  KEY `idx_agent_status` (`agent_id`, `status`),
  KEY `idx_agent_create` (`agent_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI智能体版本表';

CREATE TABLE IF NOT EXISTS `ai_agent_publish_approvals` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `approval_id` varchar(32) NOT NULL DEFAULT '' COMMENT '审批唯一标识(UUID)',
  `version_id` varchar(32) NOT NULL DEFAULT '' COMMENT '版本ID（关联 ai_agent_versions）',
  `agent_id` varchar(32) NOT NULL DEFAULT '' COMMENT '智能体ID（关联 ai_agents）',
  `applicant_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请人ID',
  `applicant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '申请人姓名（冗余）',
  `approval_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '审批状态：pending/approved/rejected/canceled',
  `approver_id` int(11) DEFAULT NULL COMMENT '审批人ID',
  `approver_name` varchar(50) DEFAULT NULL COMMENT '审批人姓名',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approval_comment` varchar(500) DEFAULT NULL COMMENT '审批意见',
  `security_scan_result` json DEFAULT NULL COMMENT '安全扫描结果(JSON)',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_approval_id` (`approval_id`),
  KEY `idx_version_id` (`version_id`),
  KEY `idx_agent_status` (`agent_id`, `approval_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI智能体发布审批记录表';

-- ========== 二、数据字典 ==========

-- 1. agent_publish_status 发布状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('发布状态','agent_publish_status','智能体发布状态',84,1,NOW(),NOW());
SET @dp1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='agent_publish_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dp1,'草稿','draft',1,'info',1,NOW(),NOW()),
(@dp1,'审核中','reviewing',2,'warning',1,NOW(),NOW()),
(@dp1,'审核通过','approved',3,'success',1,NOW(),NOW()),
(@dp1,'已发布','published',4,'primary',1,NOW(),NOW()),
(@dp1,'已下线','offline',5,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. agent_approval_status 审批状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('审批状态','agent_approval_status','智能体发布审批状态',85,1,NOW(),NOW());
SET @dp2 = (SELECT `id` FROM `dictionary_types` WHERE `code`='agent_approval_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dp2,'待审批','pending',1,'warning',1,NOW(),NOW()),
(@dp2,'已通过','approved',2,'success',1,NOW(),NOW()),
(@dp2,'已驳回','rejected',3,'danger',1,NOW(),NOW()),
(@dp2,'已取消','canceled',4,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. agent_publish_channel 发布渠道
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('发布渠道','agent_publish_channel','智能体发布渠道',86,1,NOW(),NOW());
SET @dp3 = (SELECT `id` FROM `dictionary_types` WHERE `code`='agent_publish_channel' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dp3,'Web API','webapi',1,'primary',1,NOW(),NOW()),
(@dp3,'钉钉','dingtalk',2,'success',1,NOW(),NOW()),
(@dp3,'企业微信','workwx',3,'success',1,NOW(),NOW()),
(@dp3,'飞书','feishu',4,'warning',1,NOW(),NOW()),
(@dp3,'微信公众号','wechat',5,'success',1,NOW(),NOW()),
(@dp3,'Web嵌入','webembed',6,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 4. agent_publish_type 发布类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('发布类型','agent_publish_type','智能体发布类型',87,1,NOW(),NOW());
SET @dp4 = (SELECT `id` FROM `dictionary_types` WHERE `code`='agent_publish_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dp4,'全量发布','full',1,'success',1,NOW(),NOW()),
(@dp4,'灰度发布','gray',2,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('agent_publish_require_approval','发布需要审批','true','boolean','ai','发布智能体是否需要审批',30,1,0,NOW(),NOW()),
('agent_publish_default_approver','默认审批人ID列表','[]','json','ai','发布审批默认审批人ID列表',31,1,0,NOW(),NOW()),
('agent_publish_gray_duration_days','灰度观察天数','3','number','ai','灰度发布观察期天数',32,1,0,NOW(),NOW()),
('agent_publish_max_versions','最大保留版本数','20','number','ai','每个智能体最多保留的版本数',33,1,0,NOW(),NOW()),
('agent_publish_safety_check_enabled','启用安全扫描','true','boolean','ai','发布前自动安全扫描开关',34,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('智能体发布','ai:agent:publish',1,0,'ai','/ai/agent/publish','el-icon-s-promotion',NULL,7,1,1,'智能体发布查看',NOW(),NOW()),
('智能体发布编辑','ai:agent:publish:edit',2,0,'ai',NULL,NULL,NULL,8,1,1,'创建版本/提交审核/执行发布/回滚',NOW(),NOW()),
('智能体发布审批','ai:agent:publish:approve',2,0,'ai',NULL,NULL,NULL,9,1,1,'审批通过/驳回',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:agent:publish','ai:agent:publish:edit','ai:agent:publish:approve');

-- ========== 五、菜单（智能体中心 → 智能体发布，hidden 由前端路由控制） ==========
SET @ai_agent_id = (SELECT id FROM menus WHERE permission='ai:agent:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_agent_id, '智能体发布', '/ai/agent/publish', 'el-icon-s-promotion', 'ai:agent:publish', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:agent:publish' AND deleted_at IS NULL);
