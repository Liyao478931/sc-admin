-- =====================================================
-- 022_create_device_repair_order.sql（完整版，重建）
-- 设备维修模块：维修工单表 + 操作日志表
-- =====================================================

-- ---------- 1. 维修工单表 ----------
DROP TABLE IF EXISTS `device_repair_order`;
CREATE TABLE `device_repair_order` (
  `id`                  int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_code`          varchar(50)  NOT NULL COMMENT '工单编号（REP-YYYYMMDD-XXXX）',
  `device_id`           int(11) unsigned NOT NULL COMMENT '设备ID（device_assets.id）',
  `device_code`         varchar(50)  NOT NULL COMMENT '设备编码（冗余）',
  `device_name`         varchar(100) NOT NULL COMMENT '设备名称（冗余）',
  `fault_type`          varchar(30)  NOT NULL DEFAULT '' COMMENT '故障类型（字典 repair_fault_type）',
  `fault_description`   text         COMMENT '故障描述',
  `emergency_level`     varchar(20)  NOT NULL DEFAULT 'normal' COMMENT '紧急程度：normal/urgent/critical（字典 repair_emergency_level）',
  `source_type`         varchar(30)  NOT NULL DEFAULT 'manual' COMMENT '来源类型：manual/inspection/maintenance（字典 repair_source_type）',
  `source_id`           int(11)      DEFAULT NULL COMMENT '来源ID（巡检/保养记录ID）',
  `reporter_id`         int(11) unsigned NOT NULL DEFAULT 0 COMMENT '报修人ID（users.id）',
  `reporter_name`       varchar(50)  NOT NULL DEFAULT '' COMMENT '报修人姓名',
  `report_time`         datetime     NOT NULL COMMENT '报修时间',
  `handler_id`          int(11) unsigned DEFAULT NULL COMMENT '处理人ID（users.id）',
  `handler_name`        varchar(50)  NOT NULL DEFAULT '' COMMENT '处理人姓名',
  `assign_time`         datetime     DEFAULT NULL COMMENT '派单时间',
  `assign_remark`       varchar(255) NOT NULL DEFAULT '' COMMENT '派单备注',
  `plan_complete_time`  date         DEFAULT NULL COMMENT '计划完成时间',
  `actual_complete_time` datetime    DEFAULT NULL COMMENT '实际完成时间',
  `status`              varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending待派单/assigned已派单/repairing维修中/accepted待验收/approved已验收/closed已关闭/rejected已驳回',
  `transfer_history`    json         DEFAULT NULL COMMENT '转派历史[{from,to,time,reason}]',
  `reject_reason`       varchar(255) NOT NULL DEFAULT '' COMMENT '驳回原因',
  `reject_count`        int(11)      NOT NULL DEFAULT 0 COMMENT '驳回次数',
  `close_time`          datetime     DEFAULT NULL COMMENT '关闭时间',
  -- 执行结果（员工端提交后落库）
  `diagnosis_cause`     text         COMMENT '故障原因分析',
  `diagnosis_conclusion` text        COMMENT '诊断结论',
  `repair_plan`         text         COMMENT '维修方案',
  `materials`           json         DEFAULT NULL COMMENT '备件清单[{name,spec,quantity}]',
  `repair_process`      text         COMMENT '维修过程记录',
  `repair_result`       varchar(20)  NOT NULL DEFAULT '' COMMENT '维修结果：fixed/unfixable',
  `attachments`         json         DEFAULT NULL COMMENT '附件图片列表',
  `execute_start_time`  datetime     DEFAULT NULL COMMENT '开始维修时间',
  `execute_end_time`    datetime     DEFAULT NULL COMMENT '结束维修时间',
  `duration`            int(11)      DEFAULT NULL COMMENT '维修时长（分钟）',
  -- 验收信息
  `acceptor_id`         int(11) unsigned DEFAULT NULL COMMENT '验收人ID',
  `acceptor_name`       varchar(50)  NOT NULL DEFAULT '' COMMENT '验收人姓名',
  `accept_time`         datetime     DEFAULT NULL COMMENT '验收时间',
  `accept_remark`       varchar(255) NOT NULL DEFAULT '' COMMENT '验收意见',
  `draft`               json         DEFAULT NULL COMMENT '暂存数据（员工端草稿）',
  `remark`              text         COMMENT '备注',
  `create_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`         datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_code` (`order_code`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_status` (`status`),
  KEY `idx_reporter_id` (`reporter_id`),
  KEY `idx_handler_id` (`handler_id`),
  KEY `idx_report_time` (`report_time`),
  KEY `idx_emergency_level` (`emergency_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备维修工单';

-- ---------- 2. 维修工单操作日志表 ----------
DROP TABLE IF EXISTS `device_repair_order_log`;
CREATE TABLE `device_repair_order_log` (
  `id`            int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id`      int(11) unsigned NOT NULL COMMENT '工单ID',
  `operator_id`   int(11) unsigned NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(50)  NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `action`        varchar(30)  NOT NULL COMMENT '操作类型：create/edit/delete/assign/transfer/accept/reject/status_change/close',
  `action_desc`   varchar(255) NOT NULL COMMENT '操作描述',
  `old_value`     varchar(255) DEFAULT NULL COMMENT '旧值',
  `new_value`     varchar(255) DEFAULT NULL COMMENT '新值',
  `create_time`   datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='维修工单操作日志';
