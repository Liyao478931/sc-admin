-- ============================================================
-- ChurnAgent/Monitor 超时扫描所需字段补齐
-- 历史库（含本机）缺列导致后台任务持续报 1054 Unknown column。
-- 幂等说明：重复执行报 Duplicate column，安装/更新迁移逻辑会忽略。
-- ============================================================

ALTER TABLE `safety_inspection_task` ADD COLUMN `plan_time` datetime DEFAULT NULL COMMENT '计划时间';
ALTER TABLE `business_purchase_order` ADD COLUMN `delivery_date` date DEFAULT NULL COMMENT '交付日期';
ALTER TABLE `sales_ship_order` ADD COLUMN `plan_delivery_date` date DEFAULT NULL COMMENT '预计发货日期';