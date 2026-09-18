-- 128_add_arrival_received.sql
-- 采购到货单增加 received_quantity（已入库数量，分批入库累加，用于入库进度与状态回写）
-- 回滚 down：ALTER TABLE business_purchase_arrival DROP COLUMN received_quantity;
ALTER TABLE `business_purchase_arrival` ADD COLUMN `received_quantity` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '已入库数量（分批入库累加）' AFTER `arrival_date`;
