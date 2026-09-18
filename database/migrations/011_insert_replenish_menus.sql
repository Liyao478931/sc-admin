-- 011 新增补货建议与安全生产大屏菜单
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system)
SELECT 204,'补货建议','/admin/replenish.html','warehouse','warehouse:replenish:view',208,1,2,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:replenish:view');
INSERT INTO menus (parent_id,name,path,icon,permission,sort,status,type,is_system)
SELECT 41,'安全生产大屏','/admin/safety-board.html','safety','safety:dashboard:view',50,1,2,0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/admin/safety-board.html');
