-- =====================================================
-- 014_create_device_status_change_tables.sql
-- 设备状态变更模块：变更记录表 + 状态流转规则表 + 初始化流转规则
-- =====================================================

-- ---------- 1. 设备状态变更记录表 ----------
CREATE TABLE IF NOT EXISTS `device_status_change_log` (
  `id`                  int(11) unsigned NOT NULL AUTO_INCREMENT,
  `asset_id`            int(11) unsigned NOT NULL COMMENT '设备ID（device_assets.id）',
  `device_code`         varchar(50)  NOT NULL DEFAULT '' COMMENT '设备编码（冗余）',
  `device_name`         varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）',
  `device_type`         varchar(20)  NOT NULL DEFAULT '' COMMENT '设备类型（冗余，字典device_type）',
  `from_status`         varchar(20)  NOT NULL DEFAULT '' COMMENT '变更前状态（字典device_status）',
  `to_status`           varchar(20)  NOT NULL COMMENT '变更后状态（字典device_status）',
  `reason`              varchar(500) NOT NULL DEFAULT '' COMMENT '变更原因',
  `change_type`         varchar(20)  NOT NULL DEFAULT 'normal' COMMENT '变更类型：normal/rollback（字典change_type）',
  `operator_id`         int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人ID（users.id）',
  `operator_name`       varchar(50)  NOT NULL DEFAULT '' COMMENT '操作人姓名（冗余）',
  `related_order_no`    varchar(50)  NOT NULL DEFAULT '' COMMENT '关联单据编号',
  `related_order_type`  varchar(30)  NOT NULL DEFAULT '' COMMENT '关联单据类型（字典order_type）',
  `remark`              varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `snapshot_data`       json         DEFAULT NULL COMMENT '变更时设备快照',
  `change_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变更时间',
  `create_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_asset_id` (`asset_id`),
  KEY `idx_device_code` (`device_code`),
  KEY `idx_from_status` (`from_status`),
  KEY `idx_to_status` (`to_status`),
  KEY `idx_operator_id` (`operator_id`),
  KEY `idx_change_time` (`change_time`),
  KEY `idx_related_order_no` (`related_order_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备状态变更记录表';

-- ---------- 2. 设备状态流转规则表 ----------
CREATE TABLE IF NOT EXISTS `device_status_flow_rule` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `from_status`     varchar(20) NOT NULL COMMENT '源状态（字典device_status）',
  `to_status`       varchar(20) NOT NULL COMMENT '目标状态（字典device_status）',
  `allow_transfer`  tinyint(1)  NOT NULL DEFAULT '1' COMMENT '是否允许流转：1允许 0禁止',
  `require_reason`  tinyint(1)  NOT NULL DEFAULT '1' COMMENT '是否必须填写原因',
  `require_order`   tinyint(1)  NOT NULL DEFAULT '0' COMMENT '是否必须关联单据',
  `sort`            int(11)     NOT NULL DEFAULT '0' COMMENT '排序',
  `create_time`     datetime    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`     datetime    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_flow` (`from_status`, `to_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备状态流转规则表';

-- ---------- 3. 初始化流转规则 ----------
INSERT INTO `device_status_flow_rule` (`from_status`, `to_status`, `allow_transfer`, `require_reason`, `require_order`, `sort`, `create_time`, `update_time`) VALUES
('in_use',      'repairing',  1, 1, 0, 10, NOW(), NOW()),
('in_use',      'idle',       1, 1, 0, 20, NOW(), NOW()),
('in_use',      'scrapped',   1, 1, 0, 30, NOW(), NOW()),
('in_use',      'transferred',1, 1, 1, 40, NOW(), NOW()),
('repairing',   'in_use',     1, 1, 0, 10, NOW(), NOW()),
('repairing',   'scrapped',   1, 1, 0, 20, NOW(), NOW()),
('idle',        'in_use',     1, 1, 0, 10, NOW(), NOW()),
('idle',        'scrapped',   1, 1, 0, 20, NOW(), NOW()),
('transferred', 'in_use',     1, 1, 0, 10, NOW(), NOW()),
('scrapped',    'in_use',     0, 1, 0, 10, NOW(), NOW()),
('scrapped',    'repairing',  0, 1, 0, 20, NOW(), NOW()),
('scrapped',    'idle',       0, 1, 0, 30, NOW(), NOW()),
('scrapped',    'transferred',0, 1, 0, 40, NOW(), NOW())
ON DUPLICATE KEY UPDATE
`allow_transfer` = VALUES(`allow_transfer`), `require_reason` = VALUES(`require_reason`),
`require_order` = VALUES(`require_order`), `sort` = VALUES(`sort`), `update_time` = NOW();
