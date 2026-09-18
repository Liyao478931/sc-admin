-- ============================================================
-- 保养任务权限数据
-- 数据库：ly478931
-- 父节点：保养计划管理 device:maintenance:plan:view
-- ============================================================
SET @parent_id = (SELECT id FROM permissions WHERE code='device:maintenance:plan:view' LIMIT 1);

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养任务列表','device:maintenance:task:list',2,@parent_id,'设备保养',16,1,1,NOW(),NOW()),
('保养任务详情','device:maintenance:task:query',2,@parent_id,'设备保养',17,1,1,NOW(),NOW()),
('分配执行人','device:maintenance:task:assign',2,@parent_id,'设备保养',18,1,1,NOW(),NOW()),
('取消保养任务','device:maintenance:task:edit',2,@parent_id,'设备保养',19,1,1,NOW(),NOW()),
('手动生成任务','device:maintenance:task:add',2,@parent_id,'设备保养',20,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);
