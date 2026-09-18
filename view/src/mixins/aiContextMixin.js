/**
 * AI 上下文混入（v1.63.0）
 * 供业务页面使用：上报数据概要 / 筛选条件 / 当前实体，供 AI 助手感知
 */
import { mapState } from 'vuex'

export default {
  computed: {
    ...mapState('ai', ['pageContext', 'dataSummary', 'filters', 'entity'])
  },
  methods: {
    /** 业务页面上报数据概要：{ total, timeRange, topItem } */
    reportAiContext ({ total, timeRange, topItem } = {}) {
      this.$store.commit('ai/SET_DATA_SUMMARY', {
        total: total !== undefined ? String(total) : '',
        time_range: timeRange || '',
        top_item: topItem || ''
      })
    },
    /** 上报当前筛选条件：{ key: value } */
    reportAiFilters (filters) {
      this.$store.commit('ai/SET_FILTERS', filters || {})
    },
    /** 上报当前实体（详情页）：{ type, id, name } */
    reportAiEntity (entity) {
      this.$store.commit('ai/SET_ENTITY', entity || null)
    },
    /** 清除上下文 */
    clearAiContext () {
      this.$store.dispatch('ai/clearPageContext')
    }
  }
}
