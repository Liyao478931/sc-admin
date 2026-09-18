-- =====================================================
-- 020_create_safety_hazard.sql
-- 安全管理模块：数据字典(5) + safety_hazards表 + 权限 + 菜单
-- =====================================================

-- ========== 一、数据字典 ==========
-- 1. 隐患类型
INSERT IGNORE INTO dictionary_types (name,code,description,sort,status,created_at,updated_at) VALUES ('隐患类型','safety_hazard_type','隐患类型',58,1,NOW(),NOW());
SET @d1=(SELECT id FROM dictionary_types WHERE code='safety_hazard_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d1,'设备隐患','equipment',1,'primary',1,NOW(),NOW()),
(@d1,'环境隐患','environment',2,'success',1,NOW(),NOW()),
(@d1,'行为隐患','behavior',3,'warning',1,NOW(),NOW()),
(@d1,'管理隐患','management',4,'info',1,NOW(),NOW()),
(@d1,'其他','other',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 2. 隐患等级
INSERT IGNORE INTO dictionary_types (name,code,description,sort,status,created_at,updated_at) VALUES ('隐患等级','safety_hazard_level','隐患等级',59,1,NOW(),NOW());
SET @d2=(SELECT id FROM dictionary_types WHERE code='safety_hazard_level');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d2,'轻微','minor',1,'info',1,NOW(),NOW()),
(@d2,'一般','general',2,'primary',1,NOW(),NOW()),
(@d2,'严重','serious',3,'warning',1,NOW(),NOW()),
(@d2,'紧急','emergency',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 3. 隐患来源
INSERT IGNORE INTO dictionary_types (name,code,description,sort,status,created_at,updated_at) VALUES ('隐患来源','safety_hazard_source','隐患来源渠道',60,1,NOW(),NOW());
SET @d3=(SELECT id FROM dictionary_types WHERE code='safety_hazard_source');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d3,'巡检异常','inspection',1,'warning',1,NOW(),NOW()),
(@d3,'人工登记','manual',2,'primary',1,NOW(),NOW()),
(@d3,'安全检查','safety_check',3,'success',1,NOW(),NOW()),
(@d3,'员工上报','report',4,'info',1,NOW(),NOW()),
(@d3,'外部检查','external',5,'danger',1,NOW(),NOW()),
(@d3,'维修发现','repair',6,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 4. 隐患状态
INSERT IGNORE INTO dictionary_types (name,code,description,sort,status,created_at,updated_at) VALUES ('隐患状态','safety_hazard_status','隐患闭环状态',61,1,NOW(),NOW());
SET @d4=(SELECT id FROM dictionary_types WHERE code='safety_hazard_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d4,'待处理','pending',1,'warning',1,NOW(),NOW()),
(@d4,'整改中','processing',2,'primary',1,NOW(),NOW()),
(@d4,'待验证','resolved',3,'info',1,NOW(),NOW()),
(@d4,'已关闭','closed',4,'success',1,NOW(),NOW()),
(@d4,'已驳回','rejected',5,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 5. 验证结果
INSERT IGNORE INTO dictionary_types (name,code,description,sort,status,created_at,updated_at) VALUES ('验证结果','verify_result','隐患验证结果',62,1,NOW(),NOW());
SET @d5=(SELECT id FROM dictionary_types WHERE code='verify_result');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d5,'待验证','pending',1,'info',1,NOW(),NOW()),
(@d5,'已通过','passed',2,'success',1,NOW(),NOW()),
(@d5,'已驳回','rejected',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 二、建表 safety_hazards ==========
CREATE TABLE IF NOT EXISTS `safety_hazards` (
  `id`                    int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hazard_code`           varchar(50)  NOT NULL COMMENT '隐患编号（唯一）HAZ-YYYYMMDD-XXXX',
  `hazard_name`           varchar(200) NOT NULL COMMENT '隐患名称',
  `hazard_type`           varchar(30)  NOT NULL DEFAULT 'equipment' COMMENT '隐患类型（字典safety_hazard_type）',
  `hazard_level`          varchar(20)  NOT NULL DEFAULT 'general' COMMENT '隐患等级（字典safety_hazard_level）',
  `source_type`           varchar(30)  NOT NULL DEFAULT 'manual' COMMENT '来源类型（字典safety_hazard_source）',
  `source_id`             int(11) unsigned DEFAULT NULL COMMENT '来源记录ID',
  `location`              varchar(200) NOT NULL DEFAULT '' COMMENT '发现位置',
  `discovered_by`         int(11) unsigned NOT NULL DEFAULT '0' COMMENT '发现人ID',
  `discovered_by_name`    varchar(50)  NOT NULL DEFAULT '' COMMENT '发现人姓名',
  `discovered_at`         datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发现时间',
  `hazard_desc`           text         NOT NULL COMMENT '隐患描述',
  `hazard_images`         json         DEFAULT NULL COMMENT '隐患图片',
  `assigned_to`           int(11) unsigned DEFAULT NULL COMMENT '指派人ID',
  `assigned_to_name`      varchar(50)  NOT NULL DEFAULT '' COMMENT '指派人姓名',
  `handler_id`            int(11) unsigned DEFAULT NULL COMMENT '整改人ID',
  `handler_name`          varchar(50)  NOT NULL DEFAULT '' COMMENT '整改人姓名',
  `handler_deadline`      date         DEFAULT NULL COMMENT '整改期限',
  `handle_measure`        text         COMMENT '整改措施',
  `handle_attachments`    json         DEFAULT NULL COMMENT '整改附件',
  `handle_completed_at`   datetime     DEFAULT NULL COMMENT '整改完成时间',
  `verified_by`           int(11) unsigned DEFAULT NULL COMMENT '验证人ID',
  `verified_by_name`      varchar(50)  NOT NULL DEFAULT '' COMMENT '验证人姓名',
  `verified_at`           datetime     DEFAULT NULL COMMENT '验证时间',
  `verify_opinion`        varchar(500) NOT NULL DEFAULT '' COMMENT '验证意见',
  `verify_result`         varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '验证结果（字典verify_result）',
  `reject_reason`         varchar(500) NOT NULL DEFAULT '' COMMENT '驳回原因',
  `reject_count`          int(11)      NOT NULL DEFAULT '0' COMMENT '驳回次数',
  `reject_history`        json         DEFAULT NULL COMMENT '驳回历史',
  `verify_attachments`    json         DEFAULT NULL COMMENT '验证附件',
  `status`                varchar(20)  NOT NULL DEFAULT 'pending' COMMENT '状态（字典safety_hazard_status）',
  `remark`                text         COMMENT '备注',
  `create_time`           datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`           datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delete_time`           datetime     DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_hazard_code` (`hazard_code`),
  KEY `idx_status` (`status`),
  KEY `idx_hazard_level` (`hazard_level`),
  KEY `idx_discovered_at` (`discovered_at`),
  KEY `idx_handler_id` (`handler_id`),
  KEY `idx_verified_by` (`verified_by`),
  KEY `idx_source_type` (`source_type`),
  KEY `idx_discovered_by` (`discovered_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='隐患管理表';

-- ========== 三、权限 ==========
INSERT INTO permissions (name,code,type,parent_id,module,path,icon,api_url,sort,status,platform,description,created_at,updated_at) VALUES
('隐患列表查看','safety:hazard:list',1,0,'安全管理','/safety/hazard',NULL,NULL,10,1,1,NULL,NOW(),NOW()),
('隐患详情查询','safety:hazard:query',2,0,'安全管理','/safety/hazard',NULL,NULL,20,1,1,NULL,NOW(),NOW()),
('隐患登记新增','safety:hazard:add',2,0,'安全管理','/safety/hazard',NULL,NULL,30,1,1,NULL,NOW(),NOW()),
('隐患编辑修改','safety:hazard:edit',2,0,'安全管理','/safety/hazard',NULL,NULL,40,1,1,NULL,NOW(),NOW()),
('隐患删除','safety:hazard:delete',2,0,'安全管理','/safety/hazard',NULL,NULL,50,1,1,NULL,NOW(),NOW()),
('隐患导出','safety:hazard:export',2,0,'安全管理','/safety/hazard',NULL,NULL,60,1,1,NULL,NOW(),NOW()),
('隐患状态变更','safety:hazard:status',2,0,'安全管理','/safety/hazard',NULL,NULL,70,1,1,NULL,NOW(),NOW())
ON DUPLICATE KEY UPDATE name=VALUES(name),module=VALUES(module),path=VALUES(path),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

INSERT IGNORE INTO role_permissions (role_id,permission_id)
SELECT r.id,p.id FROM roles r CROSS JOIN permissions p WHERE r.code='super_admin' AND p.code LIKE 'safety:%';

-- ========== 四、菜单 ==========
-- 安全管理主菜单（一级）
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT 0,'安全管理','/safety','el-icon-warning','safety:view',15,1,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:view' AND deleted_at IS NULL);
SET @safety_menu = (SELECT id FROM menus WHERE permission='safety:view' AND deleted_at IS NULL LIMIT 1);
-- 隐患管理子菜单
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @safety_menu,'隐患管理','/safety/hazard','el-icon-warning-outline','safety:hazard:list',10,1,1,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:hazard:list' AND deleted_at IS NULL);
SET @hazard_menu = (SELECT id FROM menus WHERE permission='safety:hazard:list' AND deleted_at IS NULL LIMIT 1);
-- 隐患列表（三级）
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @hazard_menu,'隐患列表','/safety/hazard/index','el-icon-list','safety:hazard:list',10,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:hazard:list' AND path='/safety/hazard/index' AND deleted_at IS NULL);
-- 隐患登记
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @hazard_menu,'隐患登记','/safety/hazard/create','el-icon-edit-outline','safety:hazard:add',20,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:hazard:add' AND path='/safety/hazard/create' AND deleted_at IS NULL);
-- 隐患整改
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @hazard_menu,'隐患整改','/safety/hazard/handle','el-icon-s-tools','safety:hazard:edit',30,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:hazard:edit' AND path='/safety/hazard/handle' AND deleted_at IS NULL);
-- 验证任务
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @hazard_menu,'验证任务','/safety/hazard/verify','el-icon-finished','safety:hazard:status',40,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:hazard:status' AND path='/safety/hazard/verify' AND deleted_at IS NULL);
-- 预留：安全检查/安全培训/安全看板
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @safety_menu,'安全检查','/safety/inspection','el-icon-view','safety:inspection:view',20,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:inspection:view' AND deleted_at IS NULL);
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @safety_menu,'安全培训','/safety/training','el-icon-reading','safety:training:view',30,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:training:view' AND deleted_at IS NULL);
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system,created_at,updated_at)
SELECT @safety_menu,'安全看板','/safety/dashboard','el-icon-data-analysis','safety:dashboard:view',40,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='safety:dashboard:view' AND deleted_at IS NULL);
