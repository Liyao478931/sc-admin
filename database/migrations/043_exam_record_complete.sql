-- =====================================================
-- 043_exam_record_complete.sql 考试管理模块补全（幂等可重复执行）
-- 补列 exam_record/answer + 字典 + 参数 + 菜单
-- =====================================================

-- ========== 一、safety_exam_record 补列（exam_name/exam_notice/delete_time） ==========
SET @c1 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_record' AND column_name='exam_name');
SET @s1 = IF(@c1=0,'ALTER TABLE `safety_exam_record` ADD COLUMN `exam_name` varchar(100) DEFAULT NULL COMMENT ''考试名称'' AFTER `exam_code`','SET @s1_skip=1');
PREPARE st1 FROM @s1; EXECUTE st1; DEALLOCATE PREPARE st1;
SET @c2 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_record' AND column_name='exam_notice');
SET @s2 = IF(@c2=0,'ALTER TABLE `safety_exam_record` ADD COLUMN `exam_notice` text DEFAULT NULL COMMENT ''考试须知'' AFTER `pass_count`','SET @s2_skip=1');
PREPARE st2 FROM @s2; EXECUTE st2; DEALLOCATE PREPARE st2;
SET @c3 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_record' AND column_name='delete_time');
SET @s3 = IF(@c3=0,'ALTER TABLE `safety_exam_record` ADD COLUMN `delete_time` datetime DEFAULT NULL COMMENT ''软删除时间'' AFTER `update_time`','SET @s3_skip=1');
PREPARE st3 FROM @s3; EXECUTE st3; DEALLOCATE PREPARE st3;

-- ========== 二、safety_exam_answer 补列（考生状态/开始时间/延长分钟） ==========
SET @c4 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_answer' AND column_name='status');
SET @s4 = IF(@c4=0,'ALTER TABLE `safety_exam_answer` ADD COLUMN `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''0未开始 1进行中 2已交卷'' AFTER `user_name`','SET @s4_skip=1');
PREPARE st4 FROM @s4; EXECUTE st4; DEALLOCATE PREPARE st4;
SET @c5 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_answer' AND column_name='start_time');
SET @s5 = IF(@c5=0,'ALTER TABLE `safety_exam_answer` ADD COLUMN `start_time` datetime DEFAULT NULL COMMENT ''考生开始考试时间'' AFTER `status`','SET @s5_skip=1');
PREPARE st5 FROM @s5; EXECUTE st5; DEALLOCATE PREPARE st5;
SET @c6 = (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE table_schema=DATABASE() AND table_name='safety_exam_answer' AND column_name='extend_minutes');
SET @s6 = IF(@c6=0,'ALTER TABLE `safety_exam_answer` ADD COLUMN `extend_minutes` int(11) NOT NULL DEFAULT 0 COMMENT ''延长考试分钟数'' AFTER `exam_duration`','SET @s6_skip=1');
PREPARE st6 FROM @s6; EXECUTE st6; DEALLOCATE PREPARE st6;

-- ========== 三、数据字典（幂等） ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('考试状态','exam_status','培训考试状态',88,1,NOW(),NOW());
SET @dt1=(SELECT id FROM dictionary_types WHERE code='exam_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt1,'待开始','pending',1,'info',1,NOW(),NOW()),
(@dt1,'进行中','in_progress',2,'primary',1,NOW(),NOW()),
(@dt1,'已结束','ended',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('考试类型','exam_type','培训考试类型',89,1,NOW(),NOW());
SET @dt2=(SELECT id FROM dictionary_types WHERE code='exam_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@dt2,'正式考试','formal',1,'danger',1,NOW(),NOW()),
(@dt2,'练习模式','practice',2,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 四、系统参数（settings + system_params，幂等） ==========
INSERT INTO `settings` (`key`,`value`,`created_at`,`updated_at`) VALUES
('exam_auto_score','1',NOW(),NOW())
ON DUPLICATE KEY UPDATE `updated_at`=NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('exam_record_code_prefix','E','考试编号前缀','safety','string','考试编号前缀（E-YYYYMMDD-XXXX）',73,0,1,NOW(),NOW()),
('exam_auto_score','1','是否自动判卷','safety','string','考试交卷后是否自动判卷（1是 0否）',74,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、菜单：培训考试 → 考试管理（幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'考试管理','/safety/training/exam/record','el-icon-edit','safety:training:exam:list',3,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:training:exam:list' AND m.`path`='/safety/training/exam' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:training:exam:list' AND x.`path`='/safety/training/exam/record' AND x.`deleted_at` IS NULL);
