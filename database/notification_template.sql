-- =====================================================
-- notification_template.sql
-- 消息模板管理：建表 + 字典 + 系统参数 + 权限菜单（幂等）
-- 执行方式：面板【数据库】→ ly478931 → 管理 → 导入 该文件
-- 说明：本文件不含任何凭据
-- =====================================================

-- ---------- 1. 建表 system_notification_template ----------
CREATE TABLE IF NOT EXISTS `system_notification_template` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_code` varchar(50) NOT NULL COMMENT '模板编号(NT-YYYYMMDD-XXXX)',
  `template_name` varchar(100) NOT NULL COMMENT '模板名称',
  `template_type` tinyint(4) NOT NULL COMMENT '1系统公告 2任务指派 3审批通知 4预警提醒 5培训通知 6工单通知',
  `purpose` varchar(255) DEFAULT NULL COMMENT '模板用途',
  `title_template` varchar(200) NOT NULL COMMENT '消息标题模板(支持变量占位符)',
  `content_template` text NOT NULL COMMENT '消息内容模板(支持变量占位符和HTML)',
  `variables` json DEFAULT NULL COMMENT '实际使用变量列表',
  `status` tinyint(4) NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`),
  KEY `idx_template_type` (`template_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息模板';

-- ---------- 2. 数据字典：消息模板类型 ----------
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('消息模板类型','notification_template_type','消息模板类型分类',47,1,NOW(),NOW());

SET @ntt = (SELECT `id` FROM `dictionary_types` WHERE `code`='notification_template_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@ntt,'系统公告','system',1,'info',1,NOW(),NOW()),
(@ntt,'任务指派','task',2,'primary',1,NOW(),NOW()),
(@ntt,'审批通知','approval',3,'warning',1,NOW(),NOW()),
(@ntt,'预警提醒','alert',4,'danger',1,NOW(),NOW()),
(@ntt,'培训通知','training',5,'success',1,NOW(),NOW()),
(@ntt,'工单通知','order',6,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ---------- 3. 系统参数 ----------
INSERT IGNORE INTO `system_params` (`param_key`,`param_value`,`name`,`param_group`,`param_type`) VALUES
('notification_template_code_prefix','NT','模板编号前缀','system','string'),
('notification_default_variables','{"username":"用户姓名","task_name":"任务名称","deadline":"截止日期","link":"跳转链接","title":"业务标题","content":"业务内容","order_no":"工单编号","hazard_name":"隐患名称","check_name":"检查名称","training_name":"培训名称","exam_name":"考试名称","risk_name":"风险名称","accident_name":"事故名称","device_name":"设备名称","expire_date":"过期日期"}','默认变量列表(JSON)','system','json');

-- ---------- 4. 权限与菜单 ----------
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('模板列表查看','notification:template:list',1,0,'系统管理','/system/notification/templates','el-icon-document-copy',141,1,1,'查看消息模板列表',NOW(),NOW()),
('模板详情查询','notification:template:query',2,0,'系统管理','',NULL,142,1,1,'查询消息模板详情/预览',NOW(),NOW()),
('模板新增','notification:template:add',2,0,'系统管理','',NULL,143,1,1,'新增消息模板',NOW(),NOW()),
('模板编辑','notification:template:edit',2,0,'系统管理','',NULL,144,1,1,'编辑消息模板',NOW(),NOW()),
('模板删除','notification:template:delete',2,0,'系统管理','',NULL,145,1,1,'删除消息模板',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` IN ('notification:template:list','notification:template:query','notification:template:add','notification:template:edit','notification:template:delete');

-- 消息模板菜单（挂"消息通知"目录下；目录不存在则顶级）
SET @ntf_dir = (SELECT `id` FROM `menus` WHERE `name`='消息通知' AND `deleted_at` IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT COALESCE(@ntf_dir,0),'消息模板','/system/notification/templates','el-icon-document-copy','notification:template:list',2,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='notification:template:list' AND `deleted_at` IS NULL);
