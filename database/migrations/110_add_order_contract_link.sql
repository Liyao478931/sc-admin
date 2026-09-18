-- 110_add_order_contract_link.sql
-- 经营管理 -> 订单中心：订单关联合同（多订单可关联同一合同）+ 字典"销售订单"改"生产订单"
-- 1. business_orders 增加 contract_id / contract_no（已存在时执行器忽略重复列错误）
-- 2. 数据字典 order_category 的 sales 显示名更新为"生产订单"
-- 回滚 down：
--   ALTER TABLE business_orders DROP INDEX idx_contract_id;
--   ALTER TABLE business_orders DROP COLUMN contract_no;
--   ALTER TABLE business_orders DROP COLUMN contract_id;
--   UPDATE dictionary_entries SET label='销售订单' WHERE value='sales';

ALTER TABLE `business_orders` ADD COLUMN `contract_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联合同ID（多订单可关联同一合同）' AFTER `business_type`;
ALTER TABLE `business_orders` ADD COLUMN `contract_no` varchar(50) NOT NULL DEFAULT '' COMMENT '合同编号（冗余）' AFTER `contract_id`;
ALTER TABLE `business_orders` ADD INDEX `idx_contract_id` (`contract_id`);

UPDATE `dictionary_entries` SET `label` = '生产订单' WHERE `value` = 'sales' AND `type_id` = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'order_category' LIMIT 1);
