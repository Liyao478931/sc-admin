-- =====================================================
-- 088_create_ai_search_test.sql
-- AI 智能平台：知识库 → 检索测试
--   1. 两张核心表：ai_search_test_records（检索记录）/ ai_search_schemas（检索方案）
--   2. 数据字典（检索模式）
--   3. 系统参数（默认top_k/阈值/最大top_k/历史保留/高亮）
--   4. 权限（ai:knowledge:search-test 系列）
--   5. 菜单（知识库 → 检索测试）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、两张核心表 ==========
CREATE TABLE IF NOT EXISTS `ai_search_test_records` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `record_id` varchar(32) NOT NULL DEFAULT '' COMMENT '记录唯一标识(UUID)',
  `kb_id` varchar(32) NOT NULL DEFAULT '' COMMENT '知识库ID',
  `kb_name` varchar(100) NOT NULL DEFAULT '' COMMENT '知识库名称（冗余）',
  `query_text` text NOT NULL COMMENT '查询文本',
  `search_mode` varchar(20) NOT NULL DEFAULT 'semantic' COMMENT '检索模式：semantic/keyword/hybrid',
  `top_k` int(11) NOT NULL DEFAULT 5 COMMENT '返回数量',
  `threshold` decimal(3,2) NOT NULL DEFAULT 0.60 COMMENT '相似度阈值',
  `semantic_weight` decimal(3,2) NOT NULL DEFAULT 0.50 COMMENT '语义权重（混合检索）',
  `keyword_weight` decimal(3,2) NOT NULL DEFAULT 0.50 COMMENT '关键词权重（混合检索）',
  `rerank_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否启用重排序',
  `result_count` int(11) NOT NULL DEFAULT 0 COMMENT '结果数量',
  `avg_score` decimal(5,4) NOT NULL DEFAULT 0 COMMENT '平均相关度得分',
  `max_score` decimal(5,4) NOT NULL DEFAULT 0 COMMENT '最高相关度得分',
  `search_duration` int(11) NOT NULL DEFAULT 0 COMMENT '检索耗时（毫秒）',
  `results` json DEFAULT NULL COMMENT '检索结果(JSON)',
  `user_feedback` json DEFAULT NULL COMMENT '用户反馈(JSON：每个结果的相关性标记)',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_record_id` (`record_id`),
  KEY `idx_kb_create` (`kb_id`, `create_time`),
  KEY `idx_mode_create` (`search_mode`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI检索测试记录表';

CREATE TABLE IF NOT EXISTS `ai_search_schemas` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `schema_id` varchar(32) NOT NULL DEFAULT '' COMMENT '方案唯一标识(UUID)',
  `schema_name` varchar(100) NOT NULL DEFAULT '' COMMENT '方案名称',
  `kb_id` varchar(32) NOT NULL DEFAULT '' COMMENT '知识库ID',
  `search_mode` varchar(20) NOT NULL DEFAULT 'semantic' COMMENT '检索模式',
  `top_k` int(11) NOT NULL DEFAULT 5 COMMENT '返回数量',
  `threshold` decimal(3,2) NOT NULL DEFAULT 0.60 COMMENT '相似度阈值',
  `semantic_weight` decimal(3,2) NOT NULL DEFAULT 0.50 COMMENT '语义权重',
  `keyword_weight` decimal(3,2) NOT NULL DEFAULT 0.50 COMMENT '关键词权重',
  `rerank_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否启用重排序',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认方案',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_schema_id` (`schema_id`),
  KEY `idx_kb_create` (`kb_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI检索方案表';

-- ========== 二、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('检索模式','search_mode','AI知识库检索模式',94,1,NOW(),NOW());
SET @ds1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='search_mode' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@ds1,'语义检索','semantic',1,'primary',1,NOW(),NOW()),
(@ds1,'关键词检索','keyword',2,'success',1,NOW(),NOW()),
(@ds1,'混合检索','hybrid',3,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('search_test_default_top_k','默认返回数量','5','number','ai','检索测试默认返回数量',60,1,0,NOW(),NOW()),
('search_test_default_threshold','默认相似度阈值','0.60','number','ai','检索测试默认相似度阈值',61,1,0,NOW(),NOW()),
('search_test_max_top_k','最大返回数量','20','number','ai','检索测试最大返回数量',62,1,0,NOW(),NOW()),
('search_test_history_retention_days','检索历史保留天数','30','number','ai','检索历史记录保留天数',63,1,0,NOW(),NOW()),
('search_test_result_highlight','结果高亮标记','true','boolean','ai','检索结果匹配词高亮标记',64,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('检索测试','ai:knowledge:search-test',1,0,'ai','/ai/knowledge/search-test','el-icon-search',NULL,4,1,1,'检索测试查看',NOW(),NOW()),
('检索测试编辑','ai:knowledge:search-test:edit',2,0,'ai',NULL,NULL,NULL,5,1,1,'保存/删除检索方案',NOW(),NOW()),
('检索测试导出','ai:knowledge:search-test:export',2,0,'ai',NULL,NULL,NULL,6,1,1,'导出检索历史',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:knowledge:search-test','ai:knowledge:search-test:edit','ai:knowledge:search-test:export');

-- ========== 五、菜单（知识库 → 检索测试） ==========
SET @ai_kb_id = (SELECT id FROM menus WHERE permission='ai:knowledge:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_kb_id, '检索测试', '/ai/knowledge/search-test', 'el-icon-search', 'ai:knowledge:search-test', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:knowledge:search-test' AND deleted_at IS NULL);
