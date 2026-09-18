<template>
  <div class="device-asset-page">
    <!-- 面包屑 -->
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>设备管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备台账</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 运行时错误诊断显示 -->
    <div v-if="pageError" style="background:#fef0f0;color:#f56c6c;padding:8px 12px;margin-bottom:10px;border-radius:4px;white-space:pre-wrap;font-size:12px">
      ⚠ 页面运行时错误：{{ pageError }}
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card" :class="{ active: filter.status === '' }" @click="quickFilter('')">
          <div class="stat-icon blue"><i class="el-icon-s-data"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">总设备数</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card" :class="{ active: filter.status === 'in_use' }" @click="quickFilter('in_use')">
          <div class="stat-icon green"><i class="el-icon-check"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.in_use || 0 }}</div><div class="stat-label">在用设备</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card" :class="{ active: filter.status === 'repairing' }" @click="quickFilter('repairing')">
          <div class="stat-icon orange"><i class="el-icon-warning"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.repairing || 0 }}</div><div class="stat-label">维修中设备</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card" :class="{ active: filter.status === 'idle' }" @click="quickFilter('idle')">
          <div class="stat-icon gray"><i class="el-icon-turn-off"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.idle || 0 }}</div><div class="stat-label">闲置设备</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区 -->
    <div class="panel">
      <el-form :inline="true" :model="filter" size="small" class="filter-form">
        <el-form-item label="设备类型">
          <el-select v-model="filter.device_type" clearable placeholder="全部类型" style="width:130px" @change="loadList">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属分类">
          <el-cascader v-model="filter.category_id" :options="categories" :props="cascaderProps"
                       clearable filterable placeholder="全部分类" style="width:180px" @change="loadList" />
        </el-form-item>
        <el-form-item label="使用部门">
          <el-select v-model="filter.department_id" clearable placeholder="全部部门" style="width:140px" @change="loadList">
            <el-option v-for="d in departmentList" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" clearable placeholder="全部状态" style="width:120px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filter.keyword" placeholder="请输入设备名称/编码/型号/品牌" clearable style="width:220px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="onReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 表格 -->
    <div class="panel">
      <div class="toolbar">
        <div class="toolbar-left">
          <el-button v-if="hasPerm('device:asset:add')" size="small" type="primary" icon="el-icon-plus" @click="openForm('add')">新增设备</el-button>
          <el-button v-if="hasPerm('device:asset:delete')" :disabled="!selection.length" size="small" type="danger" icon="el-icon-delete" @click="batchDelete">批量删除</el-button>
          <el-button v-if="hasPerm('device:asset:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button v-if="hasPerm('device:asset:import')" size="small" icon="el-icon-upload2" @click="importVisible = true">导入</el-button>
          <el-button v-if="hasPerm('device:qrcode:generate')" :disabled="!selection.length" size="small" icon="el-icon-full-screen" @click="qrcodeVisible = true; qrcodeTab = 'generate'">批量生成二维码</el-button>
          <el-button v-if="hasPerm('device:qrcode:download')" size="small" icon="el-icon-download" @click="qrcodeVisible = true; qrcodeTab = 'download'">下载二维码</el-button>
          <el-button v-if="hasPerm('device:qrcode:print')" :disabled="!selection.length" size="small" icon="el-icon-printer" @click="qrcodeVisible = true; qrcodeTab = 'print'">打印标签</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
        <div class="toolbar-right">共 {{ total }} 条</div>
      </div>

      <!-- 手机端卡片列表 -->
      <div v-if="isMobile" class="mobile-list">
        <div v-for="d in list" :key="d.id" class="mobile-card">
          <div class="mc-top">
            <el-checkbox :value="isCardSelected(d.id)" @change="v => toggleCardSelect(d, v)" @click.stop></el-checkbox>
            <span class="mc-name" @click="openDetail(d.id)">{{ d.name }}</span>
            <el-tag :type="statusTagType(d.status)" size="mini">{{ statusLabel(d.status) }}</el-tag>
          </div>
          <div class="mc-line" @click="openDetail(d.id)">编码：{{ d.device_code }}</div>
          <div class="mc-line" v-if="d.category_name" @click="openDetail(d.id)">分类：{{ d.category_name }}</div>
          <div class="mc-line" v-if="d.department_name" @click="openDetail(d.id)">部门：{{ d.department_name }}</div>
          <div class="mc-line" v-if="d.location" @click="openDetail(d.id)">位置：{{ d.location }}</div>
          <div class="mc-actions" @click.stop>
            <el-button v-if="hasPerm('device:asset:query')" size="mini" type="text" @click="openDetail(d.id)">详情</el-button>
            <el-button v-if="hasPerm('device:asset:edit')" size="mini" type="text" @click="openForm('edit', d)">编辑</el-button>
            <el-button v-if="hasPerm('device:asset:status')" size="mini" type="text" @click="openStatus(d)">状态</el-button>
            <el-button v-if="hasPerm('device:qrcode:generate')" size="mini" type="text" @click="generateOne(d)">{{ d.qrcode_url ? '重新生成' : '二维码' }}</el-button>
            <el-button v-if="hasPerm('device:asset:delete')" size="mini" type="text" style="color:#F56C6C" @click="confirmDelete(d)">删除</el-button>
          </div>
        </div>
        <el-empty v-if="!list.length" description="暂无设备数据" />
      </div>
      <el-table v-else :key="isMobile ? 'm' : 'd'" :data="list" size="small" border stripe style="width:100%" @selection-change="sel => (selection = sel)"
                @sort-change="onSortChange" highlight-current-row>
        <el-table-column type="selection" width="44" align="center" />
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="device_code" label="设备编码" width="140" sortable="custom">
          <template slot-scope="{ row }"><el-link type="primary" @click="openDetail(row.id)">{{ row.device_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="name" label="设备名称" min-width="150" />
        <el-table-column v-if="!isMobile" label="设备类型" width="100" align="center">
          <template slot-scope="{ row }"><el-tag :type="typeTagType(row.device_type)" size="small" effect="plain">{{ typeLabel(row.device_type) }}</el-tag></template>
        </el-table-column>
        <el-table-column v-if="!isMobile" label="所属分类" min-width="150">
          <template slot-scope="{ row }"><span style="font-size:12px">{{ row.category_name || '-' }}</span></template>
        </el-table-column>
        <el-table-column v-if="!isMobile" prop="model" label="型号" width="120" />
        <el-table-column v-if="!isMobile" prop="brand" label="品牌" width="100" />
        <el-table-column v-if="!isMobile" prop="department_name" label="使用部门" width="120" />
        <el-table-column v-if="!isMobile" prop="manager_name" label="负责人" width="80" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag :type="statusTagType(row.status)" size="mini">{{ statusLabel(row.status) }}</el-tag></template>
        </el-table-column>
        <el-table-column v-if="!isMobile" prop="purchase_date" label="采购日期" width="110" />
        <el-table-column v-if="!isMobile" label="二维码" width="90" align="center">
          <template slot-scope="{ row }">
            <el-image v-if="row.qrcode_url" :src="row.qrcode_url" style="width:44px;height:44px" fit="cover" :preview-src-list="[row.qrcode_url]" />
            <span v-else style="color:#C0C4CC;font-size:12px">未生成</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" :width="isMobile ? 150 : 250" :fixed="isMobile ? false : 'right'" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('device:asset:query')" size="mini" type="text" icon="el-icon-view" @click="openDetail(row.id)">详情</el-button>
            <el-button v-if="hasPerm('device:asset:edit')" size="mini" type="text" icon="el-icon-edit" @click="openForm('edit', row)">编辑</el-button>
            <el-button v-if="hasPerm('device:asset:status')" size="mini" type="text" icon="el-icon-sort" @click="openStatus(row)">状态</el-button>
            <el-button v-if="(!isMobile) && hasPerm('device:qrcode:generate')"  size="mini" type="text" icon="el-icon-full-screen" @click="generateOne(row)">{{ row.qrcode_url ? '重新生成' : '二维码' }}</el-button>
            <el-button v-if="hasPerm('device:asset:delete')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="confirmDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
                     :total="total" :current-page="page" :page-size="limit"
                     :page-sizes="[10, 20, 50, 100]" @current-change="p => (page = p, loadList())"
                     @size-change="s => (limit = s, page = 1, loadList())" />
    </div>

    <!-- 弹窗 -->
    <asset-form-dialog :visible.sync="formVisible" :mode="formMode" :asset-id="editId"
                       :categories="categories" :type-options="typeOptions" :status-options="statusOptions"
                       :special-type-options="specialTypeOptions" :fuel-type-options="fuelTypeOptions"
                       :supplier-list="supplierList" :manager-list="managerList" :department-list="departmentList"
                       @saved="onSaved" />
    <asset-detail-dialog :visible.sync="detailVisible" :asset-id="detailId" :width="isMobile ? '96%' : '1000px'" :type-options="typeOptions"
                         :special-type-options="specialTypeOptions" :fuel-type-options="fuelTypeOptions"
                         :status-options="statusOptions" :manager-list="managerList" />
    <asset-status-dialog :visible.sync="statusVisible" :asset="currentAsset" :status-options="statusOptions" @saved="onSaved" />
    <asset-import-dialog :visible.sync="importVisible" @saved="onSaved" />
    <qrcode-manage-dialog :visible.sync="qrcodeVisible" :active-tab.sync="qrcodeTab" :selected="selection" :all-count="total" @saved="onSaved" />
  </div>
</template>

<script>
import { getAssetList, deleteAsset, batchDeleteAssets, exportAssets, getAssetStatistics } from '@/api/deviceAsset'
import { getCategoryTree } from '@/api/deviceCategory'
import { getDeptTree } from '@/api/organization'
import { getDictionaryBatch } from '@/utils/dict'
import { getSuppliers, getManagers } from '@/api/deviceAsset'
import AssetFormDialog from './components/AssetFormDialog.vue'
import AssetDetailDialog from './components/AssetDetailDialog.vue'
import AssetStatusDialog from './components/AssetStatusDialog.vue'
import AssetImportDialog from './components/AssetImportDialog.vue'
import QrcodeManageDialog from './components/QrcodeManageDialog.vue'
import { generateQrcode } from '@/api/deviceQrcode'

export default {
  name: 'DeviceAsset',
  components: { AssetFormDialog, AssetDetailDialog, AssetStatusDialog, AssetImportDialog, QrcodeManageDialog },
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 20,
      selection: [],
      filter: { keyword: '', device_type: '', category_id: '', department_id: '', status: '' },
      sortField: 'create_time',
      sortOrder: 'desc',
      stats: {},
      // 字典/选项数据
      typeOptions: [],
      statusOptions: [],
      specialTypeOptions: [],
      fuelTypeOptions: [],
      categories: [],
      departmentList: [],
      supplierList: [],
      managerList: [],
      cascaderProps: { checkStrictly: true, emitPath: false, value: 'id', label: 'name', children: 'children' },
      // 弹窗
      formVisible: false,
      formMode: 'add',
      editId: 0,
      detailVisible: false,
      detailId: 0,
      statusVisible: false,
      currentAsset: {},
      importVisible: false,
      qrcodeVisible: false,
      qrcodeTab: 'generate',
      pageError: '',
      loadSeq: 0,
      isMobile: false
    }
  },
  async created() {
    // 移动端检测
    this.checkMobile()
    window.addEventListener('resize', this.checkMobile)
    // 运行时错误捕获（诊断用）
    const self = this
    window.onerror = function (msg) {
      self.pageError = (self.pageError ? self.pageError + '\n' : '') + String(msg).slice(0, 300)
    }
    window.addEventListener('unhandledrejection', function (e) {
      const msg = e.reason && e.reason.message ? e.reason.message : String(e.reason)
      self.pageError = (self.pageError ? self.pageError + '\n' : '') + '[Promise] ' + msg.slice(0, 300)
    })
    this.loadDicts()
    this.loadOptions()
    this.loadList()
    this.loadStats()
    // 兜底：确保权限已加载
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      try { await this.$store.dispatch('user/loadPermissions') } catch (e) {}
    }
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
  },
  methods: {
    // 响应式权限
    hasPerm(code) {
      const perms = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return perms.indexOf(code) > -1
    },
    checkMobile() {
      // 手机横屏宽度可能 >768，需用 UA 判断移动设备，保证横竖屏均走卡片式
      const ua = navigator.userAgent || ''
      const isTouchDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile/i.test(ua)
      this.isMobile = isTouchDevice || window.innerWidth < 768
    },
    async loadDicts() {
      try {
        const res = await getDictionaryBatch(['device_type', 'device_status', 'special_type', 'fuel_type'])
        this.typeOptions = res['device_type'] || []
        this.statusOptions = res['device_status'] || []
        this.specialTypeOptions = res['special_type'] || []
        this.fuelTypeOptions = res['fuel_type'] || []
      } catch (e) {}
    },
    async loadOptions() {
      try {
        const [c, d, s, m] = await Promise.all([getCategoryTree({ all: 1 }), getDeptTree(), getSuppliers(), getManagers()])
        this.categories = (c.data && c.data.list) || []
        this.departmentList = this.flattenDept((d.data && d.data.list) || (d.data || []))
        this.supplierList = s.data || []
        this.managerList = m.data || []
      } catch (e) { /* 选项加载失败不阻塞 */ }
    },
    flattenDept(nodes, arr = []) {
      (nodes || []).forEach(n => { arr.push({ id: n.id, name: n.name }); if (n.children && n.children.length) this.flattenDept(n.children, arr) })
      return arr
    },
    async loadList() {
      const seq = ++this.loadSeq
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filter.keyword || '',
          device_type: this.filter.device_type || '',
          category_id: this.filter.category_id || '',
          department_id: this.filter.department_id || '',
          status: this.filter.status || '',
          sort_field: this.sortField,
          sort_order: this.sortOrder
        }
        const res = await getAssetList(params)
        // 丢弃过期请求（防止并发/重复触发的旧响应覆盖新数据）
        if (seq !== this.loadSeq) return
        if (res.code === 0) {
          this.list = res.data.list || []
          this.total = res.data.total || 0
        }
      } catch (e) { this.$message.error('网络异常，请稍后重试') }
      finally {
        if (seq === this.loadSeq) this.loading = false
      }
    },
    async loadStats() {
      try {
        const res = await getAssetStatistics()
        if (res.code === 0) this.stats = res.data
      } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    onReset() {
      this.filter = { keyword: '', device_type: '', category_id: '', department_id: '', status: '' }
      this.page = 1
      // nextTick 等待筛选组件值更新完成，避免其 change 事件用旧筛选值触发重复加载
      this.$nextTick(() => this.loadList())
    },
    quickFilter(status) {
      this.filter.status = this.filter.status === status && status !== '' ? '' : status
      this.page = 1
      this.loadList()
    },
    onSortChange({ prop, order }) {
      if (order) { this.sortField = prop === 'device_code' ? 'device_code' : prop === 'purchase_date' ? 'purchase_date' : 'create_time'; this.sortOrder = order === 'ascending' ? 'asc' : 'desc' }
      this.loadList()
    },
    // 字典标签
    typeLabel(v) { const t = this.typeOptions.find(x => x.value === v); return t ? t.label : (v || '-') },
    statusLabel(v) { const s = this.statusOptions.find(x => x.value === v); return s ? s.label : (v || '-') },
    typeTagType(v) { return { general: 'primary', special: 'danger', car: 'success', truck: 'warning' }[v] || 'info' },
    statusTagType(v) { const s = this.statusOptions.find(x => x.value === v); return (s && s.style) || 'info' },
    // 弹窗操作
    openForm(mode, row) {
      this.formMode = mode
      this.editId = row ? row.id : 0
      this.formVisible = true
    },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    // 手机端卡片多选
    isCardSelected(id) { return this.selection.some(x => x.id === id) },
    toggleCardSelect(d, v) {
      if (v) {
        if (!this.selection.some(x => x.id === d.id)) this.selection.push(d)
      } else {
        this.selection = this.selection.filter(x => x.id !== d.id)
      }
    },
    openStatus(row) { this.currentAsset = row; this.statusVisible = true },
    // 单设备生成/重新生成二维码
    async generateOne(row) {
      try {
        const res = await generateQrcode(row.id)
        if (res.code === 0) { this.$message.success(res.msg || '二维码生成成功'); this.loadList() }
      } catch (e) { /* 拦截器已提示 */ }
    },
    confirmDelete(row) {
      this.$confirm(`确定要删除设备 [${row.name}] 吗？删除后不可恢复。`, '提示', { type: 'warning' })
        .then(async () => {
          try { await deleteAsset(row.id); this.$message.success('删除成功'); this.onSaved() } catch (e) {}
        }).catch(() => {})
    },
    batchDelete() {
      if (!this.selection.length) { this.$message.warning('请选择要删除的设备'); return }
      this.$confirm(`确定要删除选中的 ${this.selection.length} 台设备吗？删除后不可恢复。`, '提示', { type: 'warning' })
        .then(async () => {
          try {
            const res = await batchDeleteAssets(this.selection.map(x => x.id))
            if (res.code === 0) { this.$message.success(res.msg || '删除完成'); this.onSaved() }
          } catch (e) {}
        }).catch(() => {})
    },
    async doExport() {
      this.$confirm(`当前筛选条件下共 ${this.total} 条设备数据，确定导出吗？`, '导出确认', { type: 'info' })
        .then(async () => {
          try {
            const res = await exportAssets({
              keyword: this.filter.keyword || '', device_type: this.filter.device_type || '',
              category_id: this.filter.category_id || '', department_id: this.filter.department_id || '', status: this.filter.status || ''
            })
            if (res.code === 0 && res.data && res.data.url) { window.open(res.data.url, '_blank'); this.$message.success('导出成功') }
          } catch (e) {}
        }).catch(() => {})
    },
    onSaved() { this.loadList(); this.loadStats() }
  }
}
</script>

<style scoped>
.device-asset-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.stat-row { margin-bottom: 16px; }
.stat-card { display: flex; align-items: center; gap: 12px; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.04); cursor: pointer; border: 2px solid transparent; }
.stat-card.active { border-color: #409EFF; }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #fff; }
.stat-icon.blue { background: #409EFF; }
.stat-icon.green { background: #67C23A; }
.stat-icon.orange { background: #E6A23C; }
.stat-icon.gray { background: #909399; }
.stat-num { font-size: 22px; font-weight: 700; }
.stat-label { color: #909399; font-size: 12px; }
.panel { background: #fff; border-radius: 8px; padding: 14px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 16px; }
.filter-form { margin-bottom: 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-left { display: flex; gap: 8px; flex-wrap: wrap; }
.toolbar-right { color: #909399; font-size: 13px; }
.pager { margin-top: 14px; text-align: right; }
/* 手机端卡片列表 */
.mobile-list { display: flex; flex-direction: column; gap: 10px; }
.mobile-card { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 12px; }
.mc-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.mc-name { font-size: 15px; font-weight: 600; }
.mc-line { color: #606266; font-size: 12px; margin: 3px 0; }
.mc-actions { display: flex; gap: 4px; margin-top: 8px; flex-wrap: wrap; }
</style>
