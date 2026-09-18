-- =====================================================
-- 055_u8_document.sql
-- U8单据状态台账：承接 U8 主动回调更新本地单据状态（业务闭环）
-- 幂等写法，可重复执行
-- =====================================================

CREATE TABLE IF NOT EXISTS `u8_document` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `biz_type` varchar(30) NOT NULL DEFAULT '' COMMENT '单据类型：warehouse/inventory/purchase_in/product_in/sale_out/other_io',
  `biz_no` varchar(64) NOT NULL DEFAULT '' COMMENT '本地单据号',
  `doc_status` varchar(20) NOT NULL DEFAULT 'submitted' COMMENT '单据状态：submitted已提交/approved已审核/rejected已驳回/unknown未知',
  `u8_errcode` int(11) NOT NULL DEFAULT 0 COMMENT 'U8处理结果码',
  `u8_errmsg` varchar(255) NOT NULL DEFAULT '' COMMENT 'U8处理结果描述',
  `u8_tradeid` varchar(64) NOT NULL DEFAULT '' COMMENT '最近回调交易流水号',
  `u8_callback_time` datetime DEFAULT NULL COMMENT '最近回调时间',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_biz` (`biz_type`, `biz_no`),
  KEY `idx_doc_status` (`doc_status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='U8单据状态台账';
