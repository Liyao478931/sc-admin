-- =====================================================
-- 100_create_contract_template.sql
-- 经营管理 → 订单中心 → 合同管理 → 合同模板管理
--   1. 建表 2 张：business_contract_templates（模板）/ business_contract_template_variables（变量）
--   2. 预置变量 24 条
--   3. 预置购销合同模板（HTML，含变量占位符）
--   4. 权限：business:contract:template（菜单）+ add/edit/delete/export（按钮）
--   5. 菜单：合同管理 → 合同模板管理
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、合同模板表 ==========
CREATE TABLE IF NOT EXISTS `business_contract_templates` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_code` varchar(50) NOT NULL DEFAULT '' COMMENT '模板编号 TPL-YYYYMMDD-XXXX',
  `template_name` varchar(100) NOT NULL DEFAULT '' COMMENT '模板名称',
  `template_type` varchar(20) NOT NULL DEFAULT 'standard' COMMENT '模板类型：standard标准 custom自定义',
  `contract_type` varchar(30) NOT NULL DEFAULT '' COMMENT '适用合同类型：sales/purchase/repair_service',
  `content` longtext NOT NULL COMMENT '模板内容（HTML，含变量占位符）',
  `style` text COMMENT '模板样式（CSS）',
  `variables` json DEFAULT NULL COMMENT '模板使用的变量列表',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认模板',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `version` int(11) NOT NULL DEFAULT 1 COMMENT '版本号',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`),
  KEY `idx_type_default` (`contract_type`, `is_default`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合同模板表';

-- ========== 二、合同模板变量表 ==========
CREATE TABLE IF NOT EXISTS `business_contract_template_variables` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `var_key` varchar(50) NOT NULL DEFAULT '' COMMENT '变量键（如 customer_name）',
  `var_name` varchar(100) NOT NULL DEFAULT '' COMMENT '变量名称',
  `var_category` varchar(30) NOT NULL DEFAULT 'basic' COMMENT '分类：basic/customer/supplier/items/amount/system/custom',
  `var_type` varchar(20) NOT NULL DEFAULT 'string' COMMENT '类型：string/number/date/amount/html',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `example` varchar(255) DEFAULT NULL COMMENT '示例值',
  `is_system` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否系统预置',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_var_key` (`var_key`),
  KEY `idx_var_category` (`var_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合同模板变量表';

-- ========== 三、预置变量 24 条 ==========
INSERT INTO `business_contract_template_variables` (`var_key`,`var_name`,`var_category`,`var_type`,`description`,`example`,`is_system`,`create_time`,`update_time`) VALUES
('contract_no','合同编号','basic','string','合同编号','CT-20260810-0001',1,NOW(),NOW()),
('contract_name','合同名称','basic','string','合同名称','液压支架维修合同',1,NOW(),NOW()),
('sign_date','签订日期','basic','date','签订日期','2026年08月10日',1,NOW(),NOW()),
('sign_location','签订地点','basic','string','签订地点','山西省大同市',1,NOW(),NOW()),
('customer_name','客户名称','customer','string','客户名称','大同煤矿集团',1,NOW(),NOW()),
('customer_address','客户地址','customer','string','客户地址','山西省大同市矿区',1,NOW(),NOW()),
('customer_contact','客户联系人','customer','string','客户联系人','张经理',1,NOW(),NOW()),
('customer_phone','客户电话','customer','string','客户电话','0352-1234567',1,NOW(),NOW()),
('customer_bank','客户开户银行','customer','string','客户开户银行','工商银行大同分行',1,NOW(),NOW()),
('customer_account','客户银行账号','customer','string','客户银行账号','1400000000000000000',1,NOW(),NOW()),
('customer_tax','客户税号','customer','string','客户税号','91140000000000000X',1,NOW(),NOW()),
('supplier_name','供应商名称','supplier','string','供应商名称','',1,NOW(),NOW()),
('supplier_address','供应商地址','supplier','string','供应商地址','山西省大同市开发区',1,NOW(),NOW()),
('supplier_contact','供应商联系人','supplier','string','供应商联系人','李经理',1,NOW(),NOW()),
('supplier_phone','供应商电话','supplier','string','供应商电话','0352-7654321',1,NOW(),NOW()),
('supplier_bank','供应商开户银行','supplier','string','供应商开户银行','建设银行大同分行',1,NOW(),NOW()),
('supplier_account','供应商银行账号','supplier','string','供应商银行账号','1500000000000000000',1,NOW(),NOW()),
('supplier_tax','供应商税号','supplier','string','供应商税号','91140000000000000Y',1,NOW(),NOW()),
('items_table','明细表格','items','html','产品/服务明细表格（自动生成）','HTML表格',1,NOW(),NOW()),
('total_amount','含税总金额','amount','amount','含税总金额','158000.00',1,NOW(),NOW()),
('total_amount_cn','人民币大写','amount','string','含税总金额人民币大写','壹拾伍万捌仟元整',1,NOW(),NOW()),
('total_amount_without_tax','不含税金额','amount','amount','不含税金额','139823.01',1,NOW(),NOW()),
('tax_amount','税额','amount','amount','税额','18176.99',1,NOW(),NOW()),
('payment_terms','付款方式','system','string','付款方式','验收合格后付清全款',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `var_name`=VALUES(`var_name`),`var_category`=VALUES(`var_category`),`var_type`=VALUES(`var_type`),`description`=VALUES(`description`),`example`=VALUES(`example`),`update_time`=NOW();

-- 系统参数：付款方式默认值
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('contract_payment_terms','合同付款方式默认值','验收合格后付清全款','string','business','合同模板生成时付款方式默认值',12,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、预置购销合同模板 ==========
INSERT INTO `business_contract_templates` (`template_code`,`template_name`,`template_type`,`contract_type`,`content`,`style`,`variables`,`is_default`,`status`,`version`,`created_by`,`created_by_name`,`create_time`,`update_time`)
SELECT 'TPL-20260101-0001','购销合同（标准）','standard','purchase',
'<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
body { font-family: SimSun, serif; font-size: 14px; padding: 40px; }
.contract-title { text-align: center; font-size: 22px; font-weight: bold; padding: 20px 0; }
.contract-info { margin: 10px 0; }
table { width: 100%; border-collapse: collapse; margin: 15px 0; }
th, td { border: 1px solid #000; padding: 6px 10px; text-align: center; }
th { background: #f5f5f5; font-weight: bold; }
.text-left { text-align: left; }
.text-right { text-align: right; }
.sign-area { margin-top: 30px; }
.sign-area table { border: none; }
.sign-area td { border: none; vertical-align: top; padding: 10px 20px; }
.clause { margin: 8px 0; }
</style>
</head>
<body>

<div class="contract-title">购 销 合 同</div>

<div class="contract-info">
  <p><strong>甲方：</strong>{customer_name} &nbsp;&nbsp;&nbsp;&nbsp; <strong>签订时间：</strong>{sign_date}</p>
  <p><strong>乙方：</strong>{supplier_name} &nbsp;&nbsp;&nbsp;&nbsp; <strong>签订地点：</strong>{sign_location}</p>
</div>

<p><strong>第一条　序号、名称、型号、数量、价款等。</strong></p>

{items_table}

<p><strong>第二条　付款方式：</strong>{payment_terms}</p>

<p><strong>第三条　质量标准：</strong>确保设备或设施满足甲方的使用需求。</p>

<p><strong>第四条　交货方式及运输费用：</strong>由乙方负责。</p>

<p><strong>第五条　验收期限：</strong>收到货后7日内验收，逾期不验收视为合格。</p>

<p><strong>第六条　合同争议解决方式：</strong>本合同履行过程中发生的争议，由双方协商解决，协商不成的，提交需方当地人民法院起诉处理。</p>

<p><strong>第七条　违约责任：</strong>按《民法典》规定，违约方承担相应违约责任。</p>

<p><strong>第八条　本合同一式四份，甲乙双方各持两份。</strong></p>

<p><strong>第九条　本合同经双方法定代表人或委托代理人签字盖章后生效。</strong></p>

<div class="sign-area">
  <table>
    <tr>
      <td style="width:50%;">
        <p><strong>甲方</strong></p>
        <p>甲方（章）：{customer_seal}</p>
        <p>地址：{customer_address}</p>
        <p>法定代表人：{customer_legal_person}</p>
        <p>委托代理人：{customer_agent}</p>
        <p>电话：{customer_phone}</p>
        <p>传真：{customer_fax}</p>
        <p>开户银行：{customer_bank}</p>
        <p>帐号：{customer_account}</p>
        <p>税号：{customer_tax}</p>
      </td>
      <td style="width:50%;">
        <p><strong>乙方</strong></p>
        <p>乙方（章）：{supplier_seal}</p>
        <p>地址：{supplier_address}</p>
        <p>法定代表人：{supplier_legal_person}</p>
        <p>委托代理人：{supplier_agent}</p>
        <p>电话：{supplier_phone}</p>
        <p>传真：{supplier_fax}</p>
        <p>开户银行：{supplier_bank}</p>
        <p>帐号：{supplier_account}</p>
        <p>税号：{supplier_tax}</p>
      </td>
    </tr>
  </table>
</div>

</body>
</html>',
NULL,
JSON_ARRAY('contract_no','contract_name','sign_date','sign_location','customer_name','supplier_name','items_table','total_amount','total_amount_cn','payment_terms'),
1,1,1,0,'system',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `business_contract_templates` WHERE `template_code`='TPL-20260101-0001');

-- ========== 五、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('合同模板管理','business:contract:template',1,0,'business','/business/contract/template','el-icon-document-copy',NULL,42,1,1,'合同模板管理（菜单）',NOW(),NOW()),
('合同模板新增','business:contract:template:add',2,0,'business',NULL,NULL,NULL,43,1,1,'新增/复制/导入模板',NOW(),NOW()),
('合同模板编辑','business:contract:template:edit',2,0,'business',NULL,NULL,NULL,44,1,1,'编辑/设默认/启用停用模板',NOW(),NOW()),
('合同模板删除','business:contract:template:delete',2,0,'business',NULL,NULL,NULL,45,1,1,'删除模板',NOW(),NOW()),
('合同模板导出','business:contract:template:export',2,0,'business',NULL,NULL,NULL,46,1,1,'导出模板/导出合同PDF/Word',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:contract:template','business:contract:template:add','business:contract:template:edit','business:contract:template:delete','business:contract:template:export');

-- ========== 六、菜单（合同管理 → 合同模板管理） ==========
-- 注：合同管理菜单当前可能被调整过父级，仅按名称匹配
SET @contract_menu_id = (SELECT id FROM menus WHERE name='合同管理' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @contract_menu_id, '合同模板管理', '/business/contract/template', 'el-icon-document-copy', 'business:contract:template', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:contract:template' AND deleted_at IS NULL AND type=2);
