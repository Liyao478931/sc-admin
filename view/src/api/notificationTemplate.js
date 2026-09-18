/**
 * 消息模板管理 API
 * 路由前缀：/notification/template
 */
import request from './request'

/** 模板列表（分页 + 筛选） */
export const getTemplateList = (p) => request({ url: '/notification/template/list', method: 'get', params: p })

/** 模板详情 */
export const getTemplateDetail = (id) => request({ url: '/notification/template/detail/' + id, method: 'get' })

/** 模板下拉选项（启用状态，供发送方调用） */
export const getTemplateOptions = () => request({ url: '/notification/template/options', method: 'get' })

/** 可用变量列表 */
export const getTemplateVariables = () => request({ url: '/notification/template/variables', method: 'get' })

/** 新增模板 */
export const addTemplate = (d) => request({ url: '/notification/template/add', method: 'post', data: d })

/** 编辑模板 */
export const editTemplate = (id, d) => request({ url: '/notification/template/edit/' + id, method: 'put', data: d })

/** 删除模板（软删除） */
export const deleteTemplate = (id) => request({ url: '/notification/template/delete/' + id, method: 'delete' })

/** 模板预览（变量值渲染） */
export const previewTemplate = (templateId, variableValues) => request({ url: '/notification/template/preview', method: 'post', data: { template_id: templateId, variable_values: variableValues } })
