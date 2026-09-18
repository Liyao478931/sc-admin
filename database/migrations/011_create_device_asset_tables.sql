-- =====================================================
-- 011_create_device_asset_tables.sql
-- 设备台账模块：建表（device_assets + 扩展表 + 状态日志 + 供应商）
-- =====================================================

-- ---------- 1. 设备主表 device_assets（软删除） ----------
CREATE TABLE IF NOT EXISTS `device_assets` (
  `id`                  int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `device_code`         varchar(50)  NOT NULL                COMMENT '设备编码（唯一）',
  `name`                varchar(100) NOT NULL                COMMENT '设备名称',
  `category_id`         int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属分类ID（device_category.id）',
  `device_type`         varchar(20)  NOT NULL DEFAULT ''     COMMENT '设备类型：general/special/car/truck（字典device_type）',
  `model`               varchar(50)  NOT NULL DEFAULT ''     COMMENT '型号',
  `specification`       varchar(255) NOT NULL DEFAULT ''     COMMENT '规格参数',
  `brand`               varchar(50)  NOT NULL DEFAULT ''     COMMENT '品牌',
  `manufacturer`        varchar(100) NOT NULL DEFAULT ''     COMMENT '生产厂家',
  `supplier_id`         int(11) unsigned DEFAULT NULL        COMMENT '供应商ID（supplier.id）',
  `purchase_date`       date         DEFAULT NULL            COMMENT '采购日期',
  `purchase_price`      decimal(10,2) DEFAULT NULL           COMMENT '采购价格',
  `put_into_use_date`   date         DEFAULT NULL            COMMENT '投入使用日期',
  `department_id`       int(11) unsigned DEFAULT NULL        COMMENT '使用部门ID（departments.id）',
  `location`            varchar(100) NOT NULL DEFAULT ''     COMMENT '存放位置',
  `manager_id`          int(11) unsigned DEFAULT NULL        COMMENT '负责人ID（users.id）',
  `status`              varchar(20)  NOT NULL DEFAULT 'in_use' COMMENT '状态（字典device_status）',
  `image`               varchar(255) NOT NULL DEFAULT ''     COMMENT '设备图片',
  `qrcode`              varchar(255) NOT NULL DEFAULT ''     COMMENT '二维码',
  `remark`              text                                 COMMENT '备注',
  `sort`                int(11)      NOT NULL DEFAULT '0'    COMMENT '排序',
  `create_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time`         datetime     DEFAULT NULL            COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_code` (`device_code`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_device_type` (`device_type`),
  KEY `idx_status` (`status`),
  KEY `idx_department_id` (`department_id`),
  KEY `idx_manager_id` (`manager_id`),
  KEY `idx_purchase_date` (`purchase_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备台账主表';

-- ---------- 2. 普通设备扩展表 device_normal_ext ----------
CREATE TABLE IF NOT EXISTS `device_normal_ext` (
  `id`                      int(11) unsigned NOT NULL AUTO_INCREMENT,
  `asset_id`                int(11) unsigned NOT NULL COMMENT '设备ID（device_assets.id）',
  `power_rating`            varchar(50)  NOT NULL DEFAULT '' COMMENT '额定功率',
  `voltage`                 varchar(50)  NOT NULL DEFAULT '' COMMENT '电压等级',
  `weight`                  decimal(10,2) DEFAULT NULL COMMENT '重量(kg)',
  `dimensions`              varchar(100) NOT NULL DEFAULT '' COMMENT '外形尺寸',
  `warranty_expire_date`    date         DEFAULT NULL COMMENT '保修截止日期',
  `calibration_cycle`       int(11)      DEFAULT NULL COMMENT '校准周期(月)',
  `last_calibration_date`   date         DEFAULT NULL COMMENT '上次校准日期',
  `next_calibration_date`   date         DEFAULT NULL COMMENT '下次校准日期',
  `create_time`             datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`             datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asset_id` (`asset_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备台账-普通设备扩展表';

-- ---------- 3. 特种设备扩展表 device_special_ext ----------
CREATE TABLE IF NOT EXISTS `device_special_ext` (
  `id`                       int(11) unsigned NOT NULL AUTO_INCREMENT,
  `asset_id`                 int(11) unsigned NOT NULL COMMENT '设备ID（device_assets.id）',
  `special_type`             varchar(30)  NOT NULL DEFAULT '' COMMENT '特种设备类型（字典special_type）',
  `registration_code`        varchar(50)  NOT NULL DEFAULT '' COMMENT '使用登记证编号',
  `registration_authority`   varchar(100) NOT NULL DEFAULT '' COMMENT '登记机关',
  `inspection_cycle`         int(11)      DEFAULT NULL COMMENT '检验周期(月)',
  `last_inspection_date`     date         DEFAULT NULL COMMENT '上次检验日期',
  `next_inspection_date`     date         DEFAULT NULL COMMENT '下次检验日期',
  `inspection_result`        varchar(20)  NOT NULL DEFAULT '' COMMENT '最近检验结果：合格/不合格/整改',
  `operator_cert_required`   tinyint(1)   NOT NULL DEFAULT '0' COMMENT '是否需要操作证',
  `operator_cert_number`     varchar(50)  NOT NULL DEFAULT '' COMMENT '操作证编号',
  `operator_ids`             varchar(255) NOT NULL DEFAULT '' COMMENT '持证操作人员ID列表(逗号分隔)',
  `design_unit`              varchar(100) NOT NULL DEFAULT '' COMMENT '设计单位',
  `install_unit`             varchar(100) NOT NULL DEFAULT '' COMMENT '安装单位',
  `create_time`              datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`              datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asset_id` (`asset_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备台账-特种设备扩展表';

-- ---------- 4. 车辆扩展表 device_vehicle_ext ----------
CREATE TABLE IF NOT EXISTS `device_vehicle_ext` (
  `id`                        int(11) unsigned NOT NULL AUTO_INCREMENT,
  `asset_id`                  int(11) unsigned NOT NULL COMMENT '设备ID（device_assets.id）',
  `license_plate`             varchar(10)  NOT NULL DEFAULT '' COMMENT '车牌号',
  `vin`                       varchar(17)  NOT NULL DEFAULT '' COMMENT '车架号',
  `engine_no`                 varchar(30)  NOT NULL DEFAULT '' COMMENT '发动机号',
  `displacement`              decimal(3,1) DEFAULT NULL COMMENT '排量(L)',
  `fuel_type`                 varchar(20)  NOT NULL DEFAULT '' COMMENT '燃料类型（字典fuel_type）',
  `load_capacity`             decimal(10,2) DEFAULT NULL COMMENT '核定载重(kg)',
  `seat_count`                tinyint(4)   DEFAULT NULL COMMENT '核定载客数',
  `mileage`                   decimal(10,1) DEFAULT '0' COMMENT '当前里程(km)',
  `last_mileage_update`       datetime     DEFAULT NULL COMMENT '上次更新里程时间',
  `insurance_expire_date`     date         DEFAULT NULL COMMENT '保险到期日',
  `inspection_expire_date`    date         DEFAULT NULL COMMENT '年检到期日',
  `next_maintenance_mileage`  decimal(10,1) DEFAULT NULL COMMENT '下次保养里程(km)',
  `last_maintenance_date`     date         DEFAULT NULL COMMENT '上次保养日期',
  `create_time`               datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`               datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asset_id` (`asset_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备台账-车辆扩展表';

-- ---------- 5. 设备状态变更日志表 device_status_log ----------
CREATE TABLE IF NOT EXISTS `device_status_log` (
  `id`            int(11) unsigned NOT NULL AUTO_INCREMENT,
  `asset_id`      int(11) unsigned NOT NULL COMMENT '设备ID（device_assets.id）',
  `from_status`   varchar(20) NOT NULL DEFAULT '' COMMENT '变更前状态（字典device_status）',
  `to_status`     varchar(20) NOT NULL COMMENT '变更后状态（字典device_status）',
  `reason`        varchar(255) NOT NULL DEFAULT '' COMMENT '变更原因',
  `operator_id`   int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人ID（users.id）',
  `operator_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `create_time`   datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_asset_id` (`asset_id`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_operator_id` (`operator_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备台账-状态变更日志表';

-- ---------- 6. 供应商表 supplier（设备台账辅助数据） ----------
CREATE TABLE IF NOT EXISTS `supplier` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name`        varchar(100) NOT NULL COMMENT '供应商名称',
  `contact`     varchar(50)  NOT NULL DEFAULT '' COMMENT '联系人',
  `phone`       varchar(20)  NOT NULL DEFAULT '' COMMENT '联系电话',
  `remark`      varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `status`      tinyint(4)   NOT NULL DEFAULT '1' COMMENT '1启用 0禁用',
  `create_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='供应商表';
