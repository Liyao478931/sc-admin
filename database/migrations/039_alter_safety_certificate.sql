-- =====================================================
-- 039_alter_safety_certificate.sql
-- 培训证书增强：补充员工/培训/颁发完整信息字段 + 颁发机构参数
-- =====================================================

-- 培训证书表：补充员工信息、培训信息、颁发信息字段
ALTER TABLE `safety_training_certificate`
  ADD COLUMN `user_idcard`       varchar(18)  DEFAULT NULL COMMENT '员工身份证号（冗余）' AFTER `user_name`,
  ADD COLUMN `user_employee_no`  varchar(50)  DEFAULT NULL COMMENT '员工工号（冗余）' AFTER `user_idcard`,
  ADD COLUMN `user_department`   varchar(100) DEFAULT NULL COMMENT '所属部门（冗余）' AFTER `user_employee_no`,
  ADD COLUMN `user_position`     varchar(100) DEFAULT NULL COMMENT '岗位（冗余）' AFTER `user_department`,
  ADD COLUMN `training_content`  text         DEFAULT NULL COMMENT '培训内容（冗余）' AFTER `training_type_name`,
  ADD COLUMN `training_duration` decimal(5,1) NOT NULL DEFAULT 0 COMMENT '培训时长（冗余）' AFTER `training_content`,
  ADD COLUMN `training_mode`     varchar(20)  DEFAULT NULL COMMENT '培训方式（冗余）' AFTER `training_duration`,
  ADD COLUMN `issue_authority`   varchar(100) DEFAULT '' COMMENT '颁发机构' AFTER `validity_years`,
  ADD COLUMN `verify_url`        varchar(255) DEFAULT NULL COMMENT '验证查询网址' AFTER `file_path`;

-- 系统参数：证书颁发机构
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('certificate_issue_authority', '', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('certificate_issue_authority', '', '证书颁发机构', 'safety', 'string', '培训证书颁发机构名称', 63, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();
