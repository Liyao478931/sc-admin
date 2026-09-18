-- ============================================================
-- 权限数据（修正版：使用 SET @var 避免同表子查询限制）
-- 数据库：ly478931
-- ============================================================
-- 父节点：保养计划管理（type=1 菜单）
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`)
VALUES ('保养计划管理','device:maintenance:plan:view',1,0,'设备保养',50,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

SET @parent_id = (SELECT id FROM permissions WHERE code='device:maintenance:plan:view' LIMIT 1);

-- 保养等级权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养等级列表','device:maintenance:level:list',2,@parent_id,'设备保养',1,1,1,NOW(),NOW()),
('保养等级详情','device:maintenance:level:query',2,@parent_id,'设备保养',2,1,1,NOW(),NOW()),
('新增保养等级','device:maintenance:level:add',2,@parent_id,'设备保养',3,1,1,NOW(),NOW()),
('编辑保养等级','device:maintenance:level:edit',2,@parent_id,'设备保养',4,1,1,NOW(),NOW()),
('删除保养等级','device:maintenance:level:delete',2,@parent_id,'设备保养',5,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 保养模板权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养模板列表','device:maintenance:template:list',2,@parent_id,'设备保养',6,1,1,NOW(),NOW()),
('保养模板详情','device:maintenance:template:query',2,@parent_id,'设备保养',7,1,1,NOW(),NOW()),
('新增保养模板','device:maintenance:template:add',2,@parent_id,'设备保养',8,1,1,NOW(),NOW()),
('编辑保养模板','device:maintenance:template:edit',2,@parent_id,'设备保养',9,1,1,NOW(),NOW()),
('删除保养模板','device:maintenance:template:delete',2,@parent_id,'设备保养',10,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 保养计划权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养计划列表','device:maintenance:plan:list',2,@parent_id,'设备保养',11,1,1,NOW(),NOW()),
('保养计划详情','device:maintenance:plan:query',2,@parent_id,'设备保养',12,1,1,NOW(),NOW()),
('新增保养计划','device:maintenance:plan:add',2,@parent_id,'设备保养',13,1,1,NOW(),NOW()),
('编辑保养计划','device:maintenance:plan:edit',2,@parent_id,'设备保养',14,1,1,NOW(),NOW()),
('删除保养计划','device:maintenance:plan:delete',2,@parent_id,'设备保养',15,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);
