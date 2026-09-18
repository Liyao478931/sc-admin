-- =====================================================
-- 016_alter_device_qrcode.sql
-- 设备二维码模块：设备表加字段 + 系统参数 + 权限
-- =====================================================

-- ---------- 1. 设备主表增加二维码字段（MySQL 5.7，仅需执行一次） ----------
ALTER TABLE `device_assets`
  ADD COLUMN `qrcode_url` varchar(255) NOT NULL DEFAULT '' COMMENT '二维码图片访问地址' AFTER `image`,
  ADD COLUMN `qrcode_generated_at` datetime DEFAULT NULL COMMENT '二维码生成时间' AFTER `qrcode_url`;

-- ---------- 2. 系统参数（分组 device） ----------
INSERT INTO `system_params`
(`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`, `created_at`, `updated_at`)
VALUES
('qrcode_default_size',       '300',   '二维码默认尺寸',   'device', 'number', '二维码图片生成尺寸(像素)', 10, 0, 1, NOW(), NOW()),
('qrcode_error_correction',   'M',     '二维码容错级别',   'device', 'text',   'L(低7%)/M(中15%)/Q(较高25%)/H(高30%)', 11, 0, 1, NOW(), NOW()),
('qrcode_label_company_name', '', '标签企业名称',   'device', 'text',   '二维码标签上显示的企业名称', 12, 0, 1, NOW(), NOW()),
('qrcode_label_show_logo',    '1',     '标签显示Logo',    'device', 'switch', '二维码标签是否显示企业Logo', 13, 0, 1, NOW(), NOW()),
('qrcode_h5_base_url',        '/m/device', 'H5设备详情页地址', 'device', 'text', '二维码扫码后跳转的H5页面基础地址', 14, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
`param_value` = VALUES(`param_value`), `name` = VALUES(`name`), `param_group` = VALUES(`param_group`),
`param_type`  = VALUES(`param_type`), `description` = VALUES(`description`),
`sort`        = VALUES(`sort`), `status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 3. 权限定义（已存在则更新） ----------
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('生成二维码', 'device:qrcode:generate', 2, 0, '设备台账', '/device/asset', NULL, NULL, 100, 1, 1, '生成/重新生成设备二维码', NOW(), NOW()),
('下载二维码', 'device:qrcode:download', 2, 0, '设备台账', '/device/asset', NULL, NULL, 110, 1, 1, '下载设备二维码', NOW(), NOW()),
('打印二维码', 'device:qrcode:print',    2, 0, '设备台账', '/device/asset', NULL, NULL, 120, 1, 1, '打印设备二维码标签', NOW(), NOW()),
('删除二维码', 'device:qrcode:delete',   2, 0, '设备台账', '/device/asset', NULL, NULL, 130, 1, 1, '删除设备二维码', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ---------- 4. 将权限分配给超级管理员角色 ----------
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:qrcode:generate','device:qrcode:download','device:qrcode:print','device:qrcode:delete');
