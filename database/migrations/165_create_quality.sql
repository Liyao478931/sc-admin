-- 165_create_quality.sql
-- 质量管理（生产管理 -> 质量管理）：5 表 + business_receive 加质量状态列 + 13 权限 + 菜单链
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('production:quality','quality:standard:view','quality:task:view','quality:reject:view','quality:statistics:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'quality:%');
--   DELETE FROM permissions WHERE code LIKE 'quality:%';
--   DROP TABLE IF EXISTS quality_reject_log;
--   DROP TABLE IF EXISTS quality_reject;
--   DROP TABLE IF EXISTS quality_inspection_item;
--   DROP TABLE IF EXISTS quality_inspection;
--   DROP TABLE IF EXISTS quality_standard;
--   ALTER TABLE business_product_receipt DROP COLUMN quality_status;

-- ========== 一、质检标准表 ==========
CREATE TABLE IF NOT EXISTS `quality_standard` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `standard_code` varchar(50) NOT NULL DEFAULT '' COMMENT '标准编码 QS-001',
  `standard_name` varchar(100) NOT NULL DEFAULT '' COMMENT '标准名称',
  `product_type` varchar(50) NOT NULL DEFAULT '' COMMENT '适用产品类型',
  `process_type` varchar(50) NOT NULL DEFAULT '' COMMENT '适用工序类型',
  `inspection_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '检验类型：1外观 2尺寸 3性能 4材质',
  `items` json DEFAULT NULL COMMENT '检验项目列表（JSON数组）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_standard_code` (`standard_code`),
  KEY `idx_standard_type` (`inspection_type`),
  KEY `idx_standard_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='质检标准表';

-- ========== 二、检验记录表 ==========
CREATE TABLE IF NOT EXISTS `quality_inspection` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `inspection_no` varchar(50) NOT NULL DEFAULT '' COMMENT '检验单编号 QI+YYYYMMDD+4位流水',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单ID',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号（冗余）',
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联产品ID',
  `product_name` varchar(100) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `standard_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联质检标准ID',
  `inspector_id` int(11) NOT NULL DEFAULT 0 COMMENT '质检员ID',
  `inspector_name` varchar(50) NOT NULL DEFAULT '' COMMENT '质检员姓名（冗余）',
  `inspection_date` date DEFAULT NULL COMMENT '检验日期',
  `inspection_time` datetime DEFAULT NULL COMMENT '检验时间（执行时写入）',
  `result` tinyint(1) NOT NULL DEFAULT 3 COMMENT '检验结果：1合格 2不合格 3待判定',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态：0待检验 1检验中 2已完成',
  `conclusion` varchar(500) DEFAULT NULL COMMENT '检验结论',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_inspection_no` (`inspection_no`),
  KEY `idx_inspection_wo` (`work_order_id`),
  KEY `idx_inspection_status` (`status`),
  KEY `idx_inspection_date` (`inspection_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='检验记录表';

-- ========== 三、检验明细表 ==========
CREATE TABLE IF NOT EXISTS `quality_inspection_item` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `inspection_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联检验记录ID',
  `item_name` varchar(100) NOT NULL DEFAULT '' COMMENT '检验项目名称',
  `item_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '项目类型：1文本 2数值 3布尔',
  `standard_value` varchar(200) DEFAULT NULL COMMENT '标准值',
  `upper_limit` decimal(12,4) DEFAULT NULL COMMENT '上限值（数值类型）',
  `lower_limit` decimal(12,4) DEFAULT NULL COMMENT '下限值（数值类型）',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位',
  `measured_value` varchar(200) DEFAULT NULL COMMENT '实测值',
  `is_qualified` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否合格：1是 0否',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_item_inspection` (`inspection_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='检验明细表';

-- ========== 四、不合格品处理表 ==========
CREATE TABLE IF NOT EXISTS `quality_reject` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `reject_no` varchar(50) NOT NULL DEFAULT '' COMMENT '处理单编号 QR+YYYYMMDD+4位流水',
  `inspection_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联检验记录ID',
  `work_order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联工单ID',
  `work_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号（冗余）',
  `product_name` varchar(100) NOT NULL DEFAULT '' COMMENT '产品名称（冗余）',
  `reject_items` json DEFAULT NULL COMMENT '不合格项目列表',
  `reject_type` tinyint(1) NOT NULL DEFAULT 5 COMMENT '不合格类型：1外观缺陷 2尺寸超差 3性能不达标 4材质问题 5其他',
  `severity` tinyint(1) NOT NULL DEFAULT 1 COMMENT '严重程度：1轻微 2一般 3严重',
  `handle_method` tinyint(1) NOT NULL DEFAULT 0 COMMENT '处理方式：1返修 2报废 3退货 4让步接收',
  `handle_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '处理状态：0待处理 1处理中 2已处理 3已关闭',
  `handler_id` int(11) NOT NULL DEFAULT 0 COMMENT '处理人ID',
  `handler_name` varchar(50) NOT NULL DEFAULT '' COMMENT '处理人姓名',
  `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
  `handle_result` varchar(500) DEFAULT NULL COMMENT '处理结果',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT 0 COMMENT '创建人',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_reject_no` (`reject_no`),
  KEY `idx_reject_wo` (`work_order_id`),
  KEY `idx_reject_status` (`handle_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='不合格品处理表';

-- ========== 五、不合格品处理日志表 ==========
CREATE TABLE IF NOT EXISTS `quality_reject_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `reject_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联处理单ID',
  `action` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型：create/handle/close',
  `action_label` varchar(30) NOT NULL DEFAULT '' COMMENT '操作类型标签',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `before_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作前状态',
  `after_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '操作后状态',
  `remark` varchar(500) DEFAULT NULL COMMENT '操作备注',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_log_reject` (`reject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='不合格品处理日志表';

-- ========== 六、产品接收单加质量状态列（幂等） ==========
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_product_receipt' AND COLUMN_NAME='quality_status');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_product_receipt` ADD COLUMN `quality_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''质量状态：0未质检 1合格 2不合格''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 七、权限（13 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('质检标准','quality:standard:view',2,0,'production','/production/quality/standard','el-icon-document-checked',NULL,247,1,1,'质检标准-查看（菜单）',NOW(),NOW()),
('新增质检标准','quality:standard:add',2,0,'production',NULL,NULL,NULL,248,1,1,'新增质检标准',NOW(),NOW()),
('编辑质检标准','quality:standard:edit',2,0,'production',NULL,NULL,NULL,249,1,1,'编辑质检标准',NOW(),NOW()),
('删除质检标准','quality:standard:delete',2,0,'production',NULL,NULL,NULL,250,1,1,'删除质检标准',NOW(),NOW()),
('检验任务','quality:task:view',2,0,'production','/production/quality/task','el-icon-edit',NULL,251,1,1,'检验任务-查看（菜单）',NOW(),NOW()),
('新增检验','quality:task:add',2,0,'production',NULL,NULL,NULL,252,1,1,'新增检验',NOW(),NOW()),
('编辑检验','quality:task:edit',2,0,'production',NULL,NULL,NULL,253,1,1,'编辑检验',NOW(),NOW()),
('执行检验','quality:task:execute',2,0,'production',NULL,NULL,NULL,254,1,1,'执行检验',NOW(),NOW()),
('删除检验','quality:task:delete',2,0,'production',NULL,NULL,NULL,255,1,1,'删除检验',NOW(),NOW()),
('不合格品处理','quality:reject:view',2,0,'production','/production/quality/reject','el-icon-warning',NULL,256,1,1,'不合格品处理-查看（菜单）',NOW(),NOW()),
('处理不合格品','quality:reject:handle',2,0,'production',NULL,NULL,NULL,257,1,1,'处理不合格品',NOW(),NOW()),
('质量统计','quality:statistics:view',2,0,'production','/production/quality/statistics','el-icon-data-analysis',NULL,258,1,1,'质量统计-查看（菜单）',NOW(),NOW()),
('导出质量统计','quality:statistics:export',2,0,'production',NULL,NULL,NULL,259,1,1,'导出质量统计',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'quality:%';

-- ========== 八、菜单链：生产管理 -> 质量管理 -> 4 个叶子 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:view' AND deleted_at IS NULL LIMIT 1), '质量管理', '', 'el-icon-medal', 'production:quality', 30, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:quality' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:quality' AND deleted_at IS NULL LIMIT 1), '质检标准', '/production/quality/standard', 'el-icon-document-checked', 'quality:standard:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='quality:standard:view' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:quality' AND deleted_at IS NULL LIMIT 1), '检验任务', '/production/quality/task', 'el-icon-edit', 'quality:task:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='quality:task:view' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:quality' AND deleted_at IS NULL LIMIT 1), '不合格品处理', '/production/quality/reject', 'el-icon-warning', 'quality:reject:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='quality:reject:view' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:quality' AND deleted_at IS NULL LIMIT 1), '质量统计', '/production/quality/statistics', 'el-icon-data-analysis', 'quality:statistics:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='quality:statistics:view' AND deleted_at IS NULL);
