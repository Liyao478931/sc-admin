ALTER TABLE drive_files ADD COLUMN view_scope VARCHAR(10) DEFAULT 'all' COMMENT 'all/dept/users/owner' AFTER uploader_id, ADD COLUMN view_dept_ids VARCHAR(500) DEFAULT '' COMMENT '可见部门ID' AFTER view_scope, ADD COLUMN view_user_ids VARCHAR(1000) DEFAULT '' COMMENT '可见用户ID' AFTER view_dept_ids;

