/**
 * Vuex 用户模块
 */
import { getToken, setToken, removeToken } from '../../utils/auth'
import { getUserInfo } from '../../api/auth'

export default {
  namespaced: true,
  state: {
    token: getToken() || '',
    userInfo: null,
    permissions: []
  },
  mutations: {
    SET_TOKEN(state, token) {
      state.token = token
      setToken(token)
    },
    SET_USER(state, user) {
      state.userInfo = user
    },
    SET_PERMISSIONS(state, perms) {
      state.permissions = perms
    },
    CLEAR_USER(state) {
      state.token = ''
      state.userInfo = null
      state.permissions = []
      removeToken()
    }
  },
  actions: {
    async getUserInfo({ commit, state }) {
      if (!state.token) return null
      try {
        const res = await getUserInfo()
        commit('SET_USER', res.data)
        return res.data
      } catch (e) {
        if (e.response?.status === 401) commit('CLEAR_USER')
        return null
      }
    },
    async loadPermissions({ commit, state }) {
      if (!state.token) return
      try {
        const { getLoginPermissions } = await import('../../api/auth')
        const res = await getLoginPermissions()
        if (res.data?.permissions) {
          commit('SET_PERMISSIONS', res.data.permissions)
        }
      } catch (e) { /* 权限加载失败不影响主流程 */ }
    },
    logout({ commit }) {
      commit('CLEAR_USER')
    }
  }
}
