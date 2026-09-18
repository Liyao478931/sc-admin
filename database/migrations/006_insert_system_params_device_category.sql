-- =====================================================
-- 006_insert_system_params_device_category.sql
-- 设备分类模块：系统参数初始化
-- 目标表：system_params（唯一索引 uk_param_key），分组 device
-- 说明：参数已存在则更新其值；布尔开关使用 switch 类型（值 0/1）
-- =====================================================
INSERT INTO `system_params`
(`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`, `created_at`, `updated_at`)
VALUES
('device_category_max_level',             '4',     '分类最大层级深度',        'device', 'number', '设备分类允许的最大嵌套层级数，超过此层级将禁止创建子分类', 1, 0, 1, NOW(), NOW()),
('device_category_code_regex',            '^[A-Z][A-Z0-9_]*$', '分类编码正则表达式', 'device', 'text',   '分类编码的格式校验规则，用于控制编码输入的格式', 2, 0, 1, NOW(), NOW()),
('device_category_code_prefix',           'CAT',   '分类编码前缀',            'device', 'text',   '分类编码自动生成时的固定前缀', 3, 0, 1, NOW(), NOW()),
('device_category_page_size',             '20',    '分类列表每页条数',        'device', 'number', '分类树形列表默认每页显示的条数', 4, 0, 1, NOW(), NOW()),
('device_category_allow_delete_with_children', '0', '允许删除包含子分类的分类', 'device', 'switch', 'true 表示允许直接删除含有子分类的分类，false 表示必须先删除子分类才能删除父分类', 5, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
`param_value` = VALUES(`param_value`),
`name`        = VALUES(`name`),
`param_group` = VALUES(`param_group`),
`param_type`  = VALUES(`param_type`),
`description` = VALUES(`description`),
`sort`        = VALUES(`sort`),
`status`      = VALUES(`status`),
`updated_at`  = NOW();
