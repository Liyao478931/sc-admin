-- 104_create_business_product_param.sql
-- 经营管理 -> 产品管理（补充迁移）
-- 1. business_products 增加 sort 字段（已存在时执行器忽略重复列错误，可重复执行）
-- 2. 建表：business_product_param_values（产品参数值表）
-- 回滚 down：
--   DROP TABLE IF EXISTS business_product_param_values;
--   ALTER TABLE business_products DROP COLUMN sort;

ALTER TABLE `business_products` ADD COLUMN `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序，小在前' AFTER `unit`;

CREATE TABLE IF NOT EXISTS `business_product_param_values` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL DEFAULT 0 COMMENT '产品ID',
  `param_name` varchar(50) NOT NULL DEFAULT '' COMMENT '参数名称',
  `param_value` varchar(255) NOT NULL DEFAULT '' COMMENT '参数值',
  `param_unit` varchar(20) NOT NULL DEFAULT '' COMMENT '参数单位',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序，小在前',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='产品参数值表';
