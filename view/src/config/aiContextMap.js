/**
 * AI 助手页面上下文映射配置（v1.63.0）
 * 权威配置：页面标题 / 推荐问题 / 快捷操作（后端快捷操作执行按 action 标识映射）
 * getPageContext(route)：精确匹配 → 前缀匹配（详情页带 ID）→ null
 */
const pageContextMap = {
  // ===== 销售统计 =====
  '/business/sales/statistics/customer': {
    pageTitle: '客户排行', module: 'sales', dataSource: 'customer_ranking',
    suggestedQuestions: [
      { id: 'top10', text: '本月TOP10客户是谁？', action: 'get_top_customers' },
      { id: 'rank_changes', text: '排名变化最大的客户有哪些？', action: 'get_rank_changes' },
      { id: 'churn_risks', text: '哪些客户有流失风险？', action: 'get_churn_risks' }
    ],
    quickActions: [
      { id: 'analyze_customers', label: '客户分析', type: 'primary', icon: 'el-icon-data-analysis', permission: 'ai:assistant:use' },
      { id: 'generate_customer_report', label: '生成报告', type: 'success', icon: 'el-icon-document', permission: 'ai:reports:generate' },
      { id: 'export_customer_data', label: '导出', type: 'default', icon: 'el-icon-download', permission: '' }
    ]
  },
  '/business/sales/statistics/product': {
    pageTitle: '产品排行', module: 'sales', dataSource: 'product_ranking',
    suggestedQuestions: [
      { id: 'top_products', text: '本月最畅销的产品是什么？', action: 'get_top_products' },
      { id: 'declining', text: '哪些产品销售额下降最多？', action: 'get_declining_products' },
      { id: 'category_dist', text: '各品类销售占比如何？', action: 'get_category_distribution' }
    ],
    quickActions: [
      { id: 'analyze_products', label: '产品分析', type: 'primary', icon: 'el-icon-data-analysis', permission: 'ai:assistant:use' },
      { id: 'generate_product_report', label: '生成报告', type: 'success', icon: 'el-icon-document', permission: 'ai:reports:generate' },
      { id: 'export_product_data', label: '导出', type: 'default', icon: 'el-icon-download', permission: '' }
    ]
  },
  '/business/sales/statistics/revenue': {
    pageTitle: '销售额分析', module: 'sales', dataSource: 'revenue_analysis',
    suggestedQuestions: [
      { id: 'trend', text: '本月销售趋势如何？', action: 'get_trend_analysis' },
      { id: 'growth', text: '同比增长和环比增长是多少？', action: 'get_growth_analysis' },
      { id: 'forecast', text: '下月销售预测是多少？', action: 'get_sales_forecast' }
    ],
    quickActions: [
      { id: 'analyze_trend', label: '趋势分析', type: 'primary', icon: 'el-icon-data-line', permission: 'ai:assistant:use' },
      { id: 'generate_monthly_brief', label: '月度简报', type: 'success', icon: 'el-icon-document', permission: 'ai:reports:generate' }
    ]
  },
  // ===== 详情页（前缀匹配）=====
  '/business/customer/detail': {
    pageTitle: '客户详情', module: 'sales', dataSource: 'customer_detail', entityType: 'customer',
    suggestedQuestions: [
      { id: 'purchase_history', text: '该客户的购买历史分析', action: 'analyze_purchase_history' },
      { id: 'churn', text: '该客户是否有流失风险？', action: 'check_churn_risk' },
      { id: 'recommend', text: '该客户适合推荐哪些产品？', action: 'recommend_products' }
    ],
    quickActions: [
      { id: 'analyze_customers', label: '客户画像分析', type: 'primary', icon: 'el-icon-user', permission: 'ai:assistant:use' }
    ]
  },
  '/business/order/detail': {
    pageTitle: '订单详情', module: 'sales', dataSource: 'order_detail', entityType: 'order',
    suggestedQuestions: [
      { id: 'anomaly', text: '该订单是否有异常？', action: 'check_order_anomaly' },
      { id: 'followup', text: '建议的跟进动作是什么？', action: 'get_followup_suggestions' }
    ],
    quickActions: [
      { id: 'analyze_trend', label: '订单异常检测', type: 'primary', icon: 'el-icon-warning', permission: 'ai:assistant:use' }
    ]
  },
  '/device/asset/detail': {
    pageTitle: '设备详情', module: 'device', dataSource: 'device_detail', entityType: 'device',
    suggestedQuestions: [
      { id: 'faults', text: '该设备的历史故障分析', action: 'analyze_device_faults' },
      { id: 'maintenance', text: '建议的保养计划是什么？', action: 'get_maintenance_suggestions' }
    ],
    quickActions: [
      { id: 'analyze_trend', label: '故障分析', type: 'primary', icon: 'el-icon-setting', permission: 'ai:assistant:use' },
      { id: 'generate_monthly_brief', label: '保养建议', type: 'success', icon: 'el-icon-first-aid-kit', permission: 'ai:reports:generate' }
    ]
  },
  '/device/repair/order/detail': {
    pageTitle: '维修工单详情', module: 'device', dataSource: 'repair_order_detail', entityType: 'repair_order',
    suggestedQuestions: [
      { id: 'solutions', text: '该故障的常见维修方案是什么？', action: 'get_repair_solutions' },
      { id: 'hours', text: '预估维修工时是多少？', action: 'estimate_repair_hours' }
    ],
    quickActions: [
      { id: 'analyze_products', label: '推荐维修方案', type: 'primary', icon: 'el-icon-s-tools', permission: 'ai:assistant:use' },
      { id: 'analyze_customers', label: '工时预估', type: 'success', icon: 'el-icon-time', permission: 'ai:assistant:use' }
    ]
  },
  '/safety/hazard/detail': {
    pageTitle: '隐患详情', module: 'safety', dataSource: 'hazard_detail', entityType: 'hazard',
    suggestedQuestions: [
      { id: 'risk', text: '该隐患的风险等级评估', action: 'assess_hazard_risk' },
      { id: 'rectify', text: '建议的整改方案是什么？', action: 'get_rectification_plan' }
    ],
    quickActions: [
      { id: 'analyze_products', label: '风险评估', type: 'primary', icon: 'el-icon-warning-outline', permission: 'ai:assistant:use' },
      { id: 'generate_product_report', label: '整改方案', type: 'success', icon: 'el-icon-s-check', permission: 'ai:reports:generate' }
    ]
  }
}

/** 根据路由获取页面上下文配置（精确 → 前缀） */
export function getPageContext (route) {
  if (!route) return null
  if (pageContextMap[route]) return { ...pageContextMap[route], route }
  for (const [key, cfg] of Object.entries(pageContextMap)) {
    if (route.startsWith(key)) return { ...cfg, route }
  }
  return null
}

export default pageContextMap
