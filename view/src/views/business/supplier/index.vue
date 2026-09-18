<!--
  文件：admin/src/views/business/supplier/index.vue
  功能：经营管理 → 供应商管理 → 供应商列表
    - 统计卡片（总数/A级/合作中/本月新增）
    - 多维筛选（关键词/类型/评级/品类/状态/区域）
    - 工具栏（新增/导入/导出/刷新）
    - 表格（编码/名称/简称/类型/品类/联系人/电话/评级/状态/操作）
    - 操作：详情/编辑/评级/状态/删除 + 弹窗（新增编辑/详情/导入）
-->
<template>
  <div class="supplier-page">
    <el-tabs v-model="activeTab" @tab-click="onTabClick">
    <!-- ===== 列表 Tab ===== -->
    <el-tab-pane label="供应商列表" name="list">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">供应商总数</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num gold">{{ stats.level_a || 0 }}</div><div class="stat-label">A级供应商</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.active || 0 }}</div><div class="stat-label">合作中</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.month_new || 0 }}</div><div class="stat-label">本月新增</div></el-card></el-col>
    </el-row>

    <!-- ===== 筛选区 ===== -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="filter.keyword" placeholder="名称/编码/联系人" clearable style="width:180px" @keyup.enter.native="search" />
        </el-form-item>
        <el-form-item label="供应商类型">
          <el-select v-model="filter.supplier_type" placeholder="全部" clearable style="width:130px">
            <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="供应商评级">
          <el-select v-model="filter.supplier_level" placeholder="全部" clearable style="width:110px">
            <el-option v-for="opt in levelOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="供应品类">
          <el-select v-model="filter.supply_category" placeholder="全部" clearable style="width:110px">
            <el-option v-for="opt in supplyOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
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
        <el-button v-if="hasPerm('business:supplier:add')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增供应商</el-button>
        <el-button v-if="hasPerm('business:supplier:add')" size="small" icon="el-icon-upload2" @click="importVisible = true">导入供应商</el-button>
        <el-button v-if="hasPerm('business:supplier:export')" size="small" icon="el-icon-download" @click="handleExport">导出供应商</el-button>
        <span class="flex-1"></span>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column prop="supplier_code" label="供应商编码" width="150" show-overflow-tooltip />
        <el-table-column prop="supplier_name" label="供应商名称" min-width="180" show-overflow-tooltip />
        <el-table-column prop="supplier_short_name" label="供应商简称" width="110" show-overflow-tooltip />
        <el-table-column prop="supplier_type_text" label="供应商类型" width="100" />
        <el-table-column prop="supply_category_text" label="供应品类" width="90" />
        <el-table-column prop="contact_person" label="联系人" width="90" />
        <el-table-column prop="contact_phone" label="联系电话" width="120" />
        <el-table-column label="供应商评级" width="90" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="levelTag(s.row.supplier_level)">{{ s.row.supplier_level_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
            <el-button v-if="hasPerm('business:supplier:edit')" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
            <el-dropdown v-if="hasPerm('business:supplier:edit')" size="mini" style="margin:0 4px" trigger="click" @command="lv => changeLevel(s.row, lv)">
              <el-button type="text" size="mini">评级<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-for="opt in levelOptions" :key="opt.value" :command="opt.value">{{ opt.label }}</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
            <el-button v-if="hasPerm('business:supplier:edit')" type="text" size="mini" @click="toggleStatus(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('business:supplier:delete')" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- ===== 弹窗 ===== -->
    <SupplierFormDialog :visible="formVisible" :row="currentRow" @update:visible="v => (formVisible = v)" @success="onFormSuccess" />
    <SupplierDetailDialog :visible="detailVisible" :supplier-id="detailId" @update:visible="v => (detailVisible = v)" />
    <SupplierImportDialog :visible="importVisible" @update:visible="v => (importVisible = v)" />

    <!-- QCD 考核弹窗 -->
    <el-dialog title="供应商QCD考核" :visible.sync="qcdDialog" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="供应商">
          <el-select v-model="qcdForm.supplier_id" filterable placeholder="选择供应商" style="width:100%">
            <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="考核月份"><el-date-picker v-model="qcdForm.assess_month" type="month" value-format="yyyy-MM" style="width:100%" /></el-form-item>
        <el-form-item label="Q质量分"><el-input-number v-model="qcdForm.q_score" :min="0" :max="100" :precision="1" style="width:100%" /></el-form-item>
        <el-form-item label="C成本分"><el-input-number v-model="qcdForm.c_score" :min="0" :max="100" :precision="1" style="width:100%" /></el-form-item>
        <el-form-item label="D交付分"><el-input-number v-model="qcdForm.d_score" :min="0" :max="100" :precision="1" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="qcdForm.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="qcdDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveQcd">保存考核</el-button>
      </template>
    </el-dialog>

    <!-- 加入黑名单弹窗 -->
    <el-dialog title="加入供应商黑名单" :visible.sync="blackDialog" width="460px">
      <el-form label-width="90px" size="small">
        <el-form-item label="供应商">
          <el-select v-model="blackForm.supplier_id" filterable placeholder="选择供应商" style="width:100%">
            <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="拉黑原因"><el-input v-model="blackForm.reason" type="textarea" :rows="3" placeholder="如：质量事故、供货延迟、商务违规" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="blackDialog = false">取消</el-button>
        <el-button size="small" type="danger" @click="addBlack">确认拉黑</el-button>
      </template>
    </el-dialog>
    </el-tab-pane>

    <!-- ===== QCD 考核 Tab ===== -->
    <el-tab-pane label="QCD考核" name="qcd">
      <div class="toolbar">
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openQcd()">新增考核</el-button>
        <el-select v-model="qcdFilter.supplier_id" size="small" clearable filterable placeholder="全部供应商" style="width:200px" @change="loadQcd">
          <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
        </el-select>
        <el-date-picker v-model="qcdFilter.month" type="month" value-format="yyyy-MM" size="small" placeholder="考核月份" style="width:130px" @change="loadQcd" />
        <el-button size="small" icon="el-icon-refresh" @click="loadQcd">刷新</el-button>
        <span class="toolbar-label">评分规则：Q质量40% + C成本30% + D交付30%，≥90 A / ≥75 B / ≥60 C / 其余 D</span>
      </div>
      <el-table :data="qcdList" v-loading="qcdLoading" size="small" border stripe>
        <el-table-column prop="supplier_name" label="供应商" width="180" show-overflow-tooltip />
        <el-table-column prop="assess_month" label="考核月份" width="100" />
        <el-table-column label="Q质量" width="90">
          <template slot-scope="{ row }">{{ Number(row.q_score).toFixed(1) }}</template>
        </el-table-column>
        <el-table-column label="C成本" width="90">
          <template slot-scope="{ row }">{{ Number(row.c_score).toFixed(1) }}</template>
        </el-table-column>
        <el-table-column label="D交付" width="90">
          <template slot-scope="{ row }">{{ Number(row.d_score).toFixed(1) }}</template>
        </el-table-column>
        <el-table-column label="总分" width="90">
          <template slot-scope="{ row }"><b>{{ Number(row.total_score).toFixed(1) }}</b></template>
        </el-table-column>
        <el-table-column label="评级" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="levelTag(row.grade)">{{ row.grade }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="assessor_name" label="评估人" width="100">
          <template slot-scope="{ row }">{{ row.assessor_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
        <el-table-column prop="created_at" label="考核时间" width="160" />
        <el-table-column label="操作" width="80" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('business:supplier:qcd:edit')" type="text" size="mini" style="color:#F56C6C" @click="delQcd(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-tab-pane>

    <!-- ===== 黑名单 Tab ===== -->
    <el-tab-pane label="黑名单" name="blacklist">
      <div class="toolbar">
        <el-button size="small" type="danger" icon="el-icon-plus" @click="openBlack()">加入黑名单</el-button>
        <el-input v-model="blackKeyword" size="small" placeholder="供应商名称" style="width:200px" clearable @keyup.enter="loadBlack" />
        <el-button size="small" icon="el-icon-refresh" @click="loadBlack">刷新</el-button>
      </div>
      <el-table :data="blackList" v-loading="blackLoading" size="small" border stripe>
        <el-table-column prop="supplier_name" label="供应商" width="200" show-overflow-tooltip />
        <el-table-column prop="reason" label="拉黑原因" min-width="200" show-overflow-tooltip />
        <el-table-column prop="operator_name" label="操作人" width="110">
          <template slot-scope="{ row }">{{ row.operator_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="created_at" label="拉黑时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('business:supplier:blacklist:edit')" type="text" size="mini" style="color:#F56C6C" @click="removeBlack(row)">移出</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script>
import request from '@/api/request'
import SupplierFormDialog from './components/SupplierFormDialog.vue'
import SupplierDetailDialog from './components/SupplierDetailDialog.vue'
import SupplierImportDialog from './components/SupplierImportDialog.vue'
import { isCarouselMode } from '@/utils/kioskMode'
import {
  getSupplierList, getSupplierStatistics, deleteSupplier,
  updateSupplierStatus, updateSupplierLevel, exportSupplier
} from '../../../api/businessSupplier'

export default {
  name: 'BusinessSupplier',
  components: { SupplierFormDialog, SupplierDetailDialog, SupplierImportDialog },
  data() {
    return {
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      stats: {},
      filter: { keyword: '', supplier_type: '', supplier_level: '', supply_category: '', status: '', region: '' },
      typeOptions: [], supplyOptions: [], levelOptions: [],
      regionMap: { north: '华北', east: '华东', south: '华南', central: '华中', southwest: '西南', northwest: '西北', northeast: '东北', other: '其他' },
      formVisible: false, currentRow: null,
      detailVisible: false, detailId: 0,
      importVisible: false,
      // QCD 考核
      activeTab: 'list',
      qcdLoading: false,
      qcdList: [],
      qcdFilter: { supplier_id: '', month: '' },
      qcdDialog: false,
      qcdForm: { id: 0, supplier_id: '', assess_month: '', q_score: 0, c_score: 0, d_score: 0, remark: '' },
      supplierOptions: [],
      // 黑名单
      blackLoading: false,
      blackList: [],
      blackKeyword: '',
      blackDialog: false,
      blackForm: { supplier_id: '', reason: '' }
    }
  },
  created() {
    const q = this.$route.query.tab
    if (q === 'qcd' || q === 'blacklist') this.activeTab = q
    this.loadList()
    this.loadStats()
    this.loadDictOptions()
    this.loadSupplierOptions()
    // 从"新增供应商"菜单（/business/supplier/create）进入时自动打开新增弹窗
    // 大屏轮播/展示模式下禁止自动打开新增供应商写弹窗
    if (this.$route.path === '/business/supplier/create' && !isCarouselMode()) {
      this.formVisible = true
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
  async loadDictOptions() {
    const { getDictByCode } = await import('../../../api/dictionary')
    try { const t = await getDictByCode('supplier_type'); this.typeOptions = t.data || [] } catch (e) { this.typeOptions = [] }
    try { const s = await getDictByCode('supplier_supply_category'); this.supplyOptions = s.data || [] } catch (e) { this.supplyOptions = [] }
    try { const l = await getDictByCode('supplier_level'); this.levelOptions = l.data || [] } catch (e) { this.levelOptions = [] }
  },
    levelTag(lv) { return { A: 'warning', B: 'primary', C: 'success', D: 'info' }[lv] || 'info' },
    onTabClick(tab) {
      if (tab.name === 'qcd') this.loadQcd()
      if (tab.name === 'blacklist') this.loadBlack()
    },
    async loadSupplierOptions() {
      try {
        const r = await request({ url: '/supplier/options', method: 'get' })
        if (r.code === 0) this.supplierOptions = r.data || []
      } catch (e) {}
    },
    // ============ QCD 考核 ============
    async loadQcd() {
      this.qcdLoading = true
      try {
        const params = {}
        if (this.qcdFilter.supplier_id) params.supplier_id = this.qcdFilter.supplier_id
        if (this.qcdFilter.month) params.month = this.qcdFilter.month
        const r = await request({ url: '/supplier/qcd-list', method: 'get', params })
        if (r.code === 0) this.qcdList = r.data.list || []
      } catch (e) {} finally { this.qcdLoading = false }
    },
    openQcd() {
      const now = new Date()
      const month = now.getFullYear() + '-' + ('0' + (now.getMonth() + 1)).slice(-2)
      this.qcdForm = { id: 0, supplier_id: '', assess_month: month, q_score: 0, c_score: 0, d_score: 0, remark: '' }
      this.qcdDialog = true
    },
    async saveQcd() {
      if (!this.qcdForm.supplier_id) { this.$message.warning('请选择供应商'); return }
      if (!this.qcdForm.assess_month) { this.$message.warning('请选择考核月份'); return }
      const r = await request({ url: '/supplier/qcd-save', method: 'post', data: this.qcdForm })
      if (r.code === 0) { this.$message.success(r.msg); this.qcdDialog = false; this.loadQcd(); this.loadList(); this.loadStats() }
    },
    async delQcd(row) {
      await this.$confirm(`确认删除该条考核记录？`, '提示', { type: 'warning' })
      const r = await request({ url: '/supplier/qcd-delete/' + row.id, method: 'delete' })
      if (r.code === 0) { this.$message.success('已删除'); this.loadQcd() }
    },
    // ============ 黑名单 ============
    async loadBlack() {
      this.blackLoading = true
      try {
        const params = {}
        if (this.blackKeyword) params.keyword = this.blackKeyword
        const r = await request({ url: '/supplier/blacklist-list', method: 'get', params })
        if (r.code === 0) this.blackList = r.data.list || []
      } catch (e) {} finally { this.blackLoading = false }
    },
    openBlack() {
      this.blackForm = { supplier_id: '', reason: '' }
      this.blackDialog = true
    },
    async addBlack() {
      if (!this.blackForm.supplier_id) { this.$message.warning('请选择供应商'); return }
      if (!this.blackForm.reason) { this.$message.warning('请填写拉黑原因'); return }
      const r = await request({ url: '/supplier/blacklist-add', method: 'post', data: this.blackForm })
      if (r.code === 0) { this.$message.success(r.msg); this.blackDialog = false; this.loadBlack() }
    },
    async removeBlack(row) {
      await this.$confirm(`确认将「${row.supplier_name}」移出黑名单？`, '提示', { type: 'warning' })
      const r = await request({ url: '/supplier/blacklist-remove/' + row.id, method: 'delete' })
      if (r.code === 0) { this.$message.success('已移出黑名单'); this.loadBlack() }
    },
    search() { this.page = 1; this.loadList() },
    reset() {
      this.filter = { keyword: '', supplier_type: '', supplier_level: '', supply_category: '', status: '', region: '' }
      this.page = 1
      this.loadList()
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getSupplierList({ ...this.filter, page: this.page, limit: this.pageSize })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try {
        const r = await getSupplierStatistics()
        if (r.code === 0) this.stats = r.data || {}
      } catch (e) {}
    },
    openForm(row) { this.currentRow = row || null; this.formVisible = true },
    onFormSuccess() { this.formVisible = false; this.loadList(); this.loadStats() },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    handleDelete(row) {
      this.$confirm(`确定删除供应商「${row.supplier_name}」？有业务关联的供应商不可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSupplier(row.id)
          if (r.code === 0) { this.$message.success('供应商已删除'); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    async toggleStatus(row) {
      try {
        const r = await updateSupplierStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success(r.msg); this.loadList() }
      } catch (e) {}
    },
    async changeLevel(row, level) {
      try {
        const r = await updateSupplierLevel(row.id, level)
        if (r.code === 0) { this.$message.success('评级已更新'); this.loadList() }
      } catch (e) {}
    },
    async handleExport() {
      try {
        const res = await exportSupplier(this.filter)
        const blob = res.data
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'suppliers_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.supplier-page { padding: 4px 16px; }
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
