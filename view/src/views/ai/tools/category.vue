<template>
  <div class="ai-tool-category-page">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="6"><el-card shadow="never" class="stat-card" @click.native="quickFilter('')">
        <div class="stat-head"><i class="el-icon-s-grid stat-icon blue"></i><span>分类总数</span></div>
        <div class="stat-num">{{ stats.total || 0 }}</div>
      </el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card" @click.native="quickFilter('enabled')">
        <div class="stat-head"><i class="el-icon-check stat-icon green"></i><span>已启用</span></div>
        <div class="stat-num">{{ stats.enabled || 0 }}</div>
      </el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card" @click.native="quickFilter('system')">
        <div class="stat-head"><i class="el-icon-star-on stat-icon gold"></i><span>系统预置</span></div>
        <div class="stat-num">{{ stats.system || 0 }}</div>
      </el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card" @click.native="quickFilter('custom')">
        <div class="stat-head"><i class="el-icon-edit-outline stat-icon purple"></i><span>自定义</span></div>
        <div class="stat-num">{{ stats.custom || 0 }}</div>
      </el-card></el-col>
    </el-row>

    <!-- ===== 筛选区域 ===== -->
    <el-form :inline="true" size="small" class="filter-form">
      <el-form-item>
        <el-input v-model="filter.keyword" placeholder="请输入分类名称" clearable style="width: 200px;" @keyup.enter.native="p => { page = 1; loadList() }" @clear="p => { page = 1; loadList() }" />
      </el-form-item>
      <el-form-item>
        <el-select v-model="filter.status" placeholder="全部状态" clearable style="width: 130px;" @change="p => { page = 1; loadList() }">
          <el-option label="启用" :value="1" />
          <el-option label="停用" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-select v-model="filter.is_system" placeholder="全部类型" clearable style="width: 130px;" @change="p => { page = 1; loadList() }">
          <el-option label="系统预置" :value="1" />
          <el-option label="自定义" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" @click="p => { page = 1; loadList() }">搜索</el-button>
        <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- ===== 工具栏 ===== -->
    <div class="tool-bar">
      <span class="tool-tip">共 {{ total }} 个分类</span>
      <span class="flex-1"></span>
      <el-button type="primary" size="small" icon="el-icon-plus" @click="$refs.formDialog.open()">新增分类</el-button>
      <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
    </div>

    <!-- ===== 表格（拖拽排序） ===== -->
    <el-table :data="list" size="small" stripe v-loading="loading" row-key="id">
      <el-table-column type="index" label="序号" width="60" align="center" />
      <el-table-column prop="category_key" label="分类标识" width="120" />
      <el-table-column prop="category_name" label="分类名称" min-width="120" />
      <el-table-column label="图标" width="80" align="center">
        <template slot-scope="s">
          <i v-if="s.row.icon && s.row.icon.startsWith('el-icon')" :class="s.row.icon" class="cat-icon"></i>
          <span v-else>{{ s.row.icon || '--' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="工具数量" width="100" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$refs.toolsDialog.open(s.row.category_key, s.row.category_name)">{{ s.row.tool_count || 0 }}</el-button>
        </template>
      </el-table-column>
      <el-table-column prop="sort" label="排序" width="100" align="center">
        <template slot-scope="s">
          <span class="drag-handle">{{ s.row.sort }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="系统预置" width="90" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="s.row.is_system === 1 ? 'warning' : 'info'">{{ s.row.is_system === 1 ? '是' : '否' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$refs.formDialog.open(s.row)">编辑</el-button>
          <el-button v-if="s.row.is_system !== 1" type="text" size="mini" class="danger" @click="removeCategory(s.row)">删除</el-button>
          <el-button type="text" size="mini" @click="toggleStatus(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" small background layout="total, sizes, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" :page-sizes="[10, 20, 50]" @current-change="p => { page = p; loadList() }" @size-change="s => { pageSize = s; page = 1; loadList() }" />

    <!-- 弹窗 -->
    <CategoryFormDialog ref="formDialog" @saved="loadAll" />
    <CategoryToolsDialog ref="toolsDialog" />
  </div>
</template>

<script>
import Sortable from 'sortablejs'
import {
  getToolCategories, deleteToolCategory, updateToolCategoryStatus,
  batchSortToolCategories, getToolCategoryStatistics
} from '../../../api/aiToolCategory'
import CategoryFormDialog from './components/CategoryFormDialog.vue'
import CategoryToolsDialog from './components/CategoryToolsDialog.vue'

export default {
  name: 'AiToolCategory',
  components: { CategoryFormDialog, CategoryToolsDialog },
  data() {
    return {
      loading: false,
      list: [], total: 0, page: 1, pageSize: 10,
      filter: { keyword: '', status: '', is_system: '' },
      stats: {},
      sortable: null
    }
  },
  created() {
    this.loadAll()
  },
  mounted() {
    this.$nextTick(() => this.initSortable())
  },
  beforeDestroy() {
    if (this.sortable) { this.sortable.destroy(); this.sortable = null }
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
        if (this.filter.status !== '') params.status = this.filter.status
        if (this.filter.is_system !== '') params.is_system = this.filter.is_system
        const res = await getToolCategories(params)
        this.list = res.data.list || []
        this.total = res.data.total || 0
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { this.stats = (await getToolCategoryStatistics()).data || {} } catch (e) {}
    },
    resetFilter() {
      this.filter = { keyword: '', status: '', is_system: '' }
      this.page = 1
      this.loadList()
    },
    quickFilter(type) {
      if (type === 'enabled') this.filter = { keyword: '', status: 1, is_system: '' }
      else if (type === 'system') this.filter = { keyword: '', status: '', is_system: 1 }
      else if (type === 'custom') this.filter = { keyword: '', status: '', is_system: 0 }
      else this.filter = { keyword: '', status: '', is_system: '' }
      this.page = 1
      this.loadList()
    },
    initSortable() {
      const tbody = this.$el.querySelector('.el-table__body-wrapper tbody')
      if (!tbody || this.sortable) return
      this.sortable = Sortable.create(tbody, {
        handle: '.drag-handle',
        animation: 150,
        onEnd: (evt) => this.saveSort(evt)
      })
    },
    async saveSort(evt) {
      // 依据 sortablejs 的 oldIndex/newIndex 重排 Vue 数组（不依赖 DOM data-id）
      if (!evt || typeof evt.oldIndex !== 'number' || typeof evt.newIndex !== 'number') return
      const list = [...this.list]
      const [moved] = list.splice(evt.oldIndex, 1)
      list.splice(evt.newIndex, 0, moved)
      this.list = list
      // 按新顺序更新 sort（10,20,30... 留间隔便于后续插入）
      const items = this.list.map((row, i) => ({ id: row.id, sort: (i + 1) * 10 }))
      try {
        await batchSortToolCategories(items)
        this.$message.success('排序已更新')
        this.loadList()
      } catch (e) {}
    },
    toggleStatus(row) {
      const newStatus = row.status === 1 ? 0 : 1
      updateToolCategoryStatus(row.id, newStatus).then(res => {
        this.$message.success(res.msg || '操作成功')
        this.loadAll()
      }).catch(() => {})
    },
    removeCategory(row) {
      this.$confirm(`确定要删除分类 [${row.category_name}] 吗？删除后不可恢复`, '提示', { type: 'warning' }).then(async () => {
        try {
          await deleteToolCategory(row.id)
          this.$message.success('删除成功')
          this.loadAll()
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.ai-tool-category-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; cursor: pointer; }
.stat-card:hover { border-color: #409eff; }
.stat-head { display: flex; align-items: center; justify-content: center; gap: 6px; color: #606266; font-size: 13px; }
.stat-icon { font-size: 18px; }
.stat-icon.blue { color: #409eff; }
.stat-icon.green { color: #67c23a; }
.stat-icon.gold { color: #e6a23c; }
.stat-icon.purple { color: #8e44ad; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; margin-top: 4px; }
.filter-form { margin-bottom: 10px; }
.tool-bar { display: flex; align-items: center; margin-bottom: 12px; }
.tool-tip { color: #909399; font-size: 13px; }
.flex-1 { flex: 1; }
.cat-icon { font-size: 16px; color: #409eff; }
.drag-handle { cursor: move; color: #409eff; }
.pager { margin-top: 10px; text-align: right; }
</style>
