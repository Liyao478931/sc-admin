<template>
  <el-dialog title="检索历史" :visible.sync="visible" width="850px" append-to-body>
    <div class="filter-bar">
      <el-select v-model="filter.kb_id" placeholder="知识库筛选" clearable size="small" style="width: 160px;" @change="p => { page = 1; loadHistory() }">
        <el-option v-for="kb in kbList" :key="kb.kb_id" :label="kb.kb_name" :value="kb.kb_id" />
      </el-select>
      <el-select v-model="filter.search_mode" placeholder="检索模式" clearable size="small" style="width: 130px; margin-left: 8px;" @change="p => { page = 1; loadHistory() }">
        <el-option v-for="opt in modeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
      </el-select>
      <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" size="small" style="margin-left: 8px;" @change="p => { page = 1; loadHistory() }" />
      <span class="flex-1"></span>
      <el-button size="small" icon="el-icon-download" @click="doExport">导出</el-button>
      <el-button size="small" icon="el-icon-refresh" @click="loadHistory">刷新</el-button>
    </div>

    <el-table :data="list" size="small" stripe v-loading="loading">
      <el-table-column prop="query_text" label="查询内容" min-width="200" show-overflow-tooltip />
      <el-table-column label="检索模式" width="100">
        <template slot-scope="s">{{ s.row.mode_text }}</template>
      </el-table-column>
      <el-table-column prop="result_count" label="结果数" width="70" align="center" />
      <el-table-column prop="avg_score" label="平均得分" width="80" align="center" />
      <el-table-column prop="search_duration" label="耗时(ms)" width="80" align="center" />
      <el-table-column prop="create_time" label="时间" width="165" />
      <el-table-column label="操作" width="100" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="reload(s.row)">重新加载</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadHistory() }" />
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getSearchHistory, getSearchHistoryDetail, exportSearchHistory } from '../../../../api/aiSearchTest'
import { getAiKnowledgeList } from '../../../../api/aiKnowledge'

export default {
  name: 'SearchHistoryDialog',
  data() {
    return {
      modeOptions: [],
      visible: false,
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      filter: { kb_id: '', search_mode: '' }, dateRange: [],
      kbList: []
    }
  },
  created() { this.loadDicts() },
  methods: {
    // 检索模式从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('search_mode'); this.modeOptions = r.data || [] } catch (e) { this.modeOptions = [] }
    },
    async open() {
      this.visible = true
      this.loadHistory()
      if (!this.kbList.length) {
        try {
          const res = await getAiKnowledgeList({ page: 1, limit: 100 })
          this.kbList = res.data.list || []
        } catch (e) {}
      }
    },
    async loadHistory() {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.pageSize }
        if (this.filter.kb_id) params.kb_id = this.filter.kb_id
        if (this.filter.search_mode) params.search_mode = this.filter.search_mode
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const res = await getSearchHistory(params)
        this.list = res.data.list || []
        this.total = res.data.total || 0
      } catch (e) {}
      this.loading = false
    },
    async reload(row) {
      try {
        const res = await getSearchHistoryDetail(row.id)
        this.visible = false
        this.$emit('reload', res.data || {})
      } catch (e) {}
    },
    async doExport() {
      try {
        const params = {}
        if (this.filter.kb_id) params.kb_id = this.filter.kb_id
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const res = await exportSearchHistory(params)
        const blob = new Blob([res.data], { type: 'text/csv;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url; a.download = 'search_history.csv'; a.click()
        URL.revokeObjectURL(url)
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.filter-bar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
</style>
