-- =====================================================
-- 007_create_device_category.sql
-- 设备分类表：建表 + 初始化数据（四大设备类型 + 二级子分类）
-- 说明：采用硬删除方案；code 唯一；code 格式由系统参数 device_category_code_regex 控制
--       初始化数据使用 SET @变量 方式避免 MySQL 1093（同表子查询限制），可重复执行（幂等）
-- =====================================================

-- ---------- 建表 ----------
CREATE TABLE IF NOT EXISTS `device_category` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `parent_id`   int(11) unsigned NOT NULL DEFAULT '0'    COMMENT '父级分类ID，0表示顶级分类',
  `name`        varchar(50)  NOT NULL                    COMMENT '分类名称',
  `code`        varchar(30)  NOT NULL                    COMMENT '分类编码',
  `level`       tinyint(4)   NOT NULL DEFAULT '1'        COMMENT '分类层级深度，顶级为1',
  `icon`        varchar(100) NOT NULL DEFAULT ''         COMMENT '分类图标（Element UI 图标类名）',
  `sort`        int(11)      NOT NULL DEFAULT '0'        COMMENT '排序权重，数值越大越靠前',
  `status`      tinyint(4)   NOT NULL DEFAULT '1'        COMMENT '状态：1启用 0停用',
  `create_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_sort` (`sort`),
  KEY `idx_status` (`status`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备分类表';

-- ---------- 初始化数据（顶级：四大设备类型） ----------
INSERT IGNORE INTO `device_category` (`parent_id`, `name`, `code`, `level`, `icon`, `sort`, `status`, `create_time`, `update_time`) VALUES
(0, '普通设备', 'GENERAL_EQUIPMENT', 1, 'el-icon-factory',   10, 1, NOW(), NOW()),
(0, '特种设备', 'SPECIAL_EQUIPMENT', 1, 'el-icon-warning',  20, 1, NOW(), NOW()),
(0, '轿车',     'CAR',               1, 'el-icon-van',      30, 1, NOW(), NOW()),
(0, '货车',     'TRUCK',             1, 'el-icon-truck',    40, 1, NOW(), NOW());

-- 缓存各顶级分类ID供子分类使用
SET @cat_general = (SELECT `id` FROM `device_category` WHERE `code`='GENERAL_EQUIPMENT');
SET @cat_special = (SELECT `id` FROM `device_category` WHERE `code`='SPECIAL_EQUIPMENT');
SET @cat_car     = (SELECT `id` FROM `device_category` WHERE `code`='CAR');
SET @cat_truck   = (SELECT `id` FROM `device_category` WHERE `code`='TRUCK');

-- ---------- 初始化数据（二级：普通设备子分类） ----------
INSERT IGNORE INTO `device_category` (`parent_id`, `name`, `code`, `level`, `icon`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@cat_general, '办公设备', 'GENERAL_EQUIPMENT_OFFICE',     2, 'el-icon-printer',   10, 1, NOW(), NOW()),
(@cat_general, '生产设备', 'GENERAL_EQUIPMENT_PRODUCTION', 2, 'el-icon-factory',   20, 1, NOW(), NOW()),
(@cat_general, 'IT设备',   'GENERAL_EQUIPMENT_IT',         2, 'el-icon-monitor',   30, 1, NOW(), NOW()),
(@cat_general, '仪器仪表', 'GENERAL_EQUIPMENT_INSTRUMENT', 2, 'el-icon-s-data',    40, 1, NOW(), NOW()),
(@cat_general, '其他',     'GENERAL_EQUIPMENT_OTHER',      2, 'el-icon-more',      99, 1, NOW(), NOW());

-- ---------- 初始化数据（二级：特种设备子分类） ----------
INSERT IGNORE INTO `device_category` (`parent_id`, `name`, `code`, `level`, `icon`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@cat_special, '锅炉',       'SPECIAL_EQUIPMENT_BOILER',         2, 'el-icon-wind-power', 10, 1, NOW(), NOW()),
(@cat_special, '压力容器',   'SPECIAL_EQUIPMENT_PRESSURE_VESSEL', 2, 'el-icon-box',        20, 1, NOW(), NOW()),
(@cat_special, '电梯',       'SPECIAL_EQUIPMENT_ELEVATOR',        2, 'el-icon-s-order',    30, 1, NOW(), NOW()),
(@cat_special, '起重机械',   'SPECIAL_EQUIPMENT_CRANE',           2, 'el-icon-s-flag',     40, 1, NOW(), NOW()),
(@cat_special, '叉车',       'SPECIAL_EQUIPMENT_FORKLIFT',        2, 'el-icon-truck',      50, 1, NOW(), NOW()),
(@cat_special, '其他',       'SPECIAL_EQUIPMENT_OTHER',           2, 'el-icon-more',       99, 1, NOW(), NOW());

-- ---------- 初始化数据（二级：轿车子分类） ----------
INSERT IGNORE INTO `device_category` (`parent_id`, `name`, `code`, `level`, `icon`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@cat_car, '燃油轿车',   'CAR_FUEL',        2, 'el-icon-van',          10, 1, NOW(), NOW()),
(@cat_car, '新能源轿车', 'CAR_NEW_ENERGY',  2, 'el-icon-charger',      20, 1, NOW(), NOW()),
(@cat_car, '混动轿车',   'CAR_HYBRID',      2, 'el-icon-s-promotion',  30, 1, NOW(), NOW()),
(@cat_car, '其他',       'CAR_OTHER',       2, 'el-icon-more',         99, 1, NOW(), NOW());

-- ---------- 初始化数据（二级：货车子分类） ----------
INSERT IGNORE INTO `device_category` (`parent_id`, `name`, `code`, `level`, `icon`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@cat_truck, '轻型货车', 'TRUCK_LIGHT',   2, 'el-icon-s-truck', 10, 1, NOW(), NOW()),
(@cat_truck, '中型货车', 'TRUCK_MEDIUM',  2, 'el-icon-s-truck', 20, 1, NOW(), NOW()),
(@cat_truck, '重型货车', 'TRUCK_HEAVY',   2, 'el-icon-s-truck', 30, 1, NOW(), NOW()),
(@cat_truck, '牵引车',   'TRUCK_TRACTOR', 2, 'el-icon-s-truck', 40, 1, NOW(), NOW()),
(@cat_truck, '其他',     'TRUCK_OTHER',   2, 'el-icon-more',    99, 1, NOW(), NOW());
