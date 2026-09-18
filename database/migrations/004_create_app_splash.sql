-- 启动页配置表
-- Migration: 2026_07_27_000004_create_app_splash_table
CREATE TABLE IF NOT EXISTS `app_splash_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1图片 2视频 3图片+视频',
  `image` varchar(255) NOT NULL DEFAULT '' COMMENT '图片URL',
  `video` varchar(255) NOT NULL DEFAULT '' COMMENT '视频URL',
  `background_color` varchar(20) NOT NULL DEFAULT '#ffffff' COMMENT '背景色',
  `duration` int(11) NOT NULL DEFAULT 3 COMMENT '显示时长(秒)',
  `skip_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否可跳过',
  `skip_style` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1文字 2图标 3无',
  `skip_text` varchar(10) NOT NULL DEFAULT '跳过' COMMENT '跳过按钮文字',
  `skip_color` varchar(20) NOT NULL DEFAULT '#ffffff' COMMENT '跳过按钮颜色',
  `skip_position` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1右下角 2右上角 3底部居中',
  `show_text` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否显示文字',
  `text_content` text COMMENT '文字内容',
  `text_color` varchar(20) NOT NULL DEFAULT '#ffffff' COMMENT '文字颜色',
  `text_position` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1居中 2底部 3顶部',
  `text_size` int(11) NOT NULL DEFAULT 24 COMMENT '文字大小(px)',
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='启动页配置';
