import { getThemeConfig } from '@/api/theme'

export default {
  namespaced: true,
  state: { config: {}, loaded: false },
  mutations: {
    SET_CONFIG(state, config) { state.config = { ...config }; state.loaded = true },
    CLEAR_CONFIG(state) { state.config = {}; state.loaded = false },
  },
  actions: {
    async loadConfig({ commit }) {
      try { const r = await getThemeConfig(); if (r.code === 0 && r.data) commit('SET_CONFIG', r.data) }
      catch (e) { console.warn('[Theme] 加载主题配置失败', e) }
    },
  },
}
