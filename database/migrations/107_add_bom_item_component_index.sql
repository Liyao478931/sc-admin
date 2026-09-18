-- 107_add_bom_item_component_index.sql
-- 经营管理 -> 产品管理 -> BOM管理（补充索引）
-- business_product_bom_item 增加 component_product_id 索引（幂等，已存在时执行器忽略 Duplicate key name）
-- 回滚 down：
--   ALTER TABLE business_product_bom_item DROP INDEX idx_component_product;

ALTER TABLE `business_product_bom_item` ADD INDEX `idx_component_product` (`component_product_id`);
