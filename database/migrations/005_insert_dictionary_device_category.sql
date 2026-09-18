-- =====================================================
-- 005_insert_dictionary_device_category.sql
-- 设备分类模块：数据字典初始化
-- 说明：字典类型已存在则跳过；字典条目存在则更新（依赖 uk_type_value 唯一索引）
-- =====================================================

-- ---------- 1. 设备分类状态 device_category_status ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('设备分类状态', 'device_category_status', '设备分类启用/停用状态', 42, 1, NOW(), NOW());

SET @dty_status = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'device_category_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_status, '启用', '1', 1, 'success', 1, NOW(), NOW()),
       (@dty_status, '停用', '0', 2, 'danger',  1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ---------- 2. 设备分类层级 device_category_level ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('设备分类层级', 'device_category_level', '设备分类层级（一级~四级）', 43, 1, NOW(), NOW());

SET @dty_level = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'device_category_level' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_level, '一级分类', '1', 1, 'primary', 1, NOW(), NOW()),
       (@dty_level, '二级分类', '2', 2, 'primary', 1, NOW(), NOW()),
       (@dty_level, '三级分类', '3', 3, 'primary', 1, NOW(), NOW()),
       (@dty_level, '四级分类', '4', 4, 'primary', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ---------- 3. 设备类型 device_type ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('设备类型', 'device_type', '四大设备类型', 44, 1, NOW(), NOW());

SET @dty_type = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'device_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_type, '普通设备', 'general', 1, '', 1, NOW(), NOW()),
       (@dty_type, '特种设备', 'special', 2, '', 1, NOW(), NOW()),
       (@dty_type, '轿车',     'car',     3, '', 1, NOW(), NOW()),
       (@dty_type, '货车',     'truck',   4, '', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();

-- ---------- 4. 设备分类图标 device_category_icon ----------
INSERT IGNORE INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`, `created_at`, `updated_at`)
VALUES ('设备分类图标', 'device_category_icon', '设备分类可选图标（Element UI 图标类名）', 45, 1, NOW(), NOW());

SET @dty_icon = (SELECT `id` FROM `dictionary_types` WHERE `code` = 'device_category_icon' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`, `created_at`, `updated_at`)
VALUES (@dty_icon, '办公设备', 'el-icon-printer',     1,  '', 1, NOW(), NOW()),
       (@dty_icon, '生产设备', 'el-icon-factory',     2,  '', 1, NOW(), NOW()),
       (@dty_icon, 'IT设备',   'el-icon-monitor',     3,  '', 1, NOW(), NOW()),
       (@dty_icon, '仪器仪表', 'el-icon-s-data',      4,  '', 1, NOW(), NOW()),
       (@dty_icon, '锅炉',     'el-icon-wind-power',  5,  '', 1, NOW(), NOW()),
       (@dty_icon, '压力容器', 'el-icon-box',         6,  '', 1, NOW(), NOW()),
       (@dty_icon, '电梯',     'el-icon-s-order',     7,  '', 1, NOW(), NOW()),
       (@dty_icon, '起重机械', 'el-icon-s-flag',      8,  '', 1, NOW(), NOW()),
       (@dty_icon, '叉车',     'el-icon-truck',       9,  '', 1, NOW(), NOW()),
       (@dty_icon, '燃油轿车', 'el-icon-van',         10, '', 1, NOW(), NOW()),
       (@dty_icon, '新能源轿车','el-icon-charger',    11, '', 1, NOW(), NOW()),
       (@dty_icon, '混动轿车', 'el-icon-s-promotion', 12, '', 1, NOW(), NOW()),
       (@dty_icon, '轻型货车', 'el-icon-s-truck',     13, '', 1, NOW(), NOW()),
       (@dty_icon, '中型货车', 'el-icon-s-truck',     14, '', 1, NOW(), NOW()),
       (@dty_icon, '重型货车', 'el-icon-s-truck',     15, '', 1, NOW(), NOW()),
       (@dty_icon, '牵引车',   'el-icon-s-truck',     16, '', 1, NOW(), NOW()),
       (@dty_icon, '其他',     'el-icon-more',        17, '', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `sort` = VALUES(`sort`),
       `style` = VALUES(`style`), `status` = VALUES(`status`), `deleted_at` = NULL, `updated_at` = NOW();
