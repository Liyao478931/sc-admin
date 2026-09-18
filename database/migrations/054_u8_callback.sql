-- =====================================================
-- 054_u8_callback.sql
-- U8主动回调模块：settings_u8_config 新增回调配置字段 + u8_callback_log 回调日志表
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、settings_u8_config 新增回调配置字段 ==========
ALTER TABLE `settings_u8_config`
  ADD COLUMN `callback_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'U8主动回调开关：0关闭 1开启' AFTER `sync_data_types`,
  ADD COLUMN `callback_secret` varchar(255) NOT NULL DEFAULT '' COMMENT 'U8回调签名密钥（加密存储）' AFTER `callback_enabled`;

-- ========== 二、U8回调日志表 ==========
CREATE TABLE IF NOT EXISTS `u8_callback_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tradeid` varchar(64) NOT NULL DEFAULT '' COMMENT 'U8交易流水号（幂等键）',
  `biz_type` varchar(30) NOT NULL DEFAULT '' COMMENT '单据类型：warehouse/inventory/purchase_in/product_in/sale_out/other_io',
  `biz_no` varchar(64) NOT NULL DEFAULT '' COMMENT '单据号',
  `errcode` int(11) NOT NULL DEFAULT 0 COMMENT 'U8处理结果码',
  `errmsg` varchar(255) NOT NULL DEFAULT '' COMMENT 'U8处理结果描述',
  `payload` text COMMENT '扩展数据(JSON)',
  `sign_result` tinyint(1) NOT NULL DEFAULT 1 COMMENT '签名校验结果：1通过 0失败',
  `process_status` varchar(20) NOT NULL DEFAULT 'processing' COMMENT '处理状态：processing/processed/type_not_supported/duplicated/sign_failed/failed',
  `handle_msg` varchar(255) NOT NULL DEFAULT '' COMMENT '处理结果描述',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '接收时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tradeid` (`tradeid`),
  KEY `idx_biz_type` (`biz_type`),
  KEY `idx_process_status` (`process_status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='U8主动回调日志';
