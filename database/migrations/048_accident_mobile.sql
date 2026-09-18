-- =====================================================
-- 048_accident_mobile.sql 员工端事故上报（幂等可重复执行）
-- =====================================================
-- 1. 字典：事故状态加"草稿(draft)"
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at)
SELECT id,'草稿','draft',0,'info',1,NOW(),NOW()
FROM dictionary_types WHERE code='safety_accident_status'
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 2. 应用路径管理（app_paths）
INSERT INTO `app_paths` (`name`,`path`,`page_key`,`platform`,`page_type`,`require_auth`,`status`,`created_at`,`updated_at`) VALUES
('事故上报','/pages/sub/safety/accident-report','safety-accident-report',0,2,1,1,NOW(),NOW()),
('我的上报','/pages/sub/safety/accident-list','safety-accident-list',0,2,1,1,NOW(),NOW()),
('上报详情','/pages/sub/safety/accident-detail','safety-accident-detail',0,2,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();

-- 3. 员工端功能菜单：事故上报
INSERT INTO `app_functions` (`name`,`code`,`icon`,`path_id`,`permission`,`sort`,`status`,`created_at`,`updated_at`)
SELECT '事故上报','accident_report','el-icon-warning',
       (SELECT id FROM `app_paths` WHERE `path`='/pages/sub/safety/accident-report' AND `deleted_at` IS NULL),
       '',55,1,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `app_functions` WHERE `code`='accident_report');
