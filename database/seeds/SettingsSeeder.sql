-- 系统参数种子
INSERT IGNORE INTO system_params (param_key, param_value, name, param_group, param_type, description, sort, status, created_at) VALUES
('banner_max_count_per_group','10','单组最大轮播图数量','banner','number','限制单个轮播组最多添加的轮播图数量，0为不限制',1,1,NOW()),
('banner_batch_upload_max','20','批量上传最大数量','banner','number','单次批量上传最多可选择图片数量',2,1,NOW()),
('banner_schedule_interval','5','定时任务检查间隔','banner','number','定时发布/下架检查间隔（分钟）',3,1,NOW()),
('banner_auto_publish_enabled','1','定时发布功能启用','banner','switch','是否启用定时发布/下架功能',4,1,NOW()),
('splash_max_duration','10','启动页最大显示时长','splash','number','启动页显示时长的上限（秒）',1,1,NOW()),
('splash_min_duration','1','启动页最小显示时长','splash','number','启动页显示时长的下限（秒）',2,1,NOW()),
('splash_image_max_size','2','启动页图片最大大小','splash','number','单位 MB',3,1,NOW()),
('splash_video_max_size','10','启动页视频最大大小','splash','number','单位 MB',4,1,NOW()),
('splash_default_duration','3','启动页默认显示时长','splash','number','默认值（秒）',5,1,NOW());
