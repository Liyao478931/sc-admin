<!--
  文件：admin/src/views/hr/assessment/template/components/IndicatorLibraryDialog.vue
  功能：从指标库选择指标弹窗（搜索/大类筛选/数据源筛选/多选批量引入）
-->
<template>
  <el-dialog title="从指标库添加" :visible.sync="visibleSync" width="720px" top="5vh" :close-on-click-modal="false">
    <div class="lib-filters">
      <el-input v-model="query.keyword" size="small" prefix-icon="el-icon-search" clearable placeholder="搜索指标名称" style="width:220px" @keyup.enter.native="load" @clear="load" />
      <el-select v-model="query.category" size="small" clearable placeholder="全部大类" style="width:150px" @change="load">
        <el-option v-for="c in LIB_CATEGORIES" :key="c" :label="c" :value="c" />
      </el-select>
      <el-select v-model="query.data_source" size="small" clearable placeholder="全部数据源" style="width:150px" @change="load">
        <el-option v-for="(t, v) in DATA_SOURCES" :key="v" :label="t" :value="v" />
      </el-select>
      <el-button size="small" icon="el-icon-refresh" @click="load">刷新</el-button>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe max-height="380" @selection-change="onSelectionChange" row-key="id">
      <el-table-column type="selection" width="45" align="center" reserve-selection />
      <el-table-column prop="name" label="指标名称" min-width="140" show-overflow-tooltip />
      <el-table-column prop="category" label="大类" width="110" align="center">
        <template slot-scope="s">{{ s.row.category || '-' }}</template>
      </el-table-column>
      <el-table-column label="数据源" width="100" align="center">
        <template slot-scope="s">{{ DATA_SOURCES[s.row.default_data_source] || '手动' }}</template>
      </el-table-column>
      <el-table-column prop="default_score" label="建议分值" width="80" align="center" />
      <el-table-column prop="usage_count" label="引用次数" width="80" align="center" />
      <el-table-column label="操作" width="80" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="showDetail(s.row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="lib-footer">
      <span class="lib-count">已选 <b>{{ selected.length }}</b> 个指标</span>
      <div>
        <el-button size="small" @click="visibleSync = false">取消</el-button>
        <el-button size="small" type="primary" :disabled="!selected.length" :loading="confirming" @click="doConfirm">确定添加（{{ selected.length }}）</el-button>
      </div>
    </div>

    <!-- 详情弹窗 -->
    <el-dialog title="指标详情" :visible.sync="detailVisible" width="520px" append-to-body>
      <el-descriptions :column="1" border size="small" v-if="detail">
        <el-descriptions-item label="指标名称">{{ detail.name }}</el-descriptions-item>
        <el-descriptions-item label="所属大类">{{ detail.category || '-' }}</el-descriptions-item>
        <el-descriptions-item label="建议分值">{{ detail.default_score }} 分</el-descriptions-item>
        <el-descriptions-item label="建议数据源">{{ DATA_SOURCES[detail.default_data_source] || '手动' }}</el-descriptions-item>
        <el-descriptions-item label="默认扣分规则">{{ ruleText(detail.default_deduct_rule) || '-' }}</el-descriptions-item>
        <el-descriptions-item label="引用次数">{{ detail.usage_count }} 个模板</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </el-dialog>
</template>

<script>
import { getLibraryList } from '@/api/assessment'

const LIB_CATEGORIES = ['履职情况', '公共量化指标', '安全', '纪律行为规范']
const DATA_SOURCES = {
  attendance: '考勤打卡', production: '生产工单', quality: '质检', maintenance: '设备保养',
  training: '培训管理', exam: '考试', safety: '安全检查', manual: '手动录入'
}

export default {
  name: 'AssessmentLibraryDialog',
  props: {
    visible: { type: Boolean, default: false }
  },
  data () {
    return {
      LIB_CATEGORIES, DATA_SOURCES,
      query: { keyword: '', category: '', data_source: '' },
      list: [], loading: false, selected: [], confirming: false,
      detailVisible: false, detail: null
    }
  },
  computed: {
    visibleSync: {
      get () { return this.visible },
      set (v) { if (!v) this.$emit('close') }
    }
  },
  watch: {
    visible (v) { if (v) { this.selected = []; this.query = { keyword: '', category: '', data_source: '' }; this.load() } }
  },
  methods: {
    async load () {
      this.loading = true
      try {
        const params = {}
        if (this.query.keyword) params.keyword = this.query.keyword
        if (this.query.category) params.category = this.query.category
        if (this.query.data_source) params.data_source = this.query.data_source
        const r = await getLibraryList(params)
        if (r.code === 0 && r.data) this.list = r.data.list || []
      } catch (e) {} finally { this.loading = false }
    },
    onSelectionChange (rows) {
      this.selected = rows
    },
    showDetail (row) {
      this.detail = row
      this.detailVisible = true
    },
    ruleText (json) {
      if (!json) return ''
      try {
        const r = JSON.parse(json)
        const rm = r.remark_template
        if (rm) return String(rm).replace(/\{\{count\}\}/g, '次数').replace(/\{\{deduct\}\}/g, '分值').replace(/\{\{score\}\}/g, '分数')
        const conds = r.conditions || []
        if (conds.length) return '按条件扣分（' + conds.length + ' 个条件）'
        return '按规则扣分'
      } catch (e) { return '' }
    },
    doConfirm () {
      this.confirming = true
      this.$emit('confirm', this.selected.map(x => x.id))
      setTimeout(() => { this.confirming = false }, 500)
    }
  }
}
</script>

<style scoped>
.lib-filters { display: flex; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
.lib-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 14px; }
.lib-count { font-size: 13px; color: #5a6f86; }
</style>
