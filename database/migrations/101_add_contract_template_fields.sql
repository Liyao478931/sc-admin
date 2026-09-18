-- =====================================================
-- 101_add_contract_template_fields.sql
-- 合同列表与新增合同改造：集成合同模板管理
--   1. business_contracts 新增 5 字段：template_id / contract_html / content_version / sign_location / payment_terms
--   2. 新增 idx_template_id 索引
-- 幂等写法（information_schema 判断，兼容 PDO/phpMyAdmin）
-- =====================================================

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='template_id');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `template_id` int(11) DEFAULT NULL COMMENT ''合同模板ID'' AFTER `contract_type`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='contract_html');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `contract_html` longtext COMMENT ''合同HTML内容（模板生成）'' AFTER `content`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='content_version');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `content_version` int(11) NOT NULL DEFAULT 1 COMMENT ''内容版本号'' AFTER `contract_html`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='sign_location');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `sign_location` varchar(100) DEFAULT NULL COMMENT ''签订地点'' AFTER `sign_date`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='payment_terms');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `payment_terms` varchar(255) DEFAULT NULL COMMENT ''付款方式'' AFTER `contract_amount`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @idx := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND INDEX_NAME='idx_template_id');
SET @sql := IF(@idx > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD KEY `idx_template_id` (`template_id`)');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
