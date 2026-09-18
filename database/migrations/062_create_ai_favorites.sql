-- =====================================================
-- 062_create_ai_favorites.sql
-- AI 智能平台：收藏问答功能
--   1. 收藏分类表 ai_favorite_categories
--   2. 收藏问答表 ai_favorites
--   3. 预置系统分类（user_id=0）
--   4. 权限（ai:chat:favorites 系列）
--   5. 菜单（AI智能平台 → 对话中心 → 收藏问答）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、收藏分类表 ==========
CREATE TABLE IF NOT EXISTS `ai_favorite_categories` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '分类名称',
  `category_color` varchar(20) NOT NULL DEFAULT '#409EFF' COMMENT '分类颜色',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '用户ID（0=系统预置）',
  `is_system` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否系统预置：1是 0否',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_sort` (`user_id`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI收藏分类表';

-- ========== 二、收藏问答表 ==========
CREATE TABLE IF NOT EXISTS `ai_favorites` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `favorite_id` varchar(32) NOT NULL DEFAULT '' COMMENT '收藏唯一标识（UUID去横线）',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '用户ID',
  `session_id` varchar(32) DEFAULT NULL COMMENT '来源会话ID',
  `message_id` varchar(32) DEFAULT NULL COMMENT '收藏的AI回复消息ID',
  `question` text COMMENT '用户问题内容（冗余存储）',
  `answer` text COMMENT 'AI回答内容（冗余存储）',
  `category_id` int(11) DEFAULT NULL COMMENT '分类ID',
  `tags` json DEFAULT NULL COMMENT '标签列表(JSON)',
  `summary` varchar(255) NOT NULL DEFAULT '' COMMENT '摘要（自动从问题提取）',
  `note` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `source` varchar(20) NOT NULL DEFAULT 'chat' COMMENT '来源：chat对话收藏/manual手动录入',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_favorite_id` (`favorite_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI收藏问答表';

-- ========== 三、预置系统分类 ==========
INSERT INTO `ai_favorite_categories` (`category_name`, `category_color`, `sort`, `user_id`, `is_system`)
VALUES
  ('业务知识', '#409EFF', 1, 0, 1),
  ('操作指南', '#67C23A', 2, 0, 1),
  ('问题解决', '#E6A23C', 3, 0, 1),
  ('常用查询', '#909399', 4, 0, 1),
  ('其他',     '#9B59B6', 5, 0, 1)
ON DUPLICATE KEY UPDATE `category_color`=VALUES(`category_color`), `sort`=VALUES(`sort`), `is_system`=1;

-- ========== 四、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('收藏问答', 'ai:chat:favorites', 1, 0, 'ai', '/ai/chat/favorites', 'el-icon-star-on', NULL, 1, 1, 1, 'AI收藏问答菜单'),
  ('收藏-添加', 'ai:chat:favorites:add', 2, 0, 'ai', '/ai/chat/favorites', NULL, NULL, 2, 1, 1, '对话中收藏'),
  ('收藏-编辑', 'ai:chat:favorites:edit', 2, 0, 'ai', '/ai/chat/favorites', NULL, NULL, 3, 1, 1, '修改分类/备注'),
  ('收藏-删除', 'ai:chat:favorites:delete', 2, 0, 'ai', '/ai/chat/favorites', NULL, NULL, 4, 1, 1, '取消收藏/批量'),
  ('收藏-导出', 'ai:chat:favorites:export', 2, 0, 'ai', '/ai/chat/favorites', NULL, NULL, 5, 1, 1, '导出收藏')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:chat:favorites','ai:chat:favorites:add','ai:chat:favorites:edit','ai:chat:favorites:delete','ai:chat:favorites:export');

-- ========== 五、菜单 ==========
-- AI智能平台（顶级，已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- 对话中心（目录，已存在则跳过）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '对话中心', '', 'el-icon-chat-dot-round', 'ai:chat:list', 10, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:chat:list' AND deleted_at IS NULL);

-- 收藏问答（子菜单）
SET @ai_chat_id = (SELECT id FROM menus WHERE permission='ai:chat:list' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_chat_id, '收藏问答', '/ai/chat/favorites', 'el-icon-star-on', 'ai:chat:favorites', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:chat:favorites' AND deleted_at IS NULL);
