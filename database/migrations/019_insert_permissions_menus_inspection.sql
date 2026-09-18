-- =====================================================
-- 019_insert_permissions_menus_inspection.sql
-- 设备巡检模块：权限 + 菜单 + 角色授权
-- =====================================================

-- ---------- 1. 权限定义 ----------
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('巡检计划列表','device:inspection:plan:list',2,0,'设备巡检','/device/inspection',NULL,NULL,10,1,1,NULL,NOW(),NOW()),
('巡检计划新增','device:inspection:plan:add',2,0,'设备巡检','/device/inspection',NULL,NULL,20,1,1,NULL,NOW(),NOW()),
('巡检计划编辑','device:inspection:plan:edit',2,0,'设备巡检','/device/inspection',NULL,NULL,30,1,1,NULL,NOW(),NOW()),
('巡检计划删除','device:inspection:plan:delete',2,0,'设备巡检','/device/inspection',NULL,NULL,40,1,1,NULL,NOW(),NOW()),
('模板列表','device:inspection:template:list',2,0,'设备巡检','/device/inspection',NULL,NULL,50,1,1,NULL,NOW(),NOW()),
('模板新增','device:inspection:template:add',2,0,'设备巡检','/device/inspection',NULL,NULL,60,1,1,NULL,NOW(),NOW()),
('模板编辑','device:inspection:template:edit',2,0,'设备巡检','/device/inspection',NULL,NULL,70,1,1,NULL,NOW(),NOW()),
('模板删除','device:inspection:template:delete',2,0,'设备巡检','/device/inspection',NULL,NULL,80,1,1,NULL,NOW(),NOW()),
('任务列表','device:inspection:task:list',2,0,'设备巡检','/device/inspection',NULL,NULL,90,1,1,NULL,NOW(),NOW()),
('任务分配','device:inspection:task:assign',2,0,'设备巡检','/device/inspection',NULL,NULL,100,1,1,NULL,NOW(),NOW()),
('任务编辑','device:inspection:task:edit',2,0,'设备巡检','/device/inspection',NULL,NULL,110,1,1,NULL,NOW(),NOW()),
('开始执行','device:inspection:execute:start',2,0,'设备巡检','/device/inspection',NULL,NULL,120,1,1,NULL,NOW(),NOW()),
('提交结果','device:inspection:execute:submit',2,0,'设备巡检','/device/inspection',NULL,NULL,130,1,1,NULL,NOW(),NOW()),
('记录列表','device:inspection:record:list',2,0,'设备巡检','/device/inspection',NULL,NULL,140,1,1,NULL,NOW(),NOW()),
('记录审核','device:inspection:record:audit',2,0,'设备巡检','/device/inspection',NULL,NULL,150,1,1,NULL,NOW(),NOW()),
('记录导出','device:inspection:record:export',2,0,'设备巡检','/device/inspection',NULL,NULL,160,1,1,NULL,NOW(),NOW()),
('隐患列表','device:inspection:hazard:list',2,0,'设备巡检','/device/inspection',NULL,NULL,170,1,1,NULL,NOW(),NOW()),
('隐患处理','device:inspection:hazard:handle',2,0,'设备巡检','/device/inspection',NULL,NULL,180,1,1,NULL,NOW(),NOW()),
('隐患关闭','device:inspection:hazard:close',2,0,'设备巡检','/device/inspection',NULL,NULL,190,1,1,NULL,NOW(),NOW()),
('隐患转维修','device:inspection:hazard:convert',2,0,'设备巡检','/device/inspection',NULL,NULL,200,1,1,NULL,NOW(),NOW()),
('统计看板','device:inspection:statistics:view',2,0,'设备巡检','/device/inspection',NULL,NULL,210,1,1,NULL,NOW(),NOW())
ON DUPLICATE KEY UPDATE name=VALUES(name),module=VALUES(module),path=VALUES(path),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ---------- 2. 分配权限给超管 ----------
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.id,p.id FROM roles r CROSS JOIN permissions p
WHERE r.code='super_admin' AND p.code LIKE 'device:inspection:%';

-- ---------- 3. 侧边栏菜单：设备管理下增加"设备巡检"子菜单 ----------
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.id,'设备巡检','/device/inspection','el-icon-s-operation','device:inspection:plan:list',40,1,2,0,NOW(),NOW()
FROM menus m
WHERE m.permission='device:manage:view' AND m.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM menus x WHERE x.permission='device:inspection:plan:list' AND x.deleted_at IS NULL);
