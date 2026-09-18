-- 字典数据种子
-- 注意：先确保 dictionary_types 有对应类型，再插入 dictionary_entries

-- banner_style（轮播样式）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('banner_style','轮播样式',1,NOW());
SET @bs = (SELECT id FROM dictionary_types WHERE code='banner_style');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@bs,'全屏轮播',1,1,1,NOW()),(@bs,'卡片轮播',2,2,1,NOW()),(@bs,'沉浸式轮播',3,3,1,NOW());

-- indicator_style（指示器样式）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('indicator_style','指示器样式',1,NOW());
SET @is = (SELECT id FROM dictionary_types WHERE code='indicator_style');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@is,'圆点',1,1,1,NOW()),(@is,'数字',2,2,1,NOW()),(@is,'缩略图',3,3,1,NOW()),(@is,'无',4,4,1,NOW());

-- animation_style（切换动画）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('animation_style','切换动画',1,NOW());
SET @as = (SELECT id FROM dictionary_types WHERE code='animation_style');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@as,'滑动',1,1,1,NOW()),(@as,'淡入淡出',2,2,1,NOW()),(@as,'缩放',3,3,1,NOW()),(@as,'翻转',4,4,1,NOW());

-- banner_position（轮播位置）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('banner_position','轮播位置',1,NOW());
SET @bp = (SELECT id FROM dictionary_types WHERE code='banner_position');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@bp,'首页顶部','home_top',1,1,NOW()),(@bp,'首页中部','home_mid',2,1,NOW()),(@bp,'活动页顶部','activity_top',3,1,NOW());

-- link_type（链接类型）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('link_type','链接类型',1,NOW());
SET @lt = (SELECT id FROM dictionary_types WHERE code='link_type');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@lt,'内链',1,1,1,NOW()),(@lt,'外链',2,2,1,NOW()),(@lt,'商品',3,3,1,NOW()),(@lt,'活动',4,4,1,NOW()),(@lt,'文章',5,5,1,NOW());

-- platform_type（平台定向）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('platform_type','平台定向',1,NOW());
SET @pt = (SELECT id FROM dictionary_types WHERE code='platform_type');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@pt,'全部',0,1,1,NOW()),(@pt,'小程序',1,2,1,NOW()),(@pt,'H5',2,3,1,NOW()),(@pt,'公众号',3,4,1,NOW());

-- banner_status（轮播状态）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('banner_status','轮播状态',1,NOW());
SET @bss = (SELECT id FROM dictionary_types WHERE code='banner_status');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@bss,'启用',1,1,1,NOW()),(@bss,'禁用',0,2,1,NOW());

-- splash_type（启动页类型）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('splash_type','启动页类型',1,NOW());
SET @st = (SELECT id FROM dictionary_types WHERE code='splash_type');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@st,'图片',1,1,1,NOW()),(@st,'视频',2,2,1,NOW()),(@st,'图片+视频',3,3,1,NOW());

-- skip_style（跳过按钮样式）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('skip_style','跳过按钮样式',1,NOW());
SET @ss = (SELECT id FROM dictionary_types WHERE code='skip_style');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@ss,'文字',1,1,1,NOW()),(@ss,'图标',2,2,1,NOW()),(@ss,'无',3,3,1,NOW());

-- text_position（文字位置）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('text_position','文字位置',1,NOW());
SET @tp = (SELECT id FROM dictionary_types WHERE code='text_position');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@tp,'居中',1,1,1,NOW()),(@tp,'底部',2,2,1,NOW()),(@tp,'顶部',3,3,1,NOW());

-- skip_position（跳过按钮位置）
INSERT IGNORE INTO dictionary_types (code, name, status, created_at) VALUES ('skip_position','跳过按钮位置',1,NOW());
SET @sp = (SELECT id FROM dictionary_types WHERE code='skip_position');
INSERT IGNORE INTO dictionary_entries (type_id,label,value,sort,status,created_at) VALUES
(@sp,'右下角',1,1,1,NOW()),(@sp,'右上角',2,2,1,NOW()),(@sp,'底部居中',3,3,1,NOW());
