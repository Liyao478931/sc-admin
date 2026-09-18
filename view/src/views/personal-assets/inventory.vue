<template>
  <div class="iv-page">
    <el-breadcrumb separator="/" class="iv-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>固定资产管理</el-breadcrumb-item>
      <el-breadcrumb-item>资产盘点</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <div class="iv-stats">
      <div class="iv-stat-card" @click="filterByStatus('')"><div class="iv-stat-info"><div class="iv-stat-num" style="color:#409EFF">{{ stats.total }}</div><div class="iv-stat-label">总盘点单</div></div><div class="iv-stat-icon" style="background:#ecf5ff"><i class="el-icon-document" style="color:#409EFF"></i></div></div>
      <div class="iv-stat-card" @click="filterByStatus(0)"><div class="iv-stat-info"><div class="iv-stat-num" style="color:#E6A23C">{{ stats.pending }}</div><div class="iv-stat-label">待执行</div></div><div class="iv-stat-icon" style="background:#fdf6ec"><i class="el-icon-time" style="color:#E6A23C"></i></div></div>
      <div class="iv-stat-card" @click="filterByStatus(1)"><div class="iv-stat-info"><div class="iv-stat-num" style="color:#409EFF">{{ stats.executing }}</div><div class="iv-stat-label">执行中</div></div><div class="iv-stat-icon" style="background:#ecf5ff"><i class="el-icon-loading" style="color:#409EFF"></i></div></div>
      <div class="iv-stat-card" @click="filterByStatus(2)"><div class="iv-stat-info"><div class="iv-stat-num" style="color:#67C23A">{{ stats.finished }}</div><div class="iv-stat-label">已完成</div></div><div class="iv-stat-icon" style="background:#f0f9eb"><i class="el-icon-success" style="color:#67C23A"></i></div></div>
    </div>

    <!-- 操作栏 -->
    <div class="iv-toolbar">
      <el-button size="small" type="primary" icon="el-icon-plus" @click="openCreate">创建盘点单</el-button>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="iv-total">共 {{ total }} 条</span>
    </div>

    <!-- 筛选 -->
    <div class="iv-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="盘点单号"><el-input v-model="query.plan_no" placeholder="盘点单号" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="盘点名称"><el-input v-model="query.plan_name" placeholder="盘点名称" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="盘点日期"><el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" style="width:220px" /></el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 列表 -->
    <div class="iv-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无盘点单">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="盘点单号" width="140"><template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.plan_no }}</el-link></template></el-table-column>
        <el-table-column prop="plan_name" label="盘点名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="plan_type_label" label="方式" width="70" align="center" />
        <el-table-column prop="scope_label" label="范围" width="90" />
        <el-table-column prop="plan_by_name" label="负责人" width="80" />
        <el-table-column prop="plan_date" label="计划日期" width="100" align="center" />
        <el-table-column label="进度" width="130">
          <template slot-scope="s">
            <div class="iv-progress"><span class="iv-progress-num">{{ s.row.checked_assets }}/{{ s.row.total_assets }}</span><el-progress :percentage="s.row.progress" :stroke-width="8" :show-text="false" style="width:70px" /></div>
          </template>
        </el-table-column>
        <el-table-column label="差异数" width="70" align="center"><template slot-scope="s"><span :style="{ color: s.row.diff_count > 0 ? '#F56C6C' : '#909399' }">{{ s.row.diff_count }}</span></template></el-table-column>
        <el-table-column label="状态" width="85" align="center"><template slot-scope="s"><el-tag :type="statusType(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template></el-table-column>
        <el-table-column label="操作" width="160" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row)">查看</el-button>
            <el-button v-if="s.row.status === 0 || s.row.status === 1" type="text" size="mini" @click="goExecute(s.row)">执行</el-button>
            <el-button v-if="s.row.status === 0" type="text" size="mini" style="color:#F56C6C" @click="handleCancel(s.row)">取消</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="iv-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper" :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]" @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 创建盘点单弹窗 -->
    <el-dialog title="创建盘点单" :visible.sync="createVisible" width="560px" append-to-body>
      <el-form ref="createForm" :model="createForm" :rules="createRules" label-width="100px" size="small">
        <el-form-item label="盘点名称" prop="plan_name"><el-input v-model="createForm.plan_name" placeholder="如：2026年8月月度盘点" /></el-form-item>
        <el-form-item label="盘点方式" prop="plan_type">
          <el-radio-group v-model="createForm.plan_type">
            <el-radio :label="1">全盘</el-radio>
            <el-radio :label="2">抽盘</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="盘点范围" prop="scope_type">
          <el-radio-group v-model="createForm.scope_type">
            <el-radio :label="1">全部资产</el-radio>
            <el-radio :label="2">按部门</el-radio>
            <el-radio :label="3">按分类</el-radio>
            <el-radio :label="4">按保管人</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="createForm.scope_type === 2" label="选择部门">
          <el-select v-model="scopeValue" multiple placeholder="选择部门" style="width:100%">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="createForm.scope_type === 3" label="选择分类">
          <el-select v-model="scopeValue" multiple placeholder="选择分类" style="width:100%">
            <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="createForm.scope_type === 4" label="选择保管人">
          <el-select v-model="scopeValue" multiple placeholder="选择员工" style="width:100%">
            <el-option v-for="e in empOptions" :key="e.user_id" :label="e.name" :value="e.user_id" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划日期" prop="plan_date"><el-date-picker v-model="createForm.plan_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="负责人" prop="plan_by">
          <el-select v-model="createForm.plan_by" filterable placeholder="选择员工" style="width:100%">
            <el-option v-for="e in empOptions" :key="e.user_id" :label="e.name" :value="e.user_id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="createForm.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="createVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="creating" @click="submitCreate">创建</el-button>
      </div>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog :title="'盘点详情 - ' + (detail.plan_no || '')" :visible.sync="detailVisible" width="800px" append-to-body>
      <div v-loading="detailLoading" class="iv-detail-body">
        <template v-if="detail.plan_no">
          <div class="iv-detail-head">
            <div class="iv-detail-item"><span class="iv-lb">盘点名称</span>{{ detail.plan_name }}</div>
            <div class="iv-detail-item"><span class="iv-lb">方式</span>{{ detail.plan_type_label }}</div>
            <div class="iv-detail-item"><span class="iv-lb">范围</span>{{ detail.scope_label }}</div>
            <div class="iv-detail-item"><span class="iv-lb">负责人</span>{{ detail.plan_by_name }}</div>
            <div class="iv-detail-item"><span class="iv-lb">日期</span>{{ detail.plan_date }}</div>
            <div class="iv-detail-item"><span class="iv-lb">状态</span><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_label }}</el-tag></div>
            <div class="iv-detail-item"><span class="iv-lb">应盘</span>{{ detail.total_assets }}</div>
            <div class="iv-detail-item"><span class="iv-lb">已盘</span>{{ detail.checked_assets }}</div>
            <div class="iv-detail-item"><span class="iv-lb">差异</span><span style="color:#F56C6C">{{ detail.diff_count }}</span></div>
          </div>
          <div v-if="detail.diffs && detail.diffs.length" class="iv-diff-sec">
            <div class="iv-sec-title">差异报告 <el-button v-if="detail.status === 2" size="mini" type="primary" icon="el-icon-download" style="float:right" @click="handleExport">导出报告</el-button></div>
            <el-table :data="detail.diffs" size="small" border>
              <el-table-column type="index" label="#" width="45" align="center" />
              <el-table-column prop="diff_type_label" label="差异类型" width="75" align="center" />
              <el-table-column label="系统数量" width="85" align="right"><template slot-scope="s">{{ s.row.system_quantity }}</template></el-table-column>
              <el-table-column label="实际数量" width="85" align="right"><template slot-scope="s">{{ s.row.actual_quantity }}</template></el-table-column>
              <el-table-column label="差异数量" width="85" align="right"><template slot-scope="s">{{ s.row.diff_quantity }}</template></el-table-column>
              <el-table-column prop="process_status_label" label="处理状态" width="85" align="center" />
              <el-table-column label="操作" width="90" align="center">
                <template slot-scope="s">
                  <el-button v-if="s.row.process_status === 0" type="text" size="mini" @click="openHandleDiff(s.row)">处理</el-button>
                  <span v-else>-</span>
                </template>
              </el-table-column>
            </el-table>
          </div>
          <div class="iv-sec-title" style="margin-top:16px">盘点明细</div>
          <el-table :data="detail.tasks" size="small" border max-height="300">
            <el-table-column prop="asset_no" label="资产编号" width="120" />
            <el-table-column prop="asset_name" label="资产名称" min-width="110" />
            <el-table-column label="系统数量" width="80" align="right"><template slot-scope="s">{{ s.row.system_quantity }}</template></el-table-column>
            <el-table-column label="实际数量" width="80" align="right"><template slot-scope="s">{{ s.row.actual_quantity ?? '-' }}</template></el-table-column>
            <el-table-column label="差异" width="70" align="right"><template slot-scope="s"><span :style="{ color: s.row.diff_type === 1 ? '#E6A23C' : (s.row.diff_type === 2 ? '#F56C6C' : '#909399') }">{{ s.row.diff_type_label || '-' }}</span></template></el-table-column>
            <el-table-column label="状态" width="70" align="center"><template slot-scope="s">{{ s.row.check_status === 1 ? '已盘' : '待盘' }}</template></el-table-column>
            <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
          </el-table>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>

    <!-- 差异处理弹窗 -->
    <el-dialog title="处理差异" :visible.sync="diffVisible" width="500px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="资产信息"><span>{{ currentDiff.asset_name || ('资产#' + currentDiff.asset_id) }}</span></el-form-item>
        <el-form-item label="差异类型"><span :style="{ color: currentDiff.diff_type === 1 ? '#E6A23C' : '#F56C6C' }">{{ currentDiff.diff_type_label }}</span></el-form-item>
        <el-form-item label="系统/实际"><span>{{ currentDiff.system_quantity }} / {{ currentDiff.actual_quantity }}（差异 {{ currentDiff.diff_quantity }}）</span></el-form-item>
        <el-form-item label="处理状态">
          <el-radio-group v-model="diffForm.process_status">
            <el-radio :label="1">已确认</el-radio>
            <el-radio :label="2">已忽略</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="diffForm.process_status === 1" label="处理方式">
          <el-select v-model="diffForm.process_type" style="width:100%">
            <el-option :value="1" label="调整系统数量" />
            <el-option :value="2" label="补充入库" />
            <el-option :value="3" label="报废出库" />
          </el-select>
        </el-form-item>
        <el-form-item label="处理备注"><el-input v-model="diffForm.process_remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="diffVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="diffSubmitting" @click="submitDiff">确认</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getInventoryList, createInventory, getInventoryDetail, handleInventoryDiff, exportInventory, cancelInventory } from '../../api/inventory'
import { getAssetDepartments, getAssetEmployeeOptions } from '../../api/personalAssets'
import { getAssetCategoryList } from '../../api/assetArchive'

const STATUS_TEXT = { 0: '待执行', 1: '执行中', 2: '已完成', 3: '已取消' }

export default {
  name: 'AssetInventory',
  data () {
    return {
      STATUS_TEXT,
      stats: { total: 0, pending: 0, executing: 0, finished: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false,
      query: { plan_no: '', plan_name: '', status: '' }, dateRange: [],
      createVisible: false, creating: false, scopeValue: [],
      createForm: { plan_name: '', plan_type: 1, scope_type: 1, plan_date: new Date().toISOString().slice(0, 10), plan_by: '', remark: '' },
      createRules: {
        plan_name: [{ required: true, message: '请输入盘点名称', trigger: 'blur' }],
        plan_date: [{ required: true, message: '请选择计划日期', trigger: 'change' }],
        plan_by: [{ required: true, message: '请选择负责人', trigger: 'change' }]
      },
      deptOptions: [], categoryOptions: [], empOptions: [],
      detailVisible: false, detailLoading: false, detail: {},
      diffVisible: false, currentDiff: {}, diffForm: { process_status: 1, process_type: 1, process_remark: '' }, diffSubmitting: false
    }
  },
  created () {
    this.loadOptions()
    this.getList()
  },
  methods: {
    statusType (s) { return { 0: 'warning', 1: 'primary', 2: 'success', 3: 'info' }[s] || 'info' },
    async loadOptions () {
      try {
        const [d, c, e] = await Promise.all([
          getAssetDepartments().catch(() => ({ data: [] })),
          getAssetCategoryList().catch(() => ({ data: { flat: {} } })),
          getAssetEmployeeOptions('').catch(() => ({ data: [] }))
        ])
        if (d.code === 0) this.deptOptions = d.data || []
        if (c.code === 0) this.categoryOptions = Object.values(c.data.flat || {}).map(x => ({ id: x.id, name: x.name }))
        if (e.code === 0) this.empOptions = e.data || []
      } catch (err) {}
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.plan_no) p.plan_no = this.query.plan_no
      if (this.query.plan_name) p.plan_name = this.query.plan_name
      if (this.query.status !== '' && this.query.status != null) p.status = this.query.status
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getInventoryList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0; this.stats = r.data.statistics || { total: 0, pending: 0, executing: 0, finished: 0 } }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { plan_no: '', plan_name: '', status: '' }; this.dateRange = []; this.page = 1; this.getList() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    filterByStatus (s) { this.query.status = (s === '' || s == null) ? '' : Number(s); this.page = 1; this.getList() },
    openCreate () {
      this.createForm = { plan_name: '', plan_type: 1, scope_type: 1, plan_date: new Date().toISOString().slice(0, 10), plan_by: '', remark: '' }
      this.scopeValue = []
      this.createVisible = true
    },
    async submitCreate () {
      this.$refs.createForm.validate(async valid => {
        if (!valid) return
        this.creating = true
        try {
          const r = await createInventory({ ...this.createForm, scope_value: JSON.stringify(this.scopeValue) })
          if (r.code === 0) { this.$message.success(r.msg || '创建成功'); this.createVisible = false; this.getList() }
        } catch (e) {}
        this.creating = false
      })
    },
    goExecute (row) { this.$router.push('/personal-assets/inventory-execute?plan_id=' + row.id) },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getInventoryDetail({ plan_id: row.id })
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    openHandleDiff (diff) {
      this.currentDiff = diff
      this.diffForm = { process_status: 1, process_type: 1, process_remark: '' }
      this.diffVisible = true
    },
    async submitDiff () {
      this.diffSubmitting = true
      try {
        const r = await handleInventoryDiff({ diff_id: this.currentDiff.id, ...this.diffForm })
        if (r.code === 0) { this.$message.success(r.msg || '处理成功'); this.diffVisible = false; this.openDetail({ id: this.detail.id }) }
      } catch (e) {}
      this.diffSubmitting = false
    },
    async handleExport () {
      try {
        const res = await exportInventory({ plan_id: this.detail.id })
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '盘点报告_' + this.detail.plan_no + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
    },
    handleCancel (row) {
      this.$confirm('确认取消盘点单 ' + row.plan_no + ' 吗？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelInventory({ plan_id: row.id })
          if (r.code === 0) { this.$message.success('盘点单已取消'); this.getList() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.iv-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.iv-breadcrumb { margin-bottom: 12px; }
.iv-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.iv-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; cursor: pointer; }
.iv-stat-card:hover { box-shadow: 0 6px 20px rgba(31,45,61,.1); }
.iv-stat-num { font-size: 22px; font-weight: 700; }
.iv-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.iv-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.iv-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.iv-total { margin-left: 12px; color: #909399; font-size: 13px; }
.iv-filter { background: #fff; border-radius: 8px; padding: 14px 16px 0; margin-bottom: 12px; }
.iv-filter .el-form-item { margin-bottom: 14px; }
.iv-table { background: #fff; border-radius: 8px; padding: 12px; }
.iv-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.iv-progress { display: flex; align-items: center; gap: 8px; }
.iv-progress-num { font-size: 12px; color: #606266; }
.iv-detail-body { min-height: 150px; }
.iv-detail-head { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px 16px; margin-bottom: 16px; }
.iv-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.iv-lb { color: #909399; width: 50px; flex-shrink: 0; }
.iv-diff-sec { margin-bottom: 8px; }
.iv-sec-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
</style>