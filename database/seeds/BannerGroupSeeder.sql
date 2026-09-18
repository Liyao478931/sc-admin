-- 预置首页轮播组数据
INSERT IGNORE INTO `app_banner_groups` (`name`, `code`, `position`, `style`, `indicator_style`, `animation`, `autoplay_interval`, `status`, `created_at`, `updated_at`)
VALUES ('首页轮播', 'home', 'home_top', 1, 1, 1, 3, 1, NOW(), NOW());
