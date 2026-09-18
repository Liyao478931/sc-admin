<!--
  文件：admin/src/views/business/customer/index.vue
  功能：经营管理 → 客户管理 → 客户列表
    - 统计卡片（客户总数/A级/活跃/本月新增）
    - 多维筛选（关键词/类型/等级/行业/状态/区域）
    - 工具栏（新增/导入/导出/合并/刷新）
    - 表格（编码/名称/简称/类型/行业/联系人/电话/等级/状态/操作）
    - 弹窗：新增编辑 / 详情 / 导入 / 合并
-->
<template>
  <div class="customer-page">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">客户总数</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num gold">{{ stats.level_a || 0 }}</div><div class="stat-label">A级客户</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.active || 0 }}</div><div class="stat-label">活跃客户</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.month_new || 0 }}</div><div class="stat-label">本月新增</div></el-card></el-col>
    </el-row>

    <!-- ===== 筛选区 ===== -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="filter.keyword" placeholder="名称/编码/联系人" clearable style="width:180px" @keyup.enter.native="search" />
        </el-form-item>
        <el-form-item label="客户类型">
          <el-select v-model="filter.customer_type" placeholder="全部" clearable style="width:130px">
            <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="客户等级">
          <el-select v-model="filter.customer_level" placeholder="全部" clearable style="width:110px">
            <el-option v-for="opt in levelOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="行业">
          <el-select v-model="filter.industry" placeholder="全部" clearable style="width:110px">
            <el-option v-for="opt in industryOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:100px">
            <el-option label="启用" value="1" /><el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="区域">
          <el-select v-model="filter.region" placeholder="全部" clearable style="width:110px">
            <el-option v-for="(v, k) in regionMap" :key="k" :label="v" :value="k" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- ===== 工具栏 + 表格 ===== -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-if="hasPerm('business:customer:add')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增客户</el-button>
        <el-button v-if="hasPerm('business:customer:add')" size="small" icon="el-icon-upload2" @click="importVisible = true">导入客户</el-button>
        <el-button v-if="hasPerm('business:customer:export')" size="small" icon="el-icon-download" @click="handleExport">导出客户</el-button>
        <el-button v-if="hasPerm('business:customer:edit')" size="small" icon="el-icon-connection" @click="openMerge">客户合并</el-button>
        <span class="flex-1"></span>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column prop="customer_code" label="客户编码" width="150" show-overflow-tooltip />
        <el-table-column prop="customer_name" label="客户名称" min-width="180" show-overflow-tooltip />
        <el-table-column prop="customer_short_name" label="客户简称" width="110" show-overflow-tooltip />
        <el-table-column prop="customer_type_text" label="客户类型" width="100" />
        <el-table-column prop="industry_text" label="所属行业" width="90" />
        <el-table-column prop="contact_person" label="联系人" width="90" />
        <el-table-column prop="contact_phone" label="联系电话" width="120" />
        <el-table-column label="客户等级" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="levelTag(s.row.customer_level)">{{ s.row.customer_level_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
            <el-button v-if="hasPerm('business:customer:edit')" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
            <el-button v-if="hasPerm('business:customer:edit')" type="text" size="mini" @click="toggleStatus(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('business:customer:delete')" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- ===== 弹窗 ===== -->
    <CustomerFormDialog :visible="formVisible" :row="currentRow" @update:visible="v => (formVisible = v)" @success="onFormSuccess" />
    <CustomerDetailDialog :visible="detailVisible" :customer-id="detailId" @update:visible="v => (detailVisible = v)" />
    <CustomerImportDialog :visible="importVisible" @update:visible="v => (importVisible = v)" />

    <!-- 客户合并弹窗 -->
    <el-dialog title="客户合并" :visible="mergeVisible" width="460px" :close-on-click-modal="false" @close="mergeVisible = false">
      <el-form label-width="110px" size="small">
        <el-form-item label="主客户（保留）">
          <el-select v-model="mergeForm.master_id" filterable style="width:100%" placeholder="选择要保留的客户">
            <el-option v-for="c in allOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="被合并客户">
          <el-select v-model="mergeForm.slave_id" filterable style="width:100%" placeholder="选择要合并掉的客户">
            <el-option v-for="c in allOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="mergeVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="merging" @click="handleMerge">确认合并</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import CustomerFormDialog from './components/CustomerFormDialog.vue'
import CustomerDetailDialog from './components/CustomerDetailDialog.vue'
import CustomerImportDialog from './components/CustomerImportDialog.vue'
import { isCarouselMode } from '@/utils/kioskMode'
import {
  getCustomerList, getCustomerStatistics, getCustomerOptions, getCustomerDetail,
  deleteCustomer, updateCustomerStatus, exportCustomer, mergeCustomer
} from '../../../api/businessCustomer'

export default {
  name: 'BusinessCustomer',
  components: { CustomerFormDialog, CustomerDetailDialog, CustomerImportDialog },
  data() {
    return {
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      stats: {},
      filter: { keyword: '', customer_type: '', customer_level: '', industry: '', status: '', region: '' },
      typeOptions: [], industryOptions: [], levelOptions: [],
      regionMap: { north: '华北', east: '华东', south: '华南', central: '华中', southwest: '西南', northwest: '西北', northeast: '东北', other: '其他' },
      // 弹窗
      formVisible: false, currentRow: null,
      detailVisible: false, detailId: 0,
      importVisible: false,
      mergeVisible: false, mergeForm: { master_id: null, slave_id: null }, merging: false, allOptions: []
    }
  },
  created() {
    this.loadList()
    this.loadStats()
    this.loadDictOptions()
    // 从"新增客户"菜单（/business/customer/create）进入时自动打开新增弹窗
    // 大屏轮播/展示模式（无人工操作、定时自动切换）下禁止自动打开写弹窗，避免误写数据
    if (this.$route.path === '/business/customer/create' && !isCarouselMode()) {
      this.formVisible = true
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadDictOptions() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const t = await getDictByCode('customer_type'); this.typeOptions = t.data || [] } catch (e) { this.typeOptions = [] }
      try { const i = await getDictByCode('customer_industry'); this.industryOptions = i.data || [] } catch (e) { this.industryOptions = [] }
      try { const l = await getDictByCode('customer_level'); this.levelOptions = l.data || [] } catch (e) { this.levelOptions = [] }
    },
    levelTag(lv) { return { A: 'warning', B: 'primary', C: 'success', D: 'info' }[lv] || 'info' },
    search() { this.page = 1; this.loadList() },
    reset() {
      this.filter = { keyword: '', customer_type: '', customer_level: '', industry: '', status: '', region: '' }
      this.page = 1
      this.loadList()
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getCustomerList({ ...this.filter, page: this.page, limit: this.pageSize })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try {
        const r = await getCustomerStatistics()
        if (r.code === 0) this.stats = r.data || {}
      } catch (e) {}
    },
    // 新增/编辑
    openForm(row) { this.currentRow = row || null; this.formVisible = true },
    onFormSuccess() { this.formVisible = false; this.loadList(); this.loadStats() },
    // 详情
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    // 删除
    handleDelete(row) {
      this.$confirm(`确定删除客户「${row.customer_name}」？有业务关联的客户不可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteCustomer(row.id)
          if (r.code === 0) { this.$message.success('客户已删除'); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    // 切换状态
    async toggleStatus(row) {
      try {
        const r = await updateCustomerStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success(r.msg); this.loadList() }
      } catch (e) {}
    },
    // 导出
    async handleExport() {
      try {
        const res = await exportCustomer(this.filter)
        const blob = res.data
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'customers_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    // 合并
    async openMerge() {
      this.mergeVisible = true
      try {
        const r = await getCustomerOptions()
        this.allOptions = r.data || []
      } catch (e) { this.allOptions = [] }
    },
    async handleMerge() {
      if (!this.mergeForm.master_id || !this.mergeForm.slave_id) { this.$message.warning('请选择主客户与被合并客户'); return }
      if (this.mergeForm.master_id === this.mergeForm.slave_id) { this.$message.warning('主客户与被合并客户不能相同'); return }
      this.$confirm('确认将被合并客户的业务关联转移到主客户并删除？此操作不可撤销。', '合并确认', { type: 'warning' }).then(async () => {
        this.merging = true
        try {
          const r = await mergeCustomer(this.mergeForm)
          if (r.code === 0) { this.$message.success(r.msg); this.mergeVisible = false; this.mergeForm = { master_id: null, slave_id: null }; this.loadList(); this.loadStats() }
        } catch (e) {}
        this.merging = false
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.customer-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; }
.stat-num.gold { color: #e6a23c; }
.stat-num.green { color: #67c23a; }
.stat-num.blue { color: #409eff; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.filter-card { margin-bottom: 14px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 12px; text-align: right; }
.danger { color: #f56c6c; }
</style>
