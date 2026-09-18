-- =====================================================
-- 017_insert_dictionary_params_inspection.sql
-- 设备巡检模块：数据字典 + 系统参数 初始化
-- =====================================================

-- ========== 一、数据字典 ==========
-- 巡检计划类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('巡检计划类型','inspection_plan_type','巡检计划类型：定期/临时',51,1,NOW(),NOW());
SET @d1=(SELECT id FROM dictionary_types WHERE code='inspection_plan_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d1,'定期','periodic',1,'primary',1,NOW(),NOW()),
(@d1,'临时','temporary',2,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 计划状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('计划状态','plan_status','巡检计划状态',52,1,NOW(),NOW());
SET @d2=(SELECT id FROM dictionary_types WHERE code='plan_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d2,'启用','active',1,'success',1,NOW(),NOW()),
(@d2,'停用','inactive',2,'info',1,NOW(),NOW()),
(@d2,'过期','expired',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 任务状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('任务状态','task_status','巡检任务状态',53,1,NOW(),NOW());
SET @d3=(SELECT id FROM dictionary_types WHERE code='task_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d3,'待执行','pending',1,'info',1,NOW(),NOW()),
(@d3,'执行中','in_progress',2,'primary',1,NOW(),NOW()),
(@d3,'已完成','completed',3,'success',1,NOW(),NOW()),
(@d3,'已逾期','overdue',4,'danger',1,NOW(),NOW()),
(@d3,'已取消','cancelled',5,'warning',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 巡检结果
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('巡检结果','record_result','巡检整体结果',54,1,NOW(),NOW());
SET @d4=(SELECT id FROM dictionary_types WHERE code='record_result');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d4,'正常','normal',1,'success',1,NOW(),NOW()),
(@d4,'异常','abnormal',2,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 审核状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('审核状态','audit_status','巡检记录审核状态',55,1,NOW(),NOW());
SET @d5=(SELECT id FROM dictionary_types WHERE code='audit_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d5,'待审核','pending',1,'warning',1,NOW(),NOW()),
(@d5,'通过','approved',2,'success',1,NOW(),NOW()),
(@d5,'驳回','rejected',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 隐患严重程度
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('隐患严重程度','hazard_severity','巡检隐患严重程度',56,1,NOW(),NOW());
SET @d6=(SELECT id FROM dictionary_types WHERE code='hazard_severity');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d6,'轻微','minor',1,'info',1,NOW(),NOW()),
(@d6,'一般','general',2,'warning',1,NOW(),NOW()),
(@d6,'严重','serious',3,'danger',1,NOW(),NOW()),
(@d6,'紧急','emergency',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 隐患状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('隐患状态','hazard_status','巡检隐患处理状态',57,1,NOW(),NOW());
SET @d7=(SELECT id FROM dictionary_types WHERE code='hazard_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d7,'待处理','pending',1,'info',1,NOW(),NOW()),
(@d7,'处理中','processing',2,'primary',1,NOW(),NOW()),
(@d7,'已处理','resolved',3,'success',1,NOW(),NOW()),
(@d7,'已关闭','closed',4,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 二、系统参数（分组 device） ==========
INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('inspection_task_advance_days',   '1',  '任务提前生成天数', 'device', 'number', '巡检任务到期前提前生成的天数', 15, 0, 1, NOW(), NOW()),
('inspection_overdue_remind_days', '3',  '逾期提醒天数', 'device', 'number', '巡检任务逾期后持续提醒的天数', 16, 0, 1, NOW(), NOW()),
('inspection_auto_generate_time',  '02:00', '自动生成任务时间', 'device', 'text', '每天自动生成巡检任务的时间(HH:MM)', 17, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();
