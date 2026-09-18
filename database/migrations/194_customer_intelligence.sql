-- 194_customer_intelligence.sql
-- v1.66.0 客户智能分析（RFM 价值分析 + 流失预警）：4 表 + 5 预置策略 + 3 权限 + 菜单

CREATE TABLE IF NOT EXISTS `customer_rfm_scores` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `analysis_period` varchar(20) NOT NULL DEFAULT '' COMMENT '分析周期（YYYY-MM）',
  `r_value` int(11) DEFAULT NULL COMMENT 'R值（距上次购买天数）',
  `f_value` int(11) DEFAULT NULL COMMENT 'F值（购买次数）',
  `m_value` decimal(15,2) DEFAULT NULL COMMENT 'M值（累计消费金额）',
  `r_score` tinyint(1) DEFAULT NULL COMMENT 'R评分（0低/1高）',
  `f_score` tinyint(1) DEFAULT NULL COMMENT 'F评分（0低/1高）',
  `m_score` tinyint(1) DEFAULT NULL COMMENT 'M评分（0低/1高）',
  `customer_type` varchar(20) DEFAULT NULL COMMENT '客户类型（重要价值/重要发展/重要挽留/一般价值/重要保持/一般保持/流失客户）',
  `total_score` int(11) DEFAULT NULL COMMENT '综合评分（0-100）',
  `rank` int(11) DEFAULT NULL COMMENT '排名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_period` (`analysis_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户RFM评分表';

CREATE TABLE IF NOT EXISTS `customer_churn_risks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(200) DEFAULT '' COMMENT '客户名称（冗余）',
  `risk_score` int(11) NOT NULL DEFAULT 0 COMMENT '风险评分（0-100）',
  `risk_level` varchar(10) NOT NULL DEFAULT 'low' COMMENT 'low/medium/high',
  `churn_reason` text COMMENT '流失原因（AI生成）',
  `days_since_last_order` int(11) DEFAULT NULL COMMENT '距上次购买天数',
  `frequency_decline` decimal(5,2) DEFAULT NULL COMMENT '近3月频次下降率（%）',
  `amount_decline` decimal(5,2) DEFAULT NULL COMMENT '近3月金额下降率（%）',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=待处理 1=处理中 2=已挽回 3=已流失',
  `detected_at` datetime NOT NULL COMMENT '检测时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_risk_level` (`risk_level`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户流失风险表';

CREATE TABLE IF NOT EXISTS `customer_churn_strategies` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `strategy_name` varchar(50) NOT NULL DEFAULT '' COMMENT '策略名称',
  `strategy_code` varchar(30) NOT NULL DEFAULT '' COMMENT '策略编码',
  `description` text COMMENT '策略描述',
  `applicable_scenario` varchar(50) DEFAULT NULL COMMENT '适用场景',
  `execution_type` varchar(20) DEFAULT NULL COMMENT '执行方式：visit/coupon/recommend/survey/care',
  `expected_success_rate` decimal(5,2) DEFAULT NULL COMMENT '预计成功率（%）',
  `estimated_cost` varchar(50) DEFAULT NULL COMMENT '预计成本',
  `is_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否默认',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=禁用 1=启用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='挽回策略模板表';

CREATE TABLE IF NOT EXISTS `customer_churn_actions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL DEFAULT 0 COMMENT '客户ID',
  `customer_name` varchar(200) DEFAULT '' COMMENT '客户名称（冗余）',
  `strategy_id` int(11) DEFAULT NULL COMMENT '策略ID',
  `strategy_name` varchar(50) DEFAULT '' COMMENT '策略名称（冗余）',
  `risk_id` int(11) DEFAULT NULL COMMENT '关联风险记录ID',
  `action_content` text COMMENT '执行内容',
  `executor` varchar(50) DEFAULT NULL COMMENT '执行人',
  `execute_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=待执行 1=执行中 2=已完成 3=失败',
  `customer_response` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=未响应 1=已查看 2=已回复 3=已转化',
  `result` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=进行中 1=成功 2=失败',
  `recovery_amount` decimal(15,2) DEFAULT NULL COMMENT '挽回金额',
  `recovery_days` int(11) DEFAULT NULL COMMENT '挽回周期（天）',
  `executed_at` datetime DEFAULT NULL COMMENT '执行时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_result` (`result`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='挽回执行记录表';

-- 预置挽回策略模板
INSERT INTO `customer_churn_strategies` (`strategy_name`, `strategy_code`, `description`, `applicable_scenario`, `execution_type`, `expected_success_rate`, `estimated_cost`, `is_default`, `status`) VALUES
('客户经理回访', 'manager_visit', '安排专属客户经理上门拜访，了解客户需求和满意度', '高价值客户流失风险', 'visit', 65.00, '2人天', 1, 1),
('专属优惠唤醒', 'coupon_wake', '发送专属优惠券，有效期30天', '中低价值客户价格敏感型', 'coupon', 45.00, '预估让利1-2万', 0, 1),
('产品推荐唤醒', 'product_recommend', '基于历史偏好推荐新产品或服务', '历史频次高近期无互动', 'recommend', 50.00, '无', 0, 1),
('满意度调查', 'satisfaction_survey', '发送满意度调查问卷，了解客户不满原因', '原因不明型流失', 'survey', 30.00, '无', 0, 1),
('节日关怀', 'holiday_care', '发送节日问候和专属祝福', '所有类型', 'care', 20.00, '无', 0, 1);

-- 权限（platform=1 为 admin）
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('查看客户价值分析', 'ai:customer:value:view', 2, 0, 'ai', '', '', '', 0, 1, 1, '客户价值分析页面与客户画像', NOW(), NOW()),
('查看流失预警', 'ai:customer:churn:view', 2, 0, 'ai', '', '', '', 0, 1, 1, '客户流失预警页面', NOW(), NOW()),
('执行挽回策略', 'ai:customer:churn:action', 2, 0, 'ai', '', '', '', 0, 1, 1, '执行挽回策略按钮', NOW(), NOW());

-- 菜单：AI智能平台下新增「客户智能」
SET @ai_top := (SELECT id FROM `menus` WHERE `permission` = 'ai:platform:view' LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@ai_top, '客户智能', '', 'el-icon-user', 'ai:customer:value:view', 14, 1, 1, 0);
SET @ci_dir := LAST_INSERT_ID();
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@ci_dir, '客户价值分析', '/ai/customer/value', '', 'ai:customer:value:view', 1, 1, 2, 0),
(@ci_dir, '流失预警', '/ai/customer/churn', '', 'ai:customer:churn:view', 2, 1, 2, 0);

-- 角色绑定
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code IN ('super_admin', 'admin') AND p.code IN ('ai:customer:value:view', 'ai:customer:churn:view', 'ai:customer:churn:action');
