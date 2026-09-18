-- =====================================================
-- 102_create_settings_company.sql
-- 系统设置 → 公司信息管理（完整规格）
--   1. settings_company 我方公司信息（~50 字段 + 状态）
--   2. settings_company_partner 客户/合作方默认信息（~39 字段）
--   3. 9 个数据字典（经营状态/公司类型/纳税人类型/税率/发票类型/信用等级/账户类型/付款方式/交货方式）
--   4. 权限：settings:company（查看/编辑）+ :publish（发布）+ :sync（同步）
--   5. 菜单：系统设置 → 公司信息
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、我方公司信息表 ==========
CREATE TABLE IF NOT EXISTS `settings_company` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  -- 基础工商信息
  `company_name` varchar(200) NOT NULL DEFAULT '' COMMENT '公司全称',
  `company_short_name` varchar(50) DEFAULT NULL COMMENT '公司简称',
  `company_en_name` varchar(200) DEFAULT NULL COMMENT '英文名称',
  `legal_person` varchar(50) DEFAULT NULL COMMENT '法定代表人',
  `credit_code` varchar(50) DEFAULT NULL COMMENT '统一社会信用代码（18位）',
  `registered_capital` varchar(50) DEFAULT NULL COMMENT '注册资本',
  `establish_date` date DEFAULT NULL COMMENT '成立日期',
  `business_term_start` date DEFAULT NULL COMMENT '营业期限起始',
  `business_term_end` date DEFAULT NULL COMMENT '营业期限截止',
  `business_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '经营状态（字典 company_business_status：1在营2注销3吊销4迁出5停业）',
  `company_type` varchar(50) DEFAULT NULL COMMENT '公司类型（字典 company_type code）',
  `industry` varchar(100) DEFAULT NULL COMMENT '所属行业',
  `business_scope` text COMMENT '经营范围',
  -- 联系方式
  `phone` varchar(50) DEFAULT NULL COMMENT '联系电话',
  `hotline` varchar(50) DEFAULT NULL COMMENT '客服热线',
  `fax` varchar(50) DEFAULT NULL COMMENT '传真号码',
  `email` varchar(100) DEFAULT NULL COMMENT '电子邮箱',
  `website` varchar(200) DEFAULT NULL COMMENT '企业官网',
  `zipcode` varchar(20) DEFAULT NULL COMMENT '邮政编码',
  `address` varchar(255) DEFAULT NULL COMMENT '公司地址',
  -- 资质证照（json 图片）
  `business_license` json DEFAULT NULL COMMENT '营业执照',
  `org_code_cert` json DEFAULT NULL COMMENT '组织机构代码证',
  `tax_cert` json DEFAULT NULL COMMENT '税务登记证',
  `account_permit` json DEFAULT NULL COMMENT '开户许可证',
  `safety_production_cert` json DEFAULT NULL COMMENT '安全生产许可证',
  `iso9001_cert` json DEFAULT NULL COMMENT '质量管理体系认证证书',
  `iso14001_cert` json DEFAULT NULL COMMENT '环境管理体系认证证书',
  `ohsas_cert` json DEFAULT NULL COMMENT '职业健康安全管理体系认证证书',
  `other_certs` json DEFAULT NULL COMMENT '其他资质证书（多图）',
  -- 品牌形象
  `logo` json DEFAULT NULL COMMENT '公司Logo',
  `favicon` json DEFAULT NULL COMMENT '网站Favicon',
  `brand_slogan` varchar(200) DEFAULT NULL COMMENT '品牌标语',
  `brand_color` varchar(100) DEFAULT NULL COMMENT '品牌色（主色/辅色）',
  `promo_video` varchar(500) DEFAULT NULL COMMENT '公司宣传片（视频链接）',
  -- 社交平台
  `wechat_name` varchar(100) DEFAULT NULL COMMENT '微信公众号',
  `wechat_appid` varchar(100) DEFAULT NULL COMMENT '微信AppID',
  `weibo_url` varchar(300) DEFAULT NULL COMMENT '微博链接',
  `douyin_url` varchar(300) DEFAULT NULL COMMENT '抖音链接',
  `wecom_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT '企业微信是否开通',
  `wecom_id` varchar(100) DEFAULT NULL COMMENT '企业微信ID',
  `wecom_secret` varchar(200) DEFAULT NULL COMMENT '企业微信Secret',
  -- 网站备案
  `icp_no` varchar(100) DEFAULT NULL COMMENT 'ICP备案号',
  `police_record_no` varchar(100) DEFAULT NULL COMMENT '公安备案号',
  `copyright` varchar(300) DEFAULT NULL COMMENT '版权信息',
  `filing_subject` varchar(200) DEFAULT NULL COMMENT '备案主体名称',
  `filing_subject_type` varchar(50) DEFAULT NULL COMMENT '备案主体性质（字典）',
  -- 公司简介
  `intro` text COMMENT '公司简介（富文本HTML）',
  -- 地理位置
  `geo_lng` varchar(30) DEFAULT NULL COMMENT '经度',
  `geo_lat` varchar(30) DEFAULT NULL COMMENT '纬度',
  `map_location` varchar(255) DEFAULT NULL COMMENT '地图位置',
  `traffic_guide` varchar(255) DEFAULT NULL COMMENT '交通指引',
  -- 状态与发布
  `status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '状态：draft草稿 published已发布',
  `publish_time` datetime DEFAULT NULL COMMENT '发布时间',
  `updated_by` int(11) NOT NULL DEFAULT 0 COMMENT '最后更新人ID',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公司信息配置表（我方，单行 id=1）';

INSERT IGNORE INTO `settings_company` (`id`,`company_name`,`status`,`create_time`,`update_time`)
VALUES (1,'SC Admin','draft',NOW(),NOW());

-- ========== 二、客户/合作方默认信息表 ==========
CREATE TABLE IF NOT EXISTS `settings_company_partner` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  -- 甲方基本信息
  `party_name` varchar(200) DEFAULT NULL COMMENT '甲方名称',
  `party_address` varchar(255) DEFAULT NULL COMMENT '甲方地址',
  `party_legal_person` varchar(50) DEFAULT NULL COMMENT '法定代表人',
  `party_agent` varchar(50) DEFAULT NULL COMMENT '委托代理人',
  `party_phone` varchar(50) DEFAULT NULL COMMENT '联系电话',
  `party_fax` varchar(50) DEFAULT NULL COMMENT '传真号码',
  -- 银行账户信息
  `bank_name` varchar(100) DEFAULT NULL COMMENT '开户银行',
  `bank_account` varchar(50) DEFAULT NULL COMMENT '银行账号',
  `account_type` varchar(50) DEFAULT NULL COMMENT '账户类型（字典 account_type）',
  `bank_branch_code` varchar(100) DEFAULT NULL COMMENT '开户行联行号',
  -- 财务税务信息
  `tax_no` varchar(50) DEFAULT NULL COMMENT '税号',
  `vat_type` varchar(50) DEFAULT NULL COMMENT '纳税人类型（字典 vat_type）',
  `vat_rate` varchar(20) DEFAULT NULL COMMENT '增值税税率（字典 vat_rate）',
  `invoice_types` varchar(200) DEFAULT NULL COMMENT '发票类型（字典 invoice_type，逗号分隔）',
  `invoice_address` varchar(255) DEFAULT NULL COMMENT '发票邮寄地址',
  `finance_contact` varchar(50) DEFAULT NULL COMMENT '财务联系人',
  `finance_phone` varchar(50) DEFAULT NULL COMMENT '财务联系电话',
  `finance_email` varchar(100) DEFAULT NULL COMMENT '财务邮箱',
  -- 印章管理（json 图片）
  `seal_company` json DEFAULT NULL COMMENT '公章',
  `seal_contract` json DEFAULT NULL COMMENT '合同专用章',
  `seal_finance` json DEFAULT NULL COMMENT '财务专用章',
  `seal_invoice` json DEFAULT NULL COMMENT '发票专用章',
  `seal_legal` json DEFAULT NULL COMMENT '法定代表人章',
  -- 合同模板默认配置
  `default_contract_template` varchar(300) DEFAULT NULL COMMENT '默认合同模板文件',
  `payment_methods` varchar(200) DEFAULT NULL COMMENT '付款方式（字典 payment_method，逗号分隔）',
  `payment_conditions` varchar(500) DEFAULT NULL COMMENT '付款条件',
  `warranty_months` varchar(50) DEFAULT NULL COMMENT '质保期',
  `delivery_methods` varchar(200) DEFAULT NULL COMMENT '交货方式（字典 delivery_method，逗号分隔）',
  -- 联系人信息
  `primary_contact` varchar(50) DEFAULT NULL COMMENT '主要联系人',
  `primary_contact_title` varchar(50) DEFAULT NULL COMMENT '主要联系人职务',
  `primary_contact_phone` varchar(50) DEFAULT NULL COMMENT '主要联系人手机',
  `primary_contact_email` varchar(100) DEFAULT NULL COMMENT '主要联系人邮箱',
  `primary_contact_wechat` varchar(100) DEFAULT NULL COMMENT '主要联系人微信',
  `primary_contact_wecom` varchar(100) DEFAULT NULL COMMENT '主要联系人企业微信',
  `backup_contact` varchar(50) DEFAULT NULL COMMENT '备用联系人',
  `backup_contact_title` varchar(50) DEFAULT NULL COMMENT '备用联系人职务',
  `backup_contact_phone` varchar(50) DEFAULT NULL COMMENT '备用联系人手机',
  `backup_contact_email` varchar(100) DEFAULT NULL COMMENT '备用联系人邮箱',
  -- 信用评价
  `credit_level` varchar(20) DEFAULT NULL COMMENT '信用等级（字典 credit_level）',
  `credit_limit` varchar(50) DEFAULT NULL COMMENT '授信额度',
  `credit_term` varchar(20) DEFAULT NULL COMMENT '信用期限',
  `cooperation_years` varchar(20) DEFAULT NULL COMMENT '合作年限',
  `cooperation_comment` text COMMENT '历史合作评价',
  -- 历史交易统计（配置值；交易记录明细由合同数据动态提供）
  `first_coop_date` varchar(50) DEFAULT NULL COMMENT '首次合作日期',
  `last_trade_date` varchar(50) DEFAULT NULL COMMENT '最近交易日期',
  `total_amount` varchar(50) DEFAULT NULL COMMENT '累计交易额',
  `total_orders` varchar(50) DEFAULT NULL COMMENT '累计订单数',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户/合作方默认信息表（单行 id=1）';

INSERT IGNORE INTO `settings_company_partner` (`id`,`create_time`,`update_time`) VALUES (1,NOW(),NOW());

-- ========== 三、数据字典 9 个 ==========
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('经营状态','company_business_status','公司信息-经营状态',150,1,NOW(),NOW()),
('公司类型','company_type','公司信息-公司类型',151,1,NOW(),NOW()),
('纳税人类型','vat_type','公司信息-增值税纳税人类型',152,1,NOW(),NOW()),
('增值税税率','vat_rate','公司信息-增值税税率',153,1,NOW(),NOW()),
('发票类型','invoice_type','公司信息-发票类型',154,1,NOW(),NOW()),
('信用等级','credit_level','公司信息-信用等级',155,1,NOW(),NOW()),
('账户类型','account_type','公司信息-账户类型',156,1,NOW(),NOW()),
('付款方式','payment_method','公司信息-付款方式',157,1,NOW(),NOW()),
('交货方式','delivery_method','公司信息-交货方式',158,1,NOW(),NOW());

-- 经营状态（值 1-5）
SET @d := (SELECT id FROM dictionary_types WHERE code='company_business_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'在营','1',1,'success',1,NOW(),NOW()),(@d,'注销','2',2,'info',1,NOW(),NOW()),(@d,'吊销','3',3,'danger',1,NOW(),NOW()),(@d,'迁出','4',4,'warning',1,NOW(),NOW()),(@d,'停业','5',5,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 公司类型
SET @d := (SELECT id FROM dictionary_types WHERE code='company_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'有限责任公司','limited',1,'',1,NOW(),NOW()),(@d,'股份有限公司','stock',2,'',1,NOW(),NOW()),(@d,'合伙企业','partnership',3,'',1,NOW(),NOW()),(@d,'个人独资企业','sole',4,'',1,NOW(),NOW()),(@d,'国有控股','state_owned',5,'',1,NOW(),NOW()),(@d,'外商投资','foreign',6,'',1,NOW(),NOW()),(@d,'其他','other',7,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 纳税人类型
SET @d := (SELECT id FROM dictionary_types WHERE code='vat_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'一般纳税人','general',1,'',1,NOW(),NOW()),(@d,'小规模纳税人','small',2,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 增值税税率
SET @d := (SELECT id FROM dictionary_types WHERE code='vat_rate' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'13%','13',1,'',1,NOW(),NOW()),(@d,'9%','9',2,'',1,NOW(),NOW()),(@d,'6%','6',3,'',1,NOW(),NOW()),(@d,'3%','3',4,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 发票类型
SET @d := (SELECT id FROM dictionary_types WHERE code='invoice_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'增值税专用发票','special',1,'',1,NOW(),NOW()),(@d,'增值税普通发票','normal',2,'',1,NOW(),NOW()),(@d,'电子发票','electronic',3,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 信用等级
SET @d := (SELECT id FROM dictionary_types WHERE code='credit_level' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'AAA','AAA',1,'success',1,NOW(),NOW()),(@d,'AA+','AA+',2,'success',1,NOW(),NOW()),(@d,'AA','AA',3,'primary',1,NOW(),NOW()),(@d,'AA-','AA-',4,'primary',1,NOW(),NOW()),(@d,'A+','A+',5,'warning',1,NOW(),NOW()),(@d,'A','A',6,'warning',1,NOW(),NOW()),(@d,'B','B',7,'danger',1,NOW(),NOW()),(@d,'C','C',8,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 账户类型
SET @d := (SELECT id FROM dictionary_types WHERE code='account_type' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'基本存款账户','basic',1,'',1,NOW(),NOW()),(@d,'一般存款账户','general',2,'',1,NOW(),NOW()),(@d,'专用存款账户','special',3,'',1,NOW(),NOW()),(@d,'临时存款账户','temporary',4,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 付款方式
SET @d := (SELECT id FROM dictionary_types WHERE code='payment_method' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'银行转账','bank_transfer',1,'',1,NOW(),NOW()),(@d,'银行承兑汇票','bank_acceptance',2,'',1,NOW(),NOW()),(@d,'商业承兑汇票','commercial_acceptance',3,'',1,NOW(),NOW()),(@d,'现金','cash',4,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 交货方式
SET @d := (SELECT id FROM dictionary_types WHERE code='delivery_method' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@d,'送货上门','delivery',1,'',1,NOW(),NOW()),(@d,'自提','pickup',2,'',1,NOW(),NOW()),(@d,'物流配送','logistics',3,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 四、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('公司信息','settings:company',1,0,'settings','/settings/company','el-icon-office-building',NULL,47,1,1,'公司信息-查看/编辑（菜单）',NOW(),NOW()),
('公司信息发布','settings:company:publish',2,0,'settings',NULL,NULL,NULL,48,1,1,'公司信息-发布上线',NOW(),NOW()),
('公司信息同步','settings:company:sync',2,0,'settings',NULL,NULL,NULL,49,1,1,'公司信息-渠道同步',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('settings:company','settings:company:publish','settings:company:sync');

-- ========== 五、菜单（系统设置 → 公司信息） ==========
SET @sys_settings_id = (SELECT id FROM menus WHERE name='系统设置' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @sys_settings_id, '公司信息', '/settings/company', 'el-icon-office-building', 'settings:company', 45, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:company' AND deleted_at IS NULL AND type=2);
