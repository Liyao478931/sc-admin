-- 126_create_warehouse_cost.sql
-- 物料单价与库存成本核算扩展（ALTER 幂等：由执行器先检查列是否存在，仅对缺失列执行）
-- 1. warehouse_material 增加：reference_price 参考采购单价 / reference_cost 参考成本单价 / costing_method 计价方式 / avg_cost_price 当前加权平均单价
-- 2. warehouse_stock_flow 增加：cost_price 成本单价 / cost_total 成本总价 / before_avg_price 变动前加权平均单价 / after_avg_price 变动后加权平均单价
-- 回滚 down：DROP COLUMN 以上字段

ALTER TABLE `warehouse_material` ADD COLUMN `reference_price` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '参考采购单价（元）' AFTER `purchase_cycle`;
ALTER TABLE `warehouse_material` ADD COLUMN `reference_cost` decimal(12,4) NOT NULL DEFAULT 0 COMMENT '参考成本单价（元）' AFTER `reference_price`;
ALTER TABLE `warehouse_material` ADD COLUMN `costing_method` tinyint(1) NOT NULL DEFAULT 1 COMMENT '计价方式：1移动加权平均 2先进先出' AFTER `reference_cost`;
ALTER TABLE `warehouse_material` ADD COLUMN `avg_cost_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '当前加权平均单价（元）' AFTER `costing_method`;
ALTER TABLE `warehouse_stock_flow` ADD COLUMN `cost_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '成本单价（元）' AFTER `after_stock`;
ALTER TABLE `warehouse_stock_flow` ADD COLUMN `cost_total` decimal(18,4) NOT NULL DEFAULT 0 COMMENT '成本总价（元）' AFTER `cost_price`;
ALTER TABLE `warehouse_stock_flow` ADD COLUMN `before_avg_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '变动前加权平均单价（元）' AFTER `cost_total`;
ALTER TABLE `warehouse_stock_flow` ADD COLUMN `after_avg_price` decimal(14,4) NOT NULL DEFAULT 0 COMMENT '变动后加权平均单价（元）' AFTER `before_avg_price`;
