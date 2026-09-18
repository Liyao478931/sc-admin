-- 176_create_biztypes.sql
-- 统一审批接入扩展：9 个业务类型流程定义（仓储6/报价/事故调查/BOM）
-- 幂等写法，可重复执行
-- 回滚 down：DELETE FROM approval_flow WHERE biz_type IN ('warehouse_device_receipt','warehouse_product_in','warehouse_product_out','warehouse_return','warehouse_scrap','warehouse_pick','quotation','safety_accident_investigate','product_bom');

INSERT IGNORE INTO `approval_flow` (`biz_type`,`biz_name`,`module_name`,`approval_mode`,`timeout_hours`,`node_config`,`status`,`remark`,`created_at`,`updated_at`) VALUES
('warehouse_device_receipt',   '设备接收',   '仓储管理', 1, 24, '[{"node_name":"仓管审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管","timeout_hours":24,"timeout_action":"remind"}]', 1, '设备接收审批', NOW(), NOW()),
('warehouse_product_in',       '产品入库',   '仓储管理', 1, 24, '[{"node_name":"仓管审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管","timeout_hours":24,"timeout_action":"remind"}]', 1, '产品入库审批', NOW(), NOW()),
('warehouse_product_out',      '产品出库',   '仓储管理', 1, 24, '[{"node_name":"仓管审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管","timeout_hours":24,"timeout_action":"remind"}]', 1, '产品出库审批', NOW(), NOW()),
('warehouse_return',           '退货/退库',  '仓储管理', 1, 24, '[{"node_name":"仓管审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管","timeout_hours":24,"timeout_action":"remind"}]', 1, '退货退库审批', NOW(), NOW()),
('warehouse_scrap',            '报废处理',   '仓储管理', 1, 24, '[{"node_name":"仓管审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管","timeout_hours":24,"timeout_action":"remind"}]', 1, '报废处理审批', NOW(), NOW()),
('warehouse_pick',             '领料申请',   '仓储管理', 1, 24, '[{"node_name":"仓管审批","approver_type":"role","approver_value":"warehouse_manager","approver_name":"仓管","timeout_hours":24,"timeout_action":"remind"}]', 1, '领料申请审批', NOW(), NOW()),
('quotation',                  '报价审批',   '经营管理', 1, 48, '[{"node_name":"经理审批","approver_type":"role","approver_value":"manager","approver_name":"经理","timeout_hours":48,"timeout_action":"remind"}]', 1, '报价审批', NOW(), NOW()),
('safety_accident_investigate','事故调查',   '安全管理', 1, 48, '[{"node_name":"安全主管审批","approver_type":"role","approver_value":"safety_manager","approver_name":"安全主管","timeout_hours":48,"timeout_action":"remind"}]', 1, '事故调查审批', NOW(), NOW()),
('product_bom',                'BOM审批',    '生产管理', 1, 24, '[{"node_name":"技术主管审批","approver_type":"role","approver_value":"tech_manager","approver_name":"技术主管","timeout_hours":24,"timeout_action":"remind"}]', 1, 'BOM 审批', NOW(), NOW());
