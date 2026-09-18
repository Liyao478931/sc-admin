-- 125_create_warehouse_extras.sql
-- 仓储管理补充功能权限：物料分类管理 / 物料批量操作 / 货位批量创建 / 货位二维码
-- 1. 权限 10 条并授权 super_admin
-- 2. 菜单：基础设置 -> 物料分类管理
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:setting:material:category:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN
--     ('warehouse:setting:material:category:view','warehouse:setting:material:category:add','warehouse:setting:material:category:edit','warehouse:setting:material:category:delete',
--      'warehouse:setting:material:batch:enable','warehouse:setting:material:batch:disable','warehouse:setting:material:batch:category','warehouse:setting:material:batch:delete',
--      'warehouse:setting:location:batch:add','warehouse:setting:location:qrcode:generate'));
--   DELETE FROM permissions WHERE code IN
--     ('warehouse:setting:material:category:view','warehouse:setting:material:category:add','warehouse:setting:material:category:edit','warehouse:setting:material:category:delete',
--      'warehouse:setting:material:batch:enable','warehouse:setting:material:batch:disable','warehouse:setting:material:batch:category','warehouse:setting:material:batch:delete',
--      'warehouse:setting:location:batch:add','warehouse:setting:location:qrcode:generate');

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('物料分类查看','warehouse:setting:material:category:view',2,0,'warehouse','/warehouse/setting/material/category','el-icon-folder-opened',NULL,25,1,1,'物料分类管理-查看（菜单）',NOW(),NOW()),
('物料分类新增','warehouse:setting:material:category:add',2,0,'warehouse',NULL,NULL,NULL,26,1,1,'新增物料分类',NOW(),NOW()),
('物料分类编辑','warehouse:setting:material:category:edit',2,0,'warehouse',NULL,NULL,NULL,27,1,1,'编辑物料分类',NOW(),NOW()),
('物料分类删除','warehouse:setting:material:category:delete',2,0,'warehouse',NULL,NULL,NULL,28,1,1,'删除物料分类',NOW(),NOW()),
('物料批量启用','warehouse:setting:material:batch:enable',2,0,'warehouse',NULL,NULL,NULL,29,1,1,'批量启用物料',NOW(),NOW()),
('物料批量停用','warehouse:setting:material:batch:disable',2,0,'warehouse',NULL,NULL,NULL,30,1,1,'批量停用物料',NOW(),NOW()),
('物料批量改分类','warehouse:setting:material:batch:category',2,0,'warehouse',NULL,NULL,NULL,31,1,1,'批量修改物料分类',NOW(),NOW()),
('物料批量删除','warehouse:setting:material:batch:delete',2,0,'warehouse',NULL,NULL,NULL,32,1,1,'批量删除物料',NOW(),NOW()),
('货位批量创建','warehouse:setting:location:batch:add',2,0,'warehouse',NULL,NULL,NULL,33,1,1,'批量创建货位',NOW(),NOW()),
('货位二维码生成','warehouse:setting:location:qrcode:generate',2,0,'warehouse',NULL,NULL,NULL,34,1,1,'生成货位二维码',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN
    ('warehouse:setting:material:category:view','warehouse:setting:material:category:add','warehouse:setting:material:category:edit','warehouse:setting:material:category:delete',
     'warehouse:setting:material:batch:enable','warehouse:setting:material:batch:disable','warehouse:setting:material:batch:category','warehouse:setting:material:batch:delete',
     'warehouse:setting:location:batch:add','warehouse:setting:location:qrcode:generate');

-- 菜单：基础设置 -> 物料分类管理
SET @setting_menu_id = (SELECT id FROM menus WHERE permission='warehouse:setting' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @setting_menu_id, '物料分类管理', '/warehouse/setting/material/category', 'el-icon-folder-opened', 'warehouse:setting:material:category:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:setting:material:category:view' AND deleted_at IS NULL AND parent_id=@setting_menu_id);
