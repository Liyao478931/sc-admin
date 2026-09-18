-- =====================================================
-- 102_add_company_params.sql
-- 合同模板生成：我司（甲方/乙方）基础信息参数
-- 用于购销合同模板中：采购→我司为甲方；销售/维修→我司为乙方
-- 参数值请在「系统参数」页面维护
-- 幂等写法，可重复执行
-- =====================================================

INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('company_name','我司公司名称','SC Admin','string','business','合同模板生成时我司（甲方/乙方）公司名称',20,1,0,NOW(),NOW()),
('company_address','我司公司地址','','string','business','合同模板生成时我司地址',21,1,0,NOW(),NOW()),
('company_phone','我司公司电话','','string','business','合同模板生成时我司电话',22,1,0,NOW(),NOW()),
('company_bank','我司开户银行','','string','business','合同模板生成时我司开户银行',23,1,0,NOW(),NOW()),
('company_account','我司银行账号','','string','business','合同模板生成时我司银行账号',24,1,0,NOW(),NOW()),
('company_tax','我司税号','','string','business','合同模板生成时我司税号',25,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();
