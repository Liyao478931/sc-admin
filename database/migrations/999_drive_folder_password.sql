ALTER TABLE drive_files ADD COLUMN folder_password VARCHAR(100) DEFAULT NULL COMMENT '文件夹密码hash' AFTER mime, ADD COLUMN uploader_id INT UNSIGNED DEFAULT 0 COMMENT '上传人用户ID' AFTER uploader;

