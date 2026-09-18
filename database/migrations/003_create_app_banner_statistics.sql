-- 轮播图统计表
-- Migration: 2026_07_27_000003_create_app_banner_statistics_table
CREATE TABLE IF NOT EXISTS `app_banner_statistics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `banner_id` int(11) NOT NULL DEFAULT 0 COMMENT '轮播图ID',
  `stat_date` date NOT NULL COMMENT '统计日期',
  `view_count` int(11) NOT NULL DEFAULT 0 COMMENT '日展示次数',
  `click_count` int(11) NOT NULL DEFAULT 0 COMMENT '日点击次数',
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_banner_date` (`banner_id`,`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='轮播图日统计';
