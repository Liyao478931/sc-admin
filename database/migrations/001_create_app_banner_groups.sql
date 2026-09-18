-- 轮播组表
-- Migration: 2026_07_27_000001_create_app_banner_groups_table
CREATE TABLE IF NOT EXISTS `app_banner_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '组名称',
  `code` varchar(50) NOT NULL DEFAULT '' COMMENT '组编码',
  `position` varchar(50) NOT NULL DEFAULT '' COMMENT '位置标识',
  `style` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1全屏 2卡片 3沉浸式',
  `indicator_style` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1圆点 2数字 3缩略图 4无',
  `animation` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1滑动 2淡入淡出 3缩放 4翻转',
  `autoplay_interval` int(11) NOT NULL DEFAULT 3 COMMENT '自动轮播间隔(秒)',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='轮播组';
