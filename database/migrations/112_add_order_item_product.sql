-- 112_add_order_item_product.sql
-- 经营管理 -> 订单中心：订单明细产品改为从产品列表获取（存 product_id 冗余字段）
-- 1. business_sales_order_items 增加产品字段（product_id/product_code/product_spec/product_unit）
-- 2. business_repair_order_items 增加配件产品字段（product_id/product_code/product_name/product_spec/product_unit/quantity/unit_price）
-- 回滚 down：
--   ALTER TABLE business_repair_order_items DROP COLUMN unit_price;
--   ALTER TABLE business_repair_order_items DROP COLUMN quantity;
--   ALTER TABLE business_repair_order_items DROP COLUMN product_unit;
--   ALTER TABLE business_repair_order_items DROP COLUMN product_spec;
--   ALTER TABLE business_repair_order_items DROP COLUMN product_name;
--   ALTER TABLE business_repair_order_items DROP COLUMN product_code;
--   ALTER TABLE business_repair_order_items DROP COLUMN product_id;
--   ALTER TABLE business_sales_order_items DROP COLUMN product_unit;
--   ALTER TABLE business_sales_order_items DROP COLUMN product_spec;
--   ALTER TABLE business_sales_order_items DROP COLUMN product_code;
--   ALTER TABLE business_sales_order_items DROP COLUMN product_id;

ALTER TABLE `business_sales_order_items` ADD COLUMN `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID' AFTER `order_id`;
ALTER TABLE `business_sales_order_items` ADD COLUMN `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '产品编码（冗余）' AFTER `product_id`;
ALTER TABLE `business_sales_order_items` ADD COLUMN `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '产品规格（冗余）' AFTER `product_name`;
ALTER TABLE `business_sales_order_items` ADD COLUMN `product_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '产品单位（冗余）' AFTER `product_spec`;

ALTER TABLE `business_repair_order_items` ADD COLUMN `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '配件产品ID' AFTER `order_id`;
ALTER TABLE `business_repair_order_items` ADD COLUMN `product_code` varchar(30) NOT NULL DEFAULT '' COMMENT '配件编码（冗余）' AFTER `product_id`;
ALTER TABLE `business_repair_order_items` ADD COLUMN `product_name` varchar(200) NOT NULL DEFAULT '' COMMENT '配件名称（冗余）' AFTER `product_code`;
ALTER TABLE `business_repair_order_items` ADD COLUMN `product_spec` varchar(100) NOT NULL DEFAULT '' COMMENT '配件规格（冗余）' AFTER `product_name`;
ALTER TABLE `business_repair_order_items` ADD COLUMN `product_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '配件单位（冗余）' AFTER `product_spec`;
ALTER TABLE `business_repair_order_items` ADD COLUMN `quantity` int(11) NOT NULL DEFAULT 1 COMMENT '配件数量' AFTER `product_unit`;
ALTER TABLE `business_repair_order_items` ADD COLUMN `unit_price` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '配件单价' AFTER `quantity`;
