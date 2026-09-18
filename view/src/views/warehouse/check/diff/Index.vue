<!--
  文件：admin/src/views/warehouse/check/diff/Index.vue
  功能：盘点差异（差异列表/统计/处理/忽略/生成调整单/详情）
  权限：warehouse:check:diff:view / process / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存盘点</el-breadcrumb-item>
      <el-breadcrumb-item>盘点差异</el-breadcrumb-item>
    </el-breadcrumb>

    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="'stat-' + card.key" @click="handleCardFilter(card)">
          <div class="stat-icon"><i :class="card.icon"></i></div>
          <div class="stat-body">
            <div class="stat-num" :class="'num-' + card.key">{{ stats[card.key] || 0 }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="盘点计划">
          <el-select v-model="query.plan_id" clearable placeholder="全部计划" style="width:150px">
            <el-option v-for="p in plans" :key="p.id" :label="p.plan_no + ' ' + p.plan_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="物料名称"><el-input v-model="query.material_name" placeholder="请输入物料名称" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料编码"><el-input v-model="query.material_code" placeholder="请输入物料编码" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="差异类型">
          <el-select v-model="query.difference_type" clearable placeholder="全部" style="width:100px">
            <el-option label="盘盈" :value="1" />
            <el-option label="盘亏" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="处理状态">
          <el-select v-model="query.process_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in processOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="盘点日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:210px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
        <el-button v-permission="'warehouse:check:diff:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出差异报表</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条差异记录</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无差异数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="diff_no" label="差异编号" width="150" />
      <el-table-column prop="material_code" label="物料编码" width="130" />
      <el-table-column prop="material_name" label="物料名称" min-width="150" show-overflow-tooltip />
      <el-table-column prop="specification" label="规格型号" width="140" show-overflow-tooltip />
      <el-table-column prop="unit" label="单位" width="70" align="center" />
      <el-table-column prop="system_quantity" label="系统库存" width="110" align="center" />
      <el-table-column prop="actual_quantity" label="实际库存" width="110" align="center" />
      <el-table-column label="差异数量" width="110" align="center">
        <template slot-scope="s"><span :class="s.row.difference_quantity > 0 ? 'diff-plus' : 'diff-minus'">{{ s.row.difference_quantity > 0 ? '+' : '' }}{{ s.row.difference_quantity }}</span></template>
      </el-table-column>
      <el-table-column label="差异类型" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.difference_type_tag" size="mini">{{ s.row.difference_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="location_name" label="关联货位" width="120" />
      <el-table-column label="处理状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.process_status_tag" size="mini">{{ s.row.process_status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <template v-if="s.row.process_status === 0">
            <el-button v-permission="'warehouse:check:diff:process'" type="text" size="mini" @click="openProcess(s.row)">处理差异</el-button>
            <el-button v-permission="'warehouse:check:diff:process'" type="text" size="mini" class="danger-text" @click="handleIgnore(s.row)">忽略差异</el-button>
            <el-button v-permission="'warehouse:check:diff:process'" type="text" size="mini" @click="handleGenerate(s.row)">生成调整单</el-button>
          </template>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 差异详情抽屉 -->
    <el-drawer title="差异详情" :visible.sync="detailVisible" size="750px" append-to-body>
      <div v-loading="detailLoading" class="drawer-body">
        <template v-if="detailData">
          <div class="section-title">差异基本信息</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="差异编号">{{ detailData.diff.diff_no }}</el-descriptions-item>
            <el-descriptions-item label="物料编码">{{ detailData.diff.material_code }}</el-descriptions-item>
            <el-descriptions-item label="物料名称">{{ detailData.diff.material_name }}</el-descriptions-item>
            <el-descriptions-item label="规格型号">{{ detailData.diff.specification || '-' }}</el-descriptions-item>
            <el-descriptions-item label="单位">{{ detailData.diff.unit || '-' }}</el-descriptions-item>
            <el-descriptions-item label="系统库存">{{ detailData.diff.system_quantity }}</el-descriptions-item>
            <el-descriptions-item label="实际库存">{{ detailData.diff.actual_quantity }}</el-descriptions-item>
            <el-descriptions-item label="差异数量"><span :class="detailData.diff.difference_quantity > 0 ? 'diff-plus' : 'diff-minus'">{{ detailData.diff.difference_quantity }}</span></el-descriptions-item>
            <el-descriptions-item label="差异类型">{{ detailData.diff.difference_type_label }}</el-descriptions-item>
            <el-descriptions-item label="关联货位">{{ detailData.diff.location_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="盘点计划">{{ (detailData.task && detailData.task.plan_no) || '-' }}</el-descriptions-item>
            <el-descriptions-item label="盘点任务">{{ (detailData.task && detailData.task.task_no) || '-' }}</el-descriptions-item>
            <el-descriptions-item label="盘点人">{{ detailData.diff.scanned_by_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="盘点时间">{{ detailData.diff.scanned_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="处理状态">{{ detailData.diff.process_status_label }}</el-descriptions-item>
            <el-descriptions-item label="处理时间">{{ detailData.diff.process_at || '-' }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">盘点任务信息</div>
          <el-descriptions :column="2" border size="small" v-if="detailData.task">
            <el-descriptions-item label="任务编号">{{ detailData.task.task_no }}</el-descriptions-item>
            <el-descriptions-item label="被分配人">{{ detailData.task.assignee_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="计划名称">{{ detailData.task.plan_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="货位">{{ detailData.task.location_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="预计开始">{{ detailData.task.expected_start_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="预计结束">{{ detailData.task.expected_end_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="实际开始">{{ detailData.task.actual_start_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="实际结束">{{ detailData.task.actual_end_time || '-' }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">差异原因分析</div>
          <el-input :value="detailData.diff.process_remark || '（暂无处理备注）'" type="textarea" :rows="3" disabled />

          <div class="section-title">调整单信息</div>
          <el-descriptions :column="2" border size="small" v-if="detailData.adjust">
            <el-descriptions-item label="调整单编号">{{ detailData.adjust.order_no }}</el-descriptions-item>
            <el-descriptions-item label="调整类型">{{ detailData.adjust.type }}</el-descriptions-item>
            <el-descriptions-item label="调整数量">{{ detailData.adjust.quantity }}</el-descriptions-item>
            <el-descriptions-item label="调整状态">{{ detailData.adjust.status }}</el-descriptions-item>
          </el-descriptions>
          <div v-else class="empty-tip">未生成调整单</div>
        </template>
      </div>
    </el-drawer>

    <!-- 处理差异对话框 -->
    <el-dialog title="处理差异" :visible.sync="processVisible" width="550px" :close-on-click-modal="false" append-to-body>
      <el-form label-width="100px" size="small" v-if="processRow">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="物料">{{ processRow.material_code }} {{ processRow.material_name }}</el-descriptions-item>
          <el-descriptions-item label="规格型号">{{ processRow.specification || '-' }}</el-descriptions-item>
          <el-descriptions-item label="系统库存">{{ processRow.system_quantity }}</el-descriptions-item>
          <el-descriptions-item label="实际库存">{{ processRow.actual_quantity }}</el-descriptions-item>
          <el-descriptions-item label="差异数量"><span :class="processRow.difference_quantity > 0 ? 'diff-plus' : 'diff-minus'">{{ processRow.difference_quantity }}</span></el-descriptions-item>
          <el-descriptions-item label="差异类型">{{ processRow.difference_type_label }}</el-descriptions-item>
        </el-descriptions>
        <el-form-item label="处理方式" style="margin-top:14px">
          <el-radio-group v-model="processType">
            <el-radio :label="1">生成调整单（自动调整库存）</el-radio>
            <el-radio :label="2">仅记录处理结果（不调整库存）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="调整原因">
          <el-input v-model="processRemark" type="textarea" :rows="3" maxlength="200" placeholder="请填写差异原因或处理说明" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="processVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="processing" @click="handleProcess">确认处理</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getDiffList, getDiffDetail, processDiff, ignoreDiff, exportDiff, getPlanList } from '@/api/warehouse'

export default {
  name: 'InventoryDiff',
  data () {
    return {
      processOptions: { 0: '待处理', 1: '已处理', 2: '已忽略' },
      statCards: [
        { key: 'total', label: '总差异数', icon: 'el-icon-document', filter: { type: 'diff_type', value: '' } },
        { key: 'gain', label: '盘盈', icon: 'el-icon-top', filter: { type: 'diff_type', value: 1 } },
        { key: 'loss', label: '盘亏', icon: 'el-icon-bottom', filter: { type: 'diff_type', value: 2 } },
        { key: 'pending', label: '待处理', icon: 'el-icon-warning', filter: { type: 'process_status', value: 0 } }
      ],
      query: { plan_id: null, material_name: '', material_code: '', difference_type: '', process_status: '', dateRange: [] },
      cardStatus: '',
      stats: { total: 0, gain: 0, loss: 0, pending: 0 },
      plans: [],
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      detailVisible: false, detailLoading: false, detailData: null,
      processVisible: false, processRow: null, processType: 1, processRemark: '', processing: false
    }
  },
  created () { this.loadData(); this.loadPlans() },
  methods: {
    async loadPlans () {
      try {
        const r = await getPlanList({ page: 1, pageSize: 100, status: 4 })
        if (r.code === 0) this.plans = (r.data && r.data.list) || []
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.plan_id) p.plan_id = this.query.plan_id
      if (this.query.material_name) p.material_name = this.query.material_name
      if (this.query.material_code) p.material_code = this.query.material_code
      if (this.query.difference_type !== '' && this.query.difference_type !== null) p.difference_type = this.query.difference_type
      if (this.query.process_status !== '' && this.query.process_status !== null) p.process_status = this.query.process_status
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      if (this.cardStatus) p[this.cardStatus.type] = this.cardStatus.value
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getDiffList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || { total: 0, gain: 0, loss: 0, pending: 0 }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.cardStatus = ''; this.page = 1; this.loadData() },
    handleReset () { this.query = { plan_id: null, material_name: '', material_code: '', difference_type: '', process_status: '', dateRange: [] }; this.cardStatus = ''; this.page = 1; this.loadData() },
    handleCardFilter (card) {
      const same = this.cardStatus && this.cardStatus.type === card.filter.type && String(this.cardStatus.value) === String(card.filter.value)
      this.cardStatus = same ? '' : card.filter
      this.page = 1
      this.loadData()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    openDetail (row) {
      this.detailVisible = true
      this.detailLoading = true
      this.detailData = null
      getDiffDetail(row.id).then(r => {
        if (r.code === 0) this.detailData = r.data
      }).catch(() => {}).finally(() => { this.detailLoading = false })
    },
    openProcess (row) { this.processRow = row; this.processType = 1; this.processRemark = ''; this.processVisible = true },
    handleProcess () {
      processDiff(this.processRow.id, { process_type: this.processType, remark: this.processRemark }).then(r => {
        if (r.code === 0) { this.$message.success('处理成功'); this.processVisible = false; this.loadData() } else this.$message.error(r.msg || '处理失败')
      }).catch(() => {})
    },
    handleIgnore (row) {
      this.$confirm('确认忽略该差异吗？忽略后该差异不再处理', '忽略差异', { type: 'warning' }).then(() => {
        ignoreDiff(row.id, { remark: '' }).then(r => {
          if (r.code === 0) { this.$message.success('已忽略'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        }).catch(() => {})
      }).catch(() => {})
    },
    handleGenerate (row) {
      this.$confirm('确认生成库存调整单吗？将根据差异数量自动生成盘盈入库或盘亏出库单', '生成调整单', { type: 'warning' }).then(() => {
        processDiff(row.id, { process_type: 1, remark: '生成调整单' }).then(r => {
          if (r.code === 0) { this.$message.success('调整单已生成' + (r.data && r.data.adjust_order_no ? '：' + r.data.adjust_order_no : '')); this.loadData() } else this.$message.error(r.msg || '操作失败')
        }).catch(() => {})
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const response = await exportDiff(this.buildParams())
        const url = URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.download = '盘点差异_' + new Date().toISOString().slice(0, 19).replace(/[-:T]/g, '') + '.xlsx'
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.stat-row { margin-bottom: 14px; }
.stat-card { display: flex; align-items: center; border-radius: 10px; padding: 18px 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: all .25s ease; }
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,0.12); }
.stat-total { background: linear-gradient(135deg,#ecf5ff,#d9ecff); }
.stat-gain { background: linear-gradient(135deg,#f0f9eb,#e1f3d8); }
.stat-loss { background: linear-gradient(135deg,#fef0f0,#fde2e2); }
.stat-pending { background: linear-gradient(135deg,#fff7e6,#ffe7ba); }
.stat-icon { font-size: 34px; color: #909399; margin-right: 14px; }
.stat-num { font-size: 26px; font-weight: 700; line-height: 1.1; }
.num-total { color: #409EFF; } .num-gain { color: #67C23A; }
.num-loss { color: #F56C6C; } .num-pending { color: #E6A23C; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.diff-plus { color: #67C23A; font-weight: 600; }
.diff-minus { color: #F56C6C; font-weight: 600; }
.danger-text { color: #F56C6C; }
.drawer-body { padding: 8px 20px 30px; }
.section-title { font-size: 15px; font-weight: 600; margin: 20px 0 12px; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; }
.empty-tip { color: #909399; }
</style>
