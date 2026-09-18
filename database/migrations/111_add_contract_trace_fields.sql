-- 111_add_contract_trace_fields.sql
-- 经营管理 -> 合同管理：合同表增加采购追溯字段（采购合同复用 business_contracts）
-- 1. business_contracts 增加 order_id（关联采购订单，预留）/ request_id（关联采购申请，冗余追溯）
-- 回滚 down：
--   ALTER TABLE business_contracts DROP INDEX idx_contract_trace;
--   ALTER TABLE business_contracts DROP COLUMN request_id;
--   ALTER TABLE business_contracts DROP COLUMN order_id;

ALTER TABLE `business_contracts` ADD COLUMN `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联采购订单ID（预留）' AFTER `parent_contract_id`;
ALTER TABLE `business_contracts` ADD COLUMN `request_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联采购申请ID（冗余便于追溯）' AFTER `order_id`;
ALTER TABLE `business_contracts` ADD INDEX `idx_contract_trace` (`order_id`, `request_id`);
