-- =====================================================
-- 010_insert_dictionary_params_device_asset.sql
-- 设备台账模块：数据字典 + 系统参数 初始化
-- =====================================================

-- ========== 一、数据字典 ==========

-- ---------- 1. 设备状态 device_status ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('设备状态', 'device_status', '设备台账状态（在用/维修中/闲置/报废/已调拨）', 46, 1, NOW(), NOW());

SET @dty_status = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'device_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_status, '在用',   'in_use',     1, 'success', 1, NOW(), NOW()),
       (@dty_status, '维修中', 'repairing',  2, 'warning', 1, NOW(), NOW()),
       (@dty_status, '闲置',   'idle',       3, 'info',    1, NOW(), NOW()),
       (@dty_status, '报废',   'scrapped',   4, 'danger',  1, NOW(), NOW()),
       (@dty_status, '已调拨', 'transferred',5, 'primary', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ---------- 2. 特种设备类型 special_type ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('特种设备类型', 'special_type', '特种设备细分类别', 47, 1, NOW(), NOW());

SET @dty_special = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'special_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_special, '锅炉',     'boiler',          1, '', 1, NOW(), NOW()),
       (@dty_special, '压力容器', 'pressure_vessel', 2, '', 1, NOW(), NOW()),
       (@dty_special, '电梯',     'elevator',        3, '', 1, NOW(), NOW()),
       (@dty_special, '起重机械', 'crane',           4, '', 1, NOW(), NOW()),
       (@dty_special, '叉车',     'forklift',        5, '', 1, NOW(), NOW()),
       (@dty_special, '其他',     'other',           6, '', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ---------- 3. 燃料类型 fuel_type ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('燃料类型', 'fuel_type', '车辆燃料类型', 48, 1, NOW(), NOW());

SET @dty_fuel = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'fuel_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_fuel, '汽油', 'gasoline', 1, '', 1, NOW(), NOW()),
       (@dty_fuel, '柴油', 'diesel',   2, '', 1, NOW(), NOW()),
       (@dty_fuel, '电动', 'electric', 3, '', 1, NOW(), NOW()),
       (@dty_fuel, '混动', 'hybrid',   4, '', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ========== 二、系统参数（分组 device） ==========
INSERT INTO `system_params`
(`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`, `created_at`, `updated_at`)
VALUES
('device_asset_code_prefix', 'EQP', '设备编码前缀', 'device', 'text',   '设备编码自动生成时的固定前缀', 6, 0, 1, NOW(), NOW()),
('device_asset_code_digits', '4',   '设备编码序号位数', 'device', 'number', '设备编码自动生成时序号的最小位数', 7, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
`param_value` = VALUES(`param_value`), `name` = VALUES(`name`), `param_group` = VALUES(`param_group`),
`param_type`  = VALUES(`param_type`), `description` = VALUES(`description`),
`sort`        = VALUES(`sort`), `status` = VALUES(`status`), `updated_at` = NOW();
