-- 177_create_order_flow.sql
-- 统一审批接入：订单评审（order）流程定义
-- 幂等写法，可重复执行
-- 回滚 down：DELETE FROM approval_flow WHERE biz_type='order';

INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`module_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('order', '订单评审', '经营管理', 1, 48, '[{"node_name":"经理评审","approver_type":"role","approver_value":"manager","approver_name":"经理","timeout_hours":48,"timeout_action":"remind"}]', 1, '订单评审审批', NOW(), NOW());
