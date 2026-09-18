/**
 * AI 助手状态模块（v1.63.0 页面上下文感知）
 * 维护：页面上下文配置 / 数据概要 / 筛选条件 / 当前实体
 */
import { getPageContext } from '@/config/aiContextMap'

const state = {
  /** 页面上下文配置 { route, pageTitle, module, dataSource, entityType, suggestedQuestions, quickActions } */
  pageContext: null,
  /** 数据概要 { total, time_range, top_item }（业务页面通过 mixin 上报） */
  dataSummary: null,
  /** 当前筛选条件 { key: value } */
  filters: {},
  /** 当前实体 { type, id, name }（详情页） */
  entity: null
}

const mutations = {
  SET_PAGE_CONTEXT (state, ctx) { state.pageContext = ctx },
  SET_DATA_SUMMARY (state, s) { state.dataSummary = s || null },
  SET_FILTERS (state, f) { state.filters = f || {} },
  SET_ENTITY (state, e) { state.entity = e || null },
  CLEAR_PAGE_CONTEXT (state) {
    state.pageContext = null
    state.dataSummary = null
    state.filters = {}
    state.entity = null
  }
}

const actions = {
  /** 路由切换后更新页面上下文（router.afterEach 调用） */
  updatePageContext ({ commit, state }, { route } = {}) {
    const cfg = getPageContext(route)
    if (!cfg) {
      // 不在映射中的页面：保留用户已上报的数据概要（仍可对话），但清空页面配置
      if (state.pageContext) commit('SET_PAGE_CONTEXT', null)
      return
    }
    commit('SET_PAGE_CONTEXT', cfg)
  },
  setDataSummary ({ commit }, s) { commit('SET_DATA_SUMMARY', s) },
  setFilters ({ commit }, f) { commit('SET_FILTERS', f) },
  setEntity ({ commit }, e) { commit('SET_ENTITY', e) },
  clearPageContext ({ commit }) { commit('CLEAR_PAGE_CONTEXT') }
}

export default {
  namespaced: true,
  state,
  mutations,
  actions
}
