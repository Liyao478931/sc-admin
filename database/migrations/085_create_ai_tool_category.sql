-- =====================================================
-- 085_create_ai_tool_category.sql
-- AI 智能平台：工具分类
--   1. 分类表 ai_tool_categories
--   2. 数据字典（分类状态）
--   3. 预置分类数据（device/safety/hr/warehouse/common）
--   4. 权限（ai:tools:category 系列）
--   5. 菜单（工具中心 → 工具分类）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、分类表（若已存在则补充缺失字段，兼容早期预留表） ==========
CREATE TABLE IF NOT EXISTS `ai_tool_categories` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `category_key` varchar(30) NOT NULL DEFAULT '' COMMENT '分类标识（如 device）',
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '分类名称（如 设备工具）',
  `icon` varchar(50) DEFAULT NULL COMMENT '分类图标（Element UI 图标类名或 emoji）',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `is_system` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否系统预置：1是 0否',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `tool_count` int(11) NOT NULL DEFAULT 0 COMMENT '工具数量（冗余字段）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_key` (`category_key`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具分类表';

-- 幂等补充缺失字段（MySQL 兼容写法，字段已存在则跳过）
SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'icon');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `icon` varchar(50) DEFAULT NULL COMMENT ''分类图标'' AFTER `category_name`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'is_system');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `is_system` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''是否系统预置'' AFTER `status`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'description');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `description` varchar(255) DEFAULT NULL COMMENT ''描述说明'' AFTER `is_system`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'tool_count');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `tool_count` int(11) NOT NULL DEFAULT 0 COMMENT ''工具数量（冗余字段）'' AFTER `description`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'create_time');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `create_time` datetime DEFAULT NULL AFTER `tool_count`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'update_time');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `update_time` datetime DEFAULT NULL AFTER `create_time`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND column_name = 'delete_time');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD COLUMN `delete_time` datetime DEFAULT NULL COMMENT ''软删除时间'' AFTER `update_time`', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

-- 补充唯一索引（幂等：已存在则跳过）
SET @cc_ex := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND index_name = 'uk_category_key');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD UNIQUE KEY `uk_category_key` (`category_key`)', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

SET @cc_ex := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'ai_tool_categories' AND index_name = 'idx_status');
SET @cc_sql := IF(@cc_ex = 0, 'ALTER TABLE `ai_tool_categories` ADD KEY `idx_status` (`status`)', 'SELECT 1');
PREPARE cc_stmt FROM @cc_sql; EXECUTE cc_stmt; DEALLOCATE PREPARE cc_stmt;

-- ========== 二、数据字典 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('分类状态','tool_category_status','AI工具分类状态',88,1,NOW(),NOW());
SET @dc1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='tool_category_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dc1,'启用','active',1,'success',1,NOW(),NOW()),
(@dc1,'停用','inactive',2,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、预置分类数据 ==========
INSERT INTO `ai_tool_categories` (`category_key`,`category_name`,`icon`,`sort`,`status`,`is_system`,`description`,`tool_count`,`create_time`,`update_time`) VALUES
('device',    '设备工具', 'el-icon-s-management', 1, 1, 1, '设备管理相关工具',    0, NOW(), NOW()),
('safety',    '安全工具', 'el-icon-warning',      2, 1, 1, '安全管理相关工具',    0, NOW(), NOW()),
('hr',        '人事工具', 'el-icon-user',         3, 1, 1, '人事管理相关工具',    0, NOW(), NOW()),
('warehouse', '仓储工具', 'el-icon-s-shop',       4, 1, 1, '仓储管理相关工具',    0, NOW(), NOW()),
('common',    '通用工具', 'el-icon-s-tools',      5, 1, 1, '通用工具',            0, NOW(), NOW())
ON DUPLICATE KEY UPDATE
`category_name`=VALUES(`category_name`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`),
`status`=VALUES(`status`), `is_system`=VALUES(`is_system`), `description`=VALUES(`description`), `update_time`=NOW();

-- 同步工具数量（预置分类与 ai_tools.category 对应）
UPDATE `ai_tool_categories` c
SET c.`tool_count` = (SELECT COUNT(*) FROM `ai_tools` t WHERE t.`category` = c.`category_key`)
WHERE c.`delete_time` IS NULL;

-- ========== 四、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工具分类','ai:tools:category',1,0,'ai','/ai/tools/category','el-icon-s-grid',NULL,5,1,1,'工具分类查看',NOW(),NOW()),
('工具分类新增','ai:tools:category:add',2,0,'ai',NULL,NULL,NULL,6,1,1,'新增工具分类',NOW(),NOW()),
('工具分类编辑','ai:tools:category:edit',2,0,'ai',NULL,NULL,NULL,7,1,1,'编辑/排序/启停工具分类',NOW(),NOW()),
('工具分类删除','ai:tools:category:delete',2,0,'ai',NULL,NULL,NULL,8,1,1,'删除工具分类',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:tools:category','ai:tools:category:add','ai:tools:category:edit','ai:tools:category:delete');

-- ========== 五、菜单（工具中心 → 工具分类） ==========
SET @ai_tools_id = (SELECT id FROM menus WHERE permission='ai:tools:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_tools_id, '工具分类', '/ai/tools/category', 'el-icon-s-grid', 'ai:tools:category', 25, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:tools:category' AND deleted_at IS NULL);
