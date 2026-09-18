-- 114_add_purchase_order_purpose.sql
-- 经营管理 -> 采购订单：主表增加用途说明字段（从采购申请带入）
-- 回滚 down：
--   ALTER TABLE business_purchase_order DROP COLUMN purpose;

ALTER TABLE `business_purchase_order` ADD COLUMN `purpose` text COMMENT '用途说明（从采购申请带入）' AFTER `remark`;
