-- =====================================================
-- 103_add_company_bank_fields.sql
-- settings_company 补充签约与银行信息字段（合同模板签署栏使用）
-- 幂等写法（information_schema 判断，兼容 PDO/phpMyAdmin）
-- =====================================================

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='settings_company' AND COLUMN_NAME='bank_name');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `settings_company` ADD COLUMN `bank_name` varchar(100) DEFAULT NULL COMMENT ''开户银行'' AFTER `address`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='settings_company' AND COLUMN_NAME='bank_account');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `settings_company` ADD COLUMN `bank_account` varchar(50) DEFAULT NULL COMMENT ''银行账号'' AFTER `bank_name`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='settings_company' AND COLUMN_NAME='account_type');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `settings_company` ADD COLUMN `account_type` varchar(50) DEFAULT NULL COMMENT ''账户类型'' AFTER `bank_account`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='settings_company' AND COLUMN_NAME='bank_branch_code');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `settings_company` ADD COLUMN `bank_branch_code` varchar(100) DEFAULT NULL COMMENT ''开户行联行号'' AFTER `account_type`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='settings_company' AND COLUMN_NAME='agent');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `settings_company` ADD COLUMN `agent` varchar(50) DEFAULT NULL COMMENT ''委托代理人'' AFTER `bank_branch_code`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
