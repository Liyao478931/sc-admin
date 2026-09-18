-- =====================================================
-- 104_add_contract_items.sql
-- business_contracts 新增 items 明细字段（表单录入的合同明细行）
-- 幂等写法
-- =====================================================

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='business_contracts' AND COLUMN_NAME='items');
SET @sql := IF(@c > 0, 'SELECT 1', 'ALTER TABLE `business_contracts` ADD COLUMN `items` json DEFAULT NULL COMMENT ''合同明细[{name,model,unit,qty,price,amount,remark}]'' AFTER `payment_terms`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
