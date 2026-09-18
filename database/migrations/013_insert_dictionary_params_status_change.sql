-- =====================================================
-- 013_insert_dictionary_params_status_change.sql
-- 设备状态变更模块：数据字典 + 系统参数 初始化
-- =====================================================

-- ========== 一、数据字典 ==========

-- ---------- 1. 变更类型 change_type ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('变更类型', 'change_type', '设备状态变更类型（正常/撤销）', 49, 1, NOW(), NOW());

SET @dty_change = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'change_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_change, '正常变更', 'normal',   1, 'primary', 1, NOW(), NOW()),
       (@dty_change, '撤销回退', 'rollback', 2, 'danger',  1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ---------- 2. 关联单据类型 order_type ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('关联单据类型', 'order_type', '设备状态变更关联单据类型', 50, 1, NOW(), NOW());

SET @dty_order = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'order_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_order, '维修单',     'repair',      1, 'warning', 1, NOW(), NOW()),
       (@dty_order, '调拨单',     'transfer',    2, 'primary', 1, NOW(), NOW()),
       (@dty_order, '报废单',     'scrap',       3, 'danger',  1, NOW(), NOW()),
       (@dty_order, '保养单',     'maintenance', 4, 'success', 1, NOW(), NOW()),
       (@dty_order, '检验单',     'inspection',  5, 'info',    1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ========== 二、系统参数（分组 device） ==========
INSERT INTO `system_params`
(`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`, `created_at`, `updated_at`)
VALUES
('device_status_change_preset_reasons', '设备故障，需要进行维修|设备定期保养维护|设备闲置封存|设备达到使用年限报废|设备调拨至其他部门|设备恢复正常使用状态|设备检测合格重新启用', '预设变更原因列表', 'device', 'text', '设备状态变更预设原因，竖线分隔', 8, 0, 1, NOW(), NOW()),
('device_status_change_rollback_hours', '24', '变更可撤销时长(小时)', 'device', 'number', '状态变更后允许撤销的时间窗口（小时）', 9, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
`param_value` = VALUES(`param_value`), `name` = VALUES(`name`), `param_group` = VALUES(`param_group`),
`param_type`  = VALUES(`param_type`), `description` = VALUES(`description`),
`sort`        = VALUES(`sort`), `status` = VALUES(`status`), `updated_at` = NOW();
