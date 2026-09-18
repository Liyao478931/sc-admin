-- =====================================================
-- 067_seed_standard_tools.sql
-- AI 智能平台工具中心：标准工具配置初始化（根据实际 API 生成）
--   1. 工具分类字典（参考；ai_tools.category 为 varchar 字段承载分类，
--      ai_tool_categories 表在项目中不存在，以下为可选建表+字典，仅供扩展）
--   2. 21 个标准工具（真实 API 端点；幂等，ON DUPLICATE KEY UPDATE 按 tool_name 更新）
-- 说明：
--   - api_path 均为项目真实路由（已对照 app/api/route/app.php 与控制器参数核实）
--   - 仓储(17/18)与系统统计(19)无对应模块接口，置 status=0 预留
--   - 路径参数工具（detail/status-log）以 {param} 占位，执行时需将参数拼入 URL
-- =====================================================

-- ========== 一、工具分类字典（可选，表不存在时先建表） ==========
-- 项目当前以 ai_tools.category 字段（device/safety/hr/warehouse/common）承载分类，
-- 以下建表语句仅为标准化参考，如需使用请先执行建表，否则跳过本段。
CREATE TABLE IF NOT EXISTS `ai_tool_categories` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `category_key` varchar(30) NOT NULL DEFAULT '' COMMENT '分类键',
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '分类名称',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_key` (`category_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具分类字典';

INSERT INTO `ai_tool_categories` (`category_key`, `category_name`, `sort`, `status`) VALUES
('device', '设备工具', 1, 1),
('safety', '安全工具', 2, 1),
('hr', '人事工具', 3, 1),
('warehouse', '仓储工具', 4, 1),
('common', '通用工具', 5, 1)
ON DUPLICATE KEY UPDATE `category_name`=VALUES(`category_name`), `sort`=VALUES(`sort`), `status`=VALUES(`status`);

-- ========== 二、21 个标准工具 ==========
INSERT INTO `ai_tools`
  (`tool_name`, `tool_display_name`, `category`, `description`, `method`, `api_path`,
   `headers`, `params_schema`, `response_schema`, `requires_confirm`, `timeout`, `retry_count`, `call_count`, `status`, `sort`)
VALUES
-- ===== 一、设备管理（6） =====
('query_device', '查询设备信息', 'device',
 '根据设备编码或名称关键词查询设备信息（设备名称、编码、型号、部门、位置、状态等）',
 'GET', '/api/device/asset/list', NULL,
 '{"type":"object","properties":{"keyword":{"type":"string","title":"关键词","description":"设备编码或名称关键词"},"status":{"type":"string","title":"设备状态","description":"按状态筛选"},"department_id":{"type":"integer","title":"部门ID","description":"按部门筛选"}}}',
 NULL, 0, 30, 1, 0, 1, 1),

('list_devices', '查询设备列表', 'device',
 '分页查询设备列表，支持按名称/编码关键词、状态、所属部门、设备类型等条件筛选',
 'GET', '/api/device/asset/list', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词","description":"设备名称或编码关键词"},"status":{"type":"string","title":"设备状态"},"department_id":{"type":"integer","title":"部门ID"},"category_id":{"type":"integer","title":"设备分类ID"},"device_type":{"type":"string","title":"设备类型"}}}',
 NULL, 0, 30, 1, 0, 1, 2),

('query_device_status', '查询设备状态', 'device',
 '查询指定设备的运行状态与状态变更记录（需将 device_id 拼入 URL 路径）',
 'GET', '/api/device/asset/status-log/{device_id}', NULL,
 '{"type":"object","required":["device_id"],"properties":{"device_id":{"type":"integer","title":"设备ID","description":"设备ID（路径参数，需拼入 URL）"}}}',
 NULL, 0, 30, 1, 0, 1, 3),

('query_repair_orders', '查询维修工单', 'device',
 '查询维修工单列表，支持按关键词、状态、紧急程度、时间范围筛选',
 'GET', '/api/device/repair/order/list', NULL,
 '{"type":"object","properties":{"keyword":{"type":"string","title":"关键词","description":"设备名称/编码/工单号关键词"},"status":{"type":"string","title":"工单状态"},"emergency_level":{"type":"string","title":"紧急程度","enum":["normal","urgent","critical"]},"start_date":{"type":"string","title":"开始日期","description":"格式 YYYY-MM-DD"},"end_date":{"type":"string","title":"结束日期","description":"格式 YYYY-MM-DD"},"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20}}}',
 NULL, 0, 30, 1, 0, 1, 4),

('create_repair_order', '创建维修工单', 'device',
 '为故障设备创建维修工单，提交后进入维修流程（高风险写操作，需用户确认）',
 'POST', '/api/device/repair/order/add', NULL,
 '{"type":"object","required":["device_id","fault_description"],"properties":{"device_id":{"type":"integer","title":"设备ID","description":"目标设备ID"},"fault_description":{"type":"string","title":"故障描述","description":"故障现象描述，必填"},"fault_type":{"type":"string","title":"故障类型","description":"故障类型枚举：mechanical(机械)、electrical(电气)、hydraulic(液压)、pneumatic(气动)、software(软件)、other(其他)，必须使用英文枚举值","enum":["mechanical","electrical","hydraulic","pneumatic","software","other"]},"emergency_level":{"type":"string","title":"紧急程度","description":"紧急程度：normal(普通)、urgent(紧急)、critical(严重)，默认normal","enum":["normal","urgent","critical"],"default":"normal"},"reporter_id":{"type":"integer","title":"报修人ID","description":"可选，默认当前用户"},"remark":{"type":"string","title":"备注"}}}',
 NULL, 1, 30, 1, 0, 1, 5),

('query_maintenance_plans', '查询保养计划', 'device',
 '查询设备保养计划列表（计划名称、保养等级、执行周期、下次保养日期等）',
 'GET', '/api/device/maintenance/plan/list', NULL,
 '{"type":"object","properties":{"device_id":{"type":"integer","title":"设备ID"},"status":{"type":"string","title":"计划状态"},"keyword":{"type":"string","title":"关键词","description":"计划名称关键词"},"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20}}}',
 NULL, 0, 30, 1, 0, 1, 6),

-- ===== 二、安全管理（6） =====
('list_hazards', '查询隐患列表', 'safety',
 '分页查询隐患记录，支持按隐患类型、隐患等级、状态、发现时间范围筛选',
 'GET', '/api/safety/hazard/list', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词","description":"隐患名称关键词"},"hazard_type":{"type":"string","title":"隐患类型","enum":["equipment","environment","behavior","management","other"]},"hazard_level":{"type":"string","title":"隐患等级","enum":["minor","general","serious","emergency"]},"status":{"type":"string","title":"隐患状态"},"start_date":{"type":"string","title":"开始日期","description":"格式 YYYY-MM-DD"},"end_date":{"type":"string","title":"结束日期","description":"格式 YYYY-MM-DD"}}}',
 NULL, 0, 30, 1, 0, 1, 7),

('query_hazard_detail', '查询隐患详情', 'safety',
 '根据隐患ID查询隐患完整详情（描述、整改措施、验证记录等，需将 hazard_id 拼入 URL）',
 'GET', '/api/safety/hazard/detail/{hazard_id}', NULL,
 '{"type":"object","required":["hazard_id"],"properties":{"hazard_id":{"type":"integer","title":"隐患ID","description":"隐患ID（路径参数，需拼入 URL）"}}}',
 NULL, 0, 30, 1, 0, 1, 8),

('create_hazard', '创建隐患登记', 'safety',
 '登记新发现的隐患，进入隐患整改流程（高风险写操作，需用户确认）',
 'POST', '/api/safety/hazard/create', NULL,
 '{"type":"object","required":["hazard_name","hazard_desc"],"properties":{"hazard_name":{"type":"string","title":"隐患名称","description":"必填"},"hazard_desc":{"type":"string","title":"隐患描述","description":"必填"},"hazard_type":{"type":"string","title":"隐患类型","enum":["equipment","environment","behavior","management","other"],"default":"equipment"},"hazard_level":{"type":"string","title":"隐患等级","enum":["minor","general","serious","emergency"],"default":"general"},"location":{"type":"string","title":"发现位置"},"handler_id":{"type":"integer","title":"整改人ID","description":"可选，指定后自动通知整改人"}}}',
 NULL, 1, 30, 1, 0, 1, 9),

('list_inspection_tasks', '查询安全检查任务', 'safety',
 '查询安全检查任务列表，支持按检查类型、状态、执行人筛选',
 'GET', '/api/safety/inspection/task/list', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词"},"status":{"type":"string","title":"任务状态"},"executor_id":{"type":"integer","title":"执行人ID"},"inspection_type_id":{"type":"integer","title":"检查类型ID"},"start_date":{"type":"string","title":"开始日期"},"end_date":{"type":"string","title":"结束日期"}}}',
 NULL, 0, 30, 1, 0, 1, 10),

('list_trainings', '查询安全培训记录', 'safety',
 '查询安全培训记录列表，支持按关键词、状态、日期范围筛选',
 'GET', '/api/safety/training/record/list', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词","description":"培训主题/人员关键词"},"status":{"type":"string","title":"培训状态"},"start_date":{"type":"string","title":"开始日期","description":"格式 YYYY-MM-DD"},"end_date":{"type":"string","title":"结束日期","description":"格式 YYYY-MM-DD"}}}',
 NULL, 0, 30, 1, 0, 1, 11),

('list_accidents', '查询事故记录', 'safety',
 '查询事故记录列表，支持按事故类型、事故等级、状态、发生时间范围筛选',
 'GET', '/api/safety/accident/list', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词"},"accident_type":{"type":"string","title":"事故类型"},"accident_level":{"type":"string","title":"事故等级"},"status":{"type":"string","title":"事故状态"},"department_id":{"type":"integer","title":"部门ID"},"start_date":{"type":"string","title":"开始日期","description":"格式 YYYY-MM-DD"},"end_date":{"type":"string","title":"结束日期","description":"格式 YYYY-MM-DD"}}}',
 NULL, 0, 30, 1, 0, 1, 12),

-- ===== 三、人事管理（4） =====
('query_employee', '查询员工档案', 'hr',
 '按姓名/工号/关键词查询员工档案（基本信息、部门、岗位、职级等）',
 'GET', '/api/profiles', NULL,
 '{"type":"object","properties":{"keyword":{"type":"string","title":"关键词","description":"员工姓名或工号"},"employee_no":{"type":"string","title":"工号"},"department_id":{"type":"integer","title":"部门ID"}}}',
 NULL, 0, 30, 1, 0, 1, 13),

('list_employees', '查询员工列表', 'hr',
 '分页查询员工列表，支持按部门、岗位、状态等条件筛选',
 'GET', '/api/profiles', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词"},"department_id":{"type":"integer","title":"部门ID"},"position":{"type":"string","title":"岗位"},"status":{"type":"integer","title":"员工状态"}}}',
 NULL, 0, 30, 1, 0, 1, 14),

('query_attendance', '查询考勤记录', 'hr',
 '查询员工考勤记录，支持按日期范围、打卡结果筛选',
 'GET', '/api/hr/attendance/record/list', NULL,
 '{"type":"object","properties":{"keyword":{"type":"string","title":"关键词","description":"员工姓名关键词"},"department_id":{"type":"integer","title":"部门ID"},"start_date":{"type":"string","title":"开始日期","description":"格式 YYYY-MM-DD"},"end_date":{"type":"string","title":"结束日期","description":"格式 YYYY-MM-DD"},"check_result":{"type":"string","title":"打卡结果"},"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20}}}',
 NULL, 0, 30, 1, 0, 1, 15),

('list_approvals', '查询审批记录', 'hr',
 '查询审批记录列表，支持按关键词、状态、申请日期范围筛选',
 'GET', '/api/hr/attendance/approval/list', NULL,
 '{"type":"object","properties":{"page":{"type":"integer","title":"页码","default":1},"limit":{"type":"integer","title":"每页条数","default":20},"keyword":{"type":"string","title":"关键词","description":"申请人/审批事项关键词"},"status":{"type":"string","title":"审批状态"},"start_date":{"type":"string","title":"开始日期","description":"格式 YYYY-MM-DD"},"end_date":{"type":"string","title":"结束日期","description":"格式 YYYY-MM-DD"}}}',
 NULL, 0, 30, 1, 0, 1, 16),

-- ===== 四、仓储管理（预留，模块未接入） =====
('query_inventory', '查询库存', 'warehouse',
 '查询物料库存信息（库存数量、仓库位置、最低库存预警线）——仓储模块未接入，预留',
 'GET', '', NULL,
 '{"type":"object","properties":{"material_code":{"type":"string","title":"物料编码"},"material_name":{"type":"string","title":"物料名称"},"warehouse_id":{"type":"integer","title":"仓库ID"}}}',
 NULL, 0, 30, 1, 0, 1, 17),

('query_inventory_alerts', '查询库存预警', 'warehouse',
 '查询低于安全库存线的物料列表——仓储模块未接入，预留',
 'GET', '', NULL,
 '{"type":"object","properties":{"warehouse_id":{"type":"integer","title":"仓库ID"}}}',
 NULL, 0, 30, 1, 0, 1, 18),

-- ===== 五、通用工具（3） =====
('query_system_stats', '查询系统统计', 'common',
 '查询系统整体统计（员工/设备/隐患/事故总数）——暂无聚合概览接口，预留',
 'GET', '', NULL,
 '{"type":"object","properties":{}}',
 NULL, 0, 30, 1, 0, 1, 19),

('query_current_user', '查询当前用户信息', 'common',
 '获取当前登录用户的基本信息（姓名、部门、岗位、角色等）',
 'GET', '/api/profile', NULL,
 '{"type":"object","properties":{}}',
 NULL, 0, 30, 1, 0, 1, 20),

('send_notification', '发送通知', 'common',
 '向指定用户发送系统通知消息（高风险写操作，需用户确认）',
 'POST', '/api/notification/send', NULL,
 '{"type":"object","required":["target_ids","title","content"],"properties":{"target_type":{"type":"string","title":"接收类型","enum":["user","dept","all"],"default":"user"},"target_ids":{"type":"array","title":"接收人ID列表","items":{"type":"integer"},"description":"必填"},"msg_type":{"type":"integer","title":"消息类型","enum":[1,2,3,4,5,6],"description":"1系统公告 2任务指派 3审批通知 4预警提醒 5培训通知 6工单通知","default":1},"title":{"type":"string","title":"通知标题","description":"必填"},"content":{"type":"string","title":"通知内容","description":"必填"},"link_url":{"type":"string","title":"跳转链接","description":"可选"}}}',
 NULL, 1, 30, 1, 0, 1, 21)

ON DUPLICATE KEY UPDATE
  `tool_display_name`=VALUES(`tool_display_name`), `category`=VALUES(`category`),
  `description`=VALUES(`description`), `method`=VALUES(`method`), `api_path`=VALUES(`api_path`),
  `params_schema`=VALUES(`params_schema`), `requires_confirm`=VALUES(`requires_confirm`),
  `timeout`=VALUES(`timeout`), `status`=VALUES(`status`), `sort`=VALUES(`sort`), `update_time`=NOW();
