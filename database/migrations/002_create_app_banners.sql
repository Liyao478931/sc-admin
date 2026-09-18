-- 轮播图表
-- Migration: 2026_07_27_000002_create_app_banners_table
CREATE TABLE IF NOT EXISTS `app_banners` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL DEFAULT 0 COMMENT '轮播组ID',
  `title` varchar(100) NOT NULL DEFAULT '' COMMENT '标题',
  `image` varchar(255) NOT NULL DEFAULT '' COMMENT '图片URL',
  `link_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1内链 2外链 3商品 4活动 5文章',
  `link_url` varchar(255) NOT NULL DEFAULT '' COMMENT '跳转链接',
  `platform` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0全部 1小程序 2H5 3公众号',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序权重',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
  `publish_time` datetime DEFAULT NULL COMMENT '定时发布时间',
  `unpublish_time` datetime DEFAULT NULL COMMENT '定时下架时间',
  `view_count` int(11) NOT NULL DEFAULT 0 COMMENT '展示次数',
  `click_count` int(11) NOT NULL DEFAULT 0 COMMENT '点击次数',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='轮播图';
