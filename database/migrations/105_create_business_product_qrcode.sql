-- 105_create_business_product_qrcode.sql
-- 经营管理 -> 产品管理（二维码功能补充）
-- 1. business_products 增加二维码字段（已存在时执行器忽略重复列错误，可重复执行）
-- 2. 新增权限 business:product:qrcode 并授权 super_admin
-- 回滚 down：
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='business:product:qrcode');
--   DELETE FROM permissions WHERE code='business:product:qrcode';
--   ALTER TABLE business_products DROP COLUMN qrcode_generated_at;
--   ALTER TABLE business_products DROP COLUMN qrcode_url;

ALTER TABLE `business_products` ADD COLUMN `qrcode_url` varchar(255) DEFAULT NULL COMMENT '二维码图片地址' AFTER `sort`;
ALTER TABLE `business_products` ADD COLUMN `qrcode_generated_at` datetime DEFAULT NULL COMMENT '二维码生成时间' AFTER `qrcode_url`;

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品二维码','business:product:qrcode',2,0,'business',NULL,NULL,NULL,19,1,1,'产品二维码生成/下载/删除',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='business:product:qrcode';
