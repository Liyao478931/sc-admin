/**
 * 文件：admin/src/views/ai/workflow/nodeTypes.js
 * 工作流节点类型定义（类型/名称/图标/颜色/分组/默认配置）
 */
export const NODE_TYPES = {
  start: { name: '开始', icon: 'el-icon-video-play', color: '#67C23A', group: '基础节点', desc: '工作流入口', defaultConfig: {} },
  end: { name: '结束', icon: 'el-icon-video-pause', color: '#F56C6C', group: '基础节点', desc: '工作流出口', defaultConfig: {} },
  llm: { name: 'LLM', icon: 'el-icon-cpu', color: '#409EFF', group: 'AI节点', desc: '调用大模型生成内容', defaultConfig: { model_id: '', system_prompt: '', user_prompt: '', temperature: 0.7, output_var: '' } },
  knowledge: { name: '知识库检索', icon: 'el-icon-collection', color: '#8E44AD', group: 'AI节点', desc: '检索知识库内容', defaultConfig: { kb_id: '', top_k: 3, threshold: 0.7, output_var: '' } },
  tool: { name: '工具调用', icon: 'el-icon-s-tools', color: '#E6A23C', group: '工具节点', desc: '调用已接入的工具API', defaultConfig: { tool_name: '', param_map: {}, output_var: '' } },
  condition: { name: '条件判断', icon: 'el-icon-s-operation', color: '#909399', group: '控制节点', desc: '条件分支判断', defaultConfig: { branches: [{ name: '是', condition: '' }, { name: '否', condition: '' }] } },
  loop: { name: '循环', icon: 'el-icon-refresh', color: '#409EFF', group: '控制节点', desc: '循环执行子流程', defaultConfig: { loop_type: 'count', count: 3, condition: '', list_var: '', max_iter: 100 } },
  code: { name: '代码执行', icon: 'el-icon-document', color: '#67C23A', group: '执行节点', desc: '执行自定义代码', defaultConfig: { language: 'python', code: '', inputs: {}, output_var: '' } },
  notification: { name: '通知', icon: 'el-icon-message', color: '#F56C6C', group: '执行节点', desc: '发送系统通知', defaultConfig: { channels: ['inbox'], receivers: [], title: '', content: '' } },
  human: { name: '人工确认', icon: 'el-icon-user', color: '#E6A23C', group: '交互节点', desc: '人工确认后继续', defaultConfig: { title: '', description: '', timeout: 60 } }
}

/** 节点分组（按顺序展示） */
export const NODE_GROUPS = ['基础节点', 'AI节点', '工具节点', '控制节点', '执行节点', '交互节点']

/** 获取节点类型元信息 */
export function getNodeType (type) {
  return NODE_TYPES[type] || { name: type || '未知', icon: 'el-icon-help', color: '#909399', desc: '' }
}

/** 生成节点唯一ID */
export function genNodeId (type) {
  return 'node_' + type + '_' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6)
}
