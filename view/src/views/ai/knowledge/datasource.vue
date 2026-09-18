<template>
  <div class="ai-datasource-page">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-head"><i class="el-icon-connection stat-icon blue"></i><span>数据源总数</span></div><div class="stat-num">{{ stats.total_ds || 0 }}</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-head"><i class="el-icon-check stat-icon green"></i><span>已启用</span></div><div class="stat-num">{{ stats.enabled_ds || 0 }}</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-head"><i class="el-icon-warning stat-icon red"></i><span>异常</span></div><div class="stat-num">{{ stats.error_ds || 0 }}</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-head"><i class="el-icon-document stat-icon orange"></i><span>总同步记录</span></div><div class="stat-num">{{ stats.total_records || 0 }}</div></el-card></el-col>
    </el-row>

    <!-- ===== 筛选区域 ===== -->
    <el-form :inline="true" size="small" class="filter-form">
      <el-form-item>
        <el-input v-model="filter.keyword" placeholder="请输入数据源名称" clearable style="width: 200px;" @keyup.enter.native="p => { page = 1; loadList() }" @clear="p => { page = 1; loadList() }" />
      </el-form-item>
      <el-form-item>
        <el-select v-model="filter.ds_type" placeholder="全部类型" clearable style="width: 130px;" @change="p => { page = 1; loadList() }">
          <el-option v-for="(v, k) in typeMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-select v-model="filter.status" placeholder="全部状态" clearable style="width: 130px;" @change="p => { page = 1; loadList() }">
          <el-option label="已启用" :value="1" />
          <el-option label="已停用" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-select v-model="filter.kb_id" placeholder="全部知识库" clearable style="width: 160px;" @change="p => { page = 1; loadList() }">
          <el-option v-for="kb in kbList" :key="kb.kb_id" :label="kb.kb_name" :value="kb.kb_id" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" @click="p => { page = 1; loadList() }">搜索</el-button>
        <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- ===== 工具栏 ===== -->
    <div class="tool-bar">
      <span class="tool-tip">共 {{ total }} 个数据源</span>
      <span class="flex-1"></span>
      <el-button type="primary" size="small" icon="el-icon-plus" @click="$refs.formDialog.open()">新增数据源</el-button>
      <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
    </div>

    <!-- ===== 表格 ===== -->
    <el-table :data="list" size="small" stripe v-loading="loading">
      <el-table-column type="index" label="序号" width="60" align="center" />
      <el-table-column label="数据源名称" min-width="140">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$refs.detailDialog.open(s.row.id)">{{ s.row.ds_name }}</el-button>
        </template>
      </el-table-column>
      <el-table-column label="类型" width="100" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="typeTag(s.row.ds_type)">{{ s.row.ds_type_text }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="kb_name" label="关联知识库" min-width="140" show-overflow-tooltip />
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="同步状态" width="90" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="syncType(s.row.sync_status)">{{ s.row.sync_status_text }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="last_sync_time" label="最后同步时间" width="160">
        <template slot-scope="s">{{ s.row.last_sync_time || '--' }}</template>
      </el-table-column>
      <el-table-column prop="last_sync_count" label="同步记录数" width="100" align="center" />
      <el-table-column label="操作" width="280" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$refs.testDialog.open(s.row)">测试</el-button>
          <el-button type="text" size="mini" @click="$refs.previewDialog.open(s.row)">预览</el-button>
          <el-button type="text" size="mini" @click="doSync(s.row)">同步</el-button>
          <el-button type="text" size="mini" @click="$refs.formDialog.open(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 1" type="text" size="mini" @click="toggleStatus(s.row)">停用</el-button>
          <el-button v-else type="text" size="mini" @click="toggleStatus(s.row)">启用</el-button>
          <el-button type="text" size="mini" class="danger" @click="removeDs(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />

    <!-- 弹窗 -->
    <DatasourceFormDialog ref="formDialog" :kb-list="kbList" @saved="loadAll" />
    <DatasourceDetailDialog ref="detailDialog" />
    <DatasourcePreviewDialog ref="previewDialog" />
    <DatasourceTestDialog ref="testDialog" />
  </div>
</template>

<script>
import {
  getDatasources, deleteDatasource, updateDatasourceStatus, syncDatasource, getDatasourceStatistics
} from '../../../api/aiDatasource'
import { getAiKnowledgeList } from '../../../api/aiKnowledge'
import DatasourceFormDialog from './components/DatasourceFormDialog.vue'
import DatasourceDetailDialog from './components/DatasourceDetailDialog.vue'
import DatasourcePreviewDialog from './components/DatasourcePreviewDialog.vue'
import DatasourceTestDialog from './components/DatasourceTestDialog.vue'

export default {
  name: 'AiDatasource',
  components: { DatasourceFormDialog, DatasourceDetailDialog, DatasourcePreviewDialog, DatasourceTestDialog },
  data() {
    return {
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', ds_type: '', status: '', kb_id: '' },
      stats: {},
      kbList: [],
      typeMap: { database: '数据库', api: 'API', webpage: '网页', filesystem: '文件系统', message_queue: '消息队列', file: '文件' }
    }
  },
  created() {
    this.loadAll()
    this.loadKbList()
  },
  methods: {
    async loadAll() {
      await this.loadList()
      this.loadStats()
    },
    async loadList() {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.pageSize }
        if (this.filter.keyword) params.keyword = this.filter.keyword
        if (this.filter.ds_type) params.ds_type = this.filter.ds_type
        if (this.filter.status !== '') params.status = this.filter.status
        if (this.filter.kb_id) params.kb_id = this.filter.kb_id
        const res = await getDatasources(params)
        this.list = res.data.list || []
        this.total = res.data.total || 0
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { this.stats = (await getDatasourceStatistics()).data || {} } catch (e) {}
    },
    async loadKbList() {
      try {
        const res = await getAiKnowledgeList({ page: 1, limit: 100 })
        this.kbList = res.data.list || []
      } catch (e) {}
    },
    resetFilter() {
      this.filter = { keyword: '', ds_type: '', status: '', kb_id: '' }
      this.page = 1
      this.loadList()
    },
    toggleStatus(row) {
      const newStatus = row.status === 1 ? 0 : 1
      updateDatasourceStatus(row.id, newStatus).then(res => {
        this.$message.success(res.msg || '操作成功')
        this.loadAll()
      }).catch(() => {})
    },
    doSync(row) {
      this.$confirm(`确认立即同步数据源「${row.ds_name}」？`, '同步确认', { type: 'warning' }).then(async () => {
        try {
          const res = await syncDatasource(row.id)
          this.$message.success(res.msg || '同步完成')
          this.loadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    removeDs(row) {
      this.$confirm(`确定删除数据源「${row.ds_name}」？将同时删除同步历史，不可恢复`, '提示', { type: 'warning' }).then(async () => {
        try {
          await deleteDatasource(row.id)
          this.$message.success('删除成功')
          this.loadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    // ===== 辅助 =====
    typeTag(t) { return { database: 'primary', api: 'success', webpage: 'warning', filesystem: 'info', message_queue: 'danger', file: 'success' }[t] || 'info' },
    syncType(st) { return { idle: 'info', syncing: 'warning', success: 'success', failed: 'danger' }[st] || 'info' }
  }
}
</script>

<style scoped>
.ai-datasource-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-head { display: flex; align-items: center; justify-content: center; gap: 6px; color: #606266; font-size: 13px; }
.stat-icon { font-size: 18px; }
.stat-icon.blue { color: #409eff; }
.stat-icon.green { color: #67c23a; }
.stat-icon.red { color: #f56c6c; }
.stat-icon.orange { color: #e6a23c; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; margin-top: 4px; }
.filter-form { margin-bottom: 10px; }
.tool-bar { display: flex; align-items: center; margin-bottom: 12px; }
.tool-tip { color: #909399; font-size: 13px; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
</style>
