-- =====================================================
-- 099_create_settings_face.sql
-- 系统设置 → 基础服务 → 人脸识别服务（腾讯云人脸识别 API 对接）
--   1. 建表 1 张：settings_face（配置，单行 id=1）
--   2. 权限：settings:services:face（菜单）/ settings:services:face:config（按钮）
--   3. 菜单：系统设置 → 基础服务 → 人脸识别服务
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、人脸识别服务配置表 ==========
CREATE TABLE IF NOT EXISTS `settings_face` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `service_name` varchar(50) NOT NULL DEFAULT '腾讯云人脸识别服务' COMMENT '服务名称',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '服务状态：1启用 0停用',
  `region` varchar(50) NOT NULL DEFAULT 'ap-guangzhou' COMMENT '服务地域',
  `secret_id` varchar(100) NOT NULL DEFAULT '' COMMENT '腾讯云API密钥ID',
  `secret_key` varchar(200) NOT NULL DEFAULT '' COMMENT '腾讯云API密钥（加密存储）',
  `group_id` varchar(100) NOT NULL DEFAULT '' COMMENT '人员库ID（控制台创建）',
  `similarity_threshold` decimal(5,2) NOT NULL DEFAULT 80.00 COMMENT '相似度阈值（分）',
  `max_face_num` int(11) NOT NULL DEFAULT 1 COMMENT '最多识别的人脸数',
  `max_person_num` int(11) NOT NULL DEFAULT 1 COMMENT '最多返回的人员数',
  `last_test_time` datetime DEFAULT NULL COMMENT '最后测试时间',
  `test_status` varchar(20) DEFAULT NULL COMMENT '测试状态：success/failed',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='腾讯云人脸识别服务配置';

-- 初始化默认配置行（单行 id=1，与电子签/U8 配置一致）
INSERT IGNORE INTO `settings_face` (`id`,`service_name`,`status`,`region`,`secret_id`,`secret_key`,`group_id`,`similarity_threshold`,`max_face_num`,`max_person_num`,`create_time`,`update_time`)
VALUES (1,'腾讯云人脸识别服务',1,'ap-guangzhou','','','',80.00,1,1,NOW(),NOW());

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('人脸识别服务','settings:services:face',1,0,'settings','/settings/services/face','el-icon-camera',NULL,43,1,1,'人脸识别服务-配置查看（菜单）',NOW(),NOW()),
('人脸识别服务配置','settings:services:face:config',2,0,'settings',NULL,NULL,NULL,44,1,1,'保存配置/测试连接/人脸接口调用',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('settings:services:face','settings:services:face:config');

-- ========== 三、菜单（系统设置 → 基础服务 → 人脸识别服务） ==========
-- 确保系统设置顶级菜单存在
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '系统设置', '', 'el-icon-setting', 'system:view', 90, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL);

-- 确保基础服务菜单存在（挂在系统设置下）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '基础服务', '/services', 'el-icon-connection', 'service:view', 10, 1, 2, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='基础服务' AND parent_id=(SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL);

SET @face_parent_id = (SELECT id FROM menus WHERE name='基础服务' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='系统设置' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) LIMIT 1);

-- 人脸识别服务页面
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @face_parent_id, '人脸识别服务', '/settings/services/face', 'el-icon-camera', 'settings:services:face', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:services:face' AND deleted_at IS NULL AND type=2);
