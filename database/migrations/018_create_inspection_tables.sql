-- =====================================================
-- 018_create_inspection_tables.sql
-- 设备巡检模块：5 张表
-- =====================================================

-- ---------- 1. 巡检计划表 ----------
CREATE TABLE IF NOT EXISTS `device_inspection_plan` (
  `id`               int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_code`        varchar(50)  NOT NULL COMMENT '计划编号（唯一）',
  `plan_name`        varchar(100) NOT NULL COMMENT '计划名称',
  `plan_type`        varchar(20)  NOT NULL DEFAULT 'periodic' COMMENT '计划类型：periodic/temporary（字典inspection_plan_type）',
  `target_type`      varchar(20)  NOT NULL DEFAULT 'device' COMMENT '目标类型：device/device_type',
  `target_ids`       text         COMMENT '目标ID列表（设备ID或分类ID，逗号分隔）',
  `template_id`      int(11) unsigned DEFAULT NULL COMMENT '内容模板ID',
  `executor_type`    varchar(20)  NOT NULL DEFAULT 'fixed' COMMENT '执行人类型：fixed/role/dept',
  `executor_ids`     varchar(500) NOT NULL DEFAULT '' COMMENT '执行人ID列表（逗号分隔）',
  `frequency_type`   varchar(20)  DEFAULT NULL COMMENT '频率类型：daily/weekly/monthly/quarterly/yearly/once',
  `frequency_value`  varchar(50)  NOT NULL DEFAULT '' COMMENT '频率值：如每周几/每月几号',
  `start_date`       date         DEFAULT NULL COMMENT '开始日期',
  `end_date`         date         DEFAULT NULL COMMENT '结束日期',
  `next_execute_date` date        DEFAULT NULL COMMENT '下次执行日期',
  `status`           varchar(20)  NOT NULL DEFAULT 'active' COMMENT '状态：active/inactive/expired（字典plan_status）',
  `remark`           text         COMMENT '备注',
  `create_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`      datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`      datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`),
  KEY `idx_plan_type` (`plan_type`),
  KEY `idx_status` (`status`),
  KEY `idx_next_execute_date` (`next_execute_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='巡检计划表';

-- ---------- 2. 巡检内容模板表 ----------
CREATE TABLE IF NOT EXISTS `device_inspection_template` (
  `id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_code`  varchar(50)  NOT NULL COMMENT '模板编号（唯一）',
  `template_name`  varchar(100) NOT NULL COMMENT '模板名称',
  `category_id`    int(11) unsigned DEFAULT NULL COMMENT '适用分类ID',
  `description`    varchar(255) NOT NULL DEFAULT '' COMMENT '模板描述',
  `items`          json         NOT NULL COMMENT '检查项列表：id/name/standard/check_method/normal_range/required/sort',
  `version`        int(11)      NOT NULL DEFAULT '1' COMMENT '版本号',
  `status`         varchar(20)  NOT NULL DEFAULT 'active' COMMENT '状态：active/inactive',
  `create_time`    datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='巡检内容模板表';

-- ---------- 3. 巡检任务表 ----------
CREATE TABLE IF NOT EXISTS `device_inspection_task` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_code`          varchar(50)  NOT NULL COMMENT '任务编号（唯一）',
  `plan_id`            int(11) unsigned NOT NULL COMMENT '计划ID',
  `device_id`          int(11) unsigned NOT NULL COMMENT '设备ID',
  `device_code`        varchar(50)  NOT NULL COMMENT '设备编码（冗余）',
  `device_name`        varchar(100) NOT NULL COMMENT '设备名称（冗余）',
  `executor_id`        int(11) unsigned DEFAULT NULL COMMENT '执行人ID',
  `executor_name`      varchar(50)  NOT NULL DEFAULT '' COMMENT '执行人姓名',
  `plan_execute_date`  date         NOT NULL COMMENT '计划执行日期',
  `actual_execute_date` datetime    DEFAULT NULL COMMENT '实际执行日期',
  `status`             varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending/in_progress/completed/overdue/cancelled（字典task_status）',
  `result`             json         DEFAULT NULL COMMENT '检查项填写结果',
  `remark`             text         COMMENT '备注',
  `execute_duration`   int(11)      DEFAULT NULL COMMENT '执行耗时(分钟)',
  `create_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`        datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_code` (`task_code`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_executor_id` (`executor_id`),
  KEY `idx_status` (`status`),
  KEY `idx_plan_execute_date` (`plan_execute_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='巡检任务表';

-- ---------- 4. 巡检记录表 ----------
CREATE TABLE IF NOT EXISTS `device_inspection_record` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `record_code`     varchar(50)  NOT NULL COMMENT '记录编号（唯一）',
  `task_id`         int(11) unsigned NOT NULL COMMENT '任务ID',
  `device_id`       int(11) unsigned NOT NULL COMMENT '设备ID',
  `plan_id`         int(11) unsigned DEFAULT NULL COMMENT '计划ID',
  `executor_id`     int(11) unsigned NOT NULL COMMENT '执行人ID',
  `executor_name`   varchar(50)  NOT NULL COMMENT '执行人姓名',
  `execute_time`    datetime     NOT NULL COMMENT '执行时间',
  `items`           json         NOT NULL COMMENT '检查项完整结果',
  `abnormal_count`  int(11)      NOT NULL DEFAULT '0' COMMENT '异常项数量',
  `total_count`     int(11)      NOT NULL DEFAULT '0' COMMENT '总检查项数量',
  `result`          varchar(20)  NOT NULL DEFAULT 'normal' COMMENT '整体结果：normal/abnormal（字典record_result）',
  `attachments`     json         DEFAULT NULL COMMENT '附件列表',
  `remark`          text         COMMENT '备注',
  `auditor_id`      int(11) unsigned DEFAULT NULL COMMENT '审核人ID',
  `audit_time`      datetime     DEFAULT NULL COMMENT '审核时间',
  `audit_remark`    varchar(255) NOT NULL DEFAULT '' COMMENT '审核意见',
  `audit_status`    varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '审核状态：pending/approved/rejected（字典audit_status）',
  `create_time`     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_record_code` (`record_code`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_executor_id` (`executor_id`),
  KEY `idx_execute_time` (`execute_time`),
  KEY `idx_audit_status` (`audit_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='巡检记录表';

-- ---------- 5. 巡检隐患表 ----------
CREATE TABLE IF NOT EXISTS `device_inspection_hazard` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hazard_code`     varchar(50)  NOT NULL COMMENT '隐患编号（唯一）',
  `record_id`       int(11) unsigned NOT NULL COMMENT '巡检记录ID',
  `device_id`       int(11) unsigned NOT NULL COMMENT '设备ID',
  `device_code`     varchar(50)  NOT NULL COMMENT '设备编码',
  `device_name`     varchar(100) NOT NULL COMMENT '设备名称',
  `check_item_name` varchar(100) NOT NULL COMMENT '检查项名称',
  `hazard_desc`     text         NOT NULL COMMENT '隐患描述',
  `severity`        varchar(20)  NOT NULL DEFAULT 'general' COMMENT '严重程度：minor/general/serious/emergency（字典hazard_severity）',
  `status`          varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending/processing/resolved/closed（字典hazard_status）',
  `handler_id`      int(11) unsigned DEFAULT NULL COMMENT '处理人ID',
  `handler_name`    varchar(50)  NOT NULL DEFAULT '' COMMENT '处理人姓名',
  `handle_measure`  text         COMMENT '处理措施',
  `handle_result`   text         COMMENT '处理结果',
  `handle_time`     datetime     DEFAULT NULL COMMENT '处理时间',
  `repair_order_no` varchar(50)  NOT NULL DEFAULT '' COMMENT '关联维修单号',
  `create_time`     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hazard_code` (`hazard_code`),
  KEY `idx_record_id` (`record_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_severity` (`severity`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='巡检隐患表';
