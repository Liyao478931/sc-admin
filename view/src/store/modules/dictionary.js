/**
 * 数据字典 Vuex 模块
 * 缓存字典数据，减少 API 请求
 */
import { getDictByCode, getDictBatch } from '@/api/dictionary'

export default {
  namespaced: true,
  state: {
    /** 字典缓存 { code: items[] } */
    dictCache: {},
    loaded: false,
  },
  mutations: {
    SET_DICT(state, { code, items }) {
      state.dictCache = { ...state.dictCache, [code]: items }
      state.loaded = true
    },
    SET_DICT_BATCH(state, dicts) {
      state.dictCache = { ...state.dictCache, ...dicts }
      state.loaded = true
    },
    CLEAR_DICT(state, code) {
      if (code) {
        const newCache = { ...state.dictCache }
        delete newCache[code]
        state.dictCache = newCache
      } else {
        state.dictCache = {}
        state.loaded = false
      }
    },
  },
  actions: {
    /** 获取单个字典数据（优先缓存） */
    async getDictionary({ state, commit }, code) {
      if (state.dictCache[code]) return state.dictCache[code]
      try {
        const r = await getDictByCode(code)
        const items = r.data || []
        commit('SET_DICT', { code, items })
        return items
      } catch (e) {
        return []
      }
    },
    /** 批量获取字典数据 */
    async getDictionaryBatch({ state, commit }, codes) {
      const needFetch = codes.filter(c => !state.dictCache[c])
      if (needFetch.length === 0) {
        const result = {}
        codes.forEach(c => { result[c] = state.dictCache[c] || [] })
        return result
      }
      try {
        const r = await getDictBatch(needFetch)
        if (r.code === 0 && r.data) {
          commit('SET_DICT_BATCH', r.data)
        }
      } catch (e) {}
      const result = {}
      codes.forEach(c => { result[c] = state.dictCache[c] || [] })
      return result
    },
  },
}
