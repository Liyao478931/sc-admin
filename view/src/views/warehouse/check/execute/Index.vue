<!--
  文件：admin/src/views/warehouse/check/execute/Index.vue
  功能：盘点执行（双视图：任务列表 + 执行盘点）
  权限：warehouse:check:execute:view / execute / submit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存盘点</el-breadcrumb-item>
      <el-breadcrumb-item>盘点执行</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- ================= 视图一：任务列表 ================= -->
    <template v-if="viewMode === 'list'">
      <el-row :gutter="16" class="stat-row">
        <el-col :span="6" v-for="card in statCards" :key="card.key">
          <div class="stat-card" :class="'stat-' + card.key" @click="handleCardFilter(card.key)">
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
          <el-form-item label="任务编号"><el-input v-model="query.task_no" placeholder="请输入任务编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
          <el-form-item label="计划编号"><el-input v-model="query.plan_no" placeholder="请输入计划编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
          <el-form-item label="货位名称"><el-input v-model="query.location_name" placeholder="请输入货位名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
          <el-form-item label="任务状态">
            <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
              <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
            </el-select>
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
          <el-button size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        </div>
        <span class="total-text">共 {{ total }} 条任务</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无盘点任务">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column label="任务编号" width="160">
          <template slot-scope="s"><span class="link-blue" @click="openExecute(s.row)">{{ s.row.task_no }}</span></template>
        </el-table-column>
        <el-table-column label="关联计划" width="150">
          <template slot-scope="s"><span class="link-blue" @click="$router.push(`/warehouse/check/plan/detail/${s.row.plan_id}`)">{{ s.row.plan_no }}</span></template>
        </el-table-column>
        <el-table-column prop="location_name" label="货位" min-width="120" />
        <el-table-column prop="material_count" label="物料数" width="80" align="center" />
        <el-table-column label="已盘点" width="90" align="center">
          <template slot-scope="s">{{ s.row.completed_count }}/{{ s.row.material_count }}</template>
        </el-table-column>
        <el-table-column label="进度" width="150">
          <template slot-scope="s">
            <el-progress :percentage="s.row.progress" :stroke-width="10" :color="progressColor(s.row.progress)" />
          </template>
        </el-table-column>
        <el-table-column label="任务状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="expected_time" label="预计时间" width="200" />
        <el-table-column label="操作" width="160" align="center" fixed="right">
          <template slot-scope="s">
            <el-button v-if="s.row.status !== 2 && s.row.status !== 3" v-permission="'warehouse:check:execute:execute'" type="text" size="mini" @click="openExecute(s.row)">{{ s.row.status === 0 ? '开始盘点' : '继续盘点' }}</el-button>
            <el-button type="text" size="mini" @click="openExecute(s.row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </template>

    <!-- ================= 视图二：执行盘点 ================= -->
    <template v-else>
      <div class="page-header">
        <span class="page-title">盘点执行 - {{ currentTask.task_no }}</span>
        <div class="header-right">
          <el-button size="small" @click="backToList">返回列表</el-button>
        </div>
      </div>

      <el-card class="info-card" shadow="never">
        <div slot="header" class="card-header">
          <span>盘点任务信息</span>
          <el-tag :type="currentTask.status_tag" size="mini">{{ currentTask.status_label }}</el-tag>
        </div>
        <el-descriptions :column="3" border size="small">
          <el-descriptions-item label="任务编号">{{ currentTask.task_no }}</el-descriptions-item>
          <el-descriptions-item label="关联计划">{{ currentTask.plan_no }}</el-descriptions-item>
          <el-descriptions-item label="盘点仓库">{{ planInfo.warehouse_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="货位名称">{{ currentTask.location_name }}</el-descriptions-item>
          <el-descriptions-item label="盘点方式">{{ planInfo.inventory_method_label || '-' }}</el-descriptions-item>
          <el-descriptions-item label="物料总数">{{ totalCount }}</el-descriptions-item>
          <el-descriptions-item label="已盘点">{{ doneCount }}</el-descriptions-item>
          <el-descriptions-item label="未盘点">{{ totalCount - doneCount }}</el-descriptions-item>
          <el-descriptions-item label="任务状态">{{ currentTask.status_label }}</el-descriptions-item>
          <el-descriptions-item label="预计开始">{{ currentTask.expected_start_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="预计结束">{{ currentTask.expected_end_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ planInfo.responsible_person_name || '-' }}</el-descriptions-item>
        </el-descriptions>
        <el-progress class="task-progress" :percentage="progress" :stroke-width="14" :color="progressColor(progress)" />
      </el-card>

      <div class="scan-bar">
        <el-input v-model="scanInput" size="small" placeholder="扫码或输入物料编码/名称，按回车快速定位" clearable style="width:360px" @keyup.enter.native="handleScan">
          <i slot="prefix" class="el-input__icon el-icon-full-screen" />
        </el-input>
        <el-radio-group v-model="filterType" size="small" class="filter-group">
          <el-radio-button label="all">全部</el-radio-button>
          <el-radio-button label="done">已盘</el-radio-button>
          <el-radio-button label="undone">未盘</el-radio-button>
          <el-radio-button label="diff">有差异</el-radio-button>
        </el-radio-group>
        <el-select v-model="sortType" size="small" style="width:130px">
          <el-option label="按物料编码" value="code" />
          <el-option label="按物料名称" value="name" />
          <el-option label="按盘点状态" value="status" />
        </el-select>
        <el-button size="small" icon="el-icon-edit" @click="batchVisible = true">批量录入</el-button>
      </div>

      <el-table :data="filteredMaterials" v-loading="detailLoading" size="small" border class="mat-table">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="130" />
        <el-table-column prop="material_name" label="物料名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" />
        <el-table-column prop="unit" label="单位" width="70" align="center" />
        <el-table-column prop="location_name" label="货位" width="110" />
        <el-table-column v-if="planInfo.inventory_method === 1" prop="system_quantity" label="系统库存" width="100" align="center" />
        <el-table-column label="实盘数量" width="130">
          <template slot-scope="s">
            <el-input-number v-model="s.row.actual_quantity" :min="0" :precision="2" :controls="false" size="mini" style="width:100%" placeholder="录入" @change="onQtyChange(s.row)" />
          </template>
        </el-table-column>
        <el-table-column v-if="planInfo.inventory_method === 1" label="差异" width="100" align="center">
          <template slot-scope="s">
            <span :class="s.row.difference_quantity > 0 ? 'diff-plus' : (s.row.difference_quantity < 0 ? 'diff-minus' : 'diff-zero')">{{ s.row.actual_quantity !== null && s.row.actual_quantity !== undefined ? s.row.difference_quantity : '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column v-if="planInfo.inventory_method === 1" label="差异类型" width="90" align="center">
          <template slot-scope="s">
            <el-tag v-if="s.row.actual_quantity !== null && s.row.actual_quantity !== undefined" :type="diffTag(s.row.difference_type)" size="mini">{{ ['', '盘盈', '盘亏', '无差异'][s.row.difference_type] || '-' }}</el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="盘点状态" width="90" align="center">
          <template slot-scope="s">
            <el-tag :type="s.row.actual_quantity !== null && s.row.actual_quantity !== undefined ? 'success' : 'info'" size="mini">{{ s.row.actual_quantity !== null && s.row.actual_quantity !== undefined ? '已盘点' : '待盘点' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="备注" width="140">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="mini" placeholder="备注" /></template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" class="danger-text" @click="clearRow(s.row)">清除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="bottom-bar">
        <el-button size="small" :loading="saving" @click="handleSaveDraft">保存草稿</el-button>
        <el-button v-permission="'warehouse:check:execute:submit'" size="small" type="primary" :loading="submitting" @click="handleSubmit">提交盘点</el-button>
        <el-button size="small" @click="backToList">返回列表</el-button>
      </div>

      <!-- 批量录入 -->
      <el-dialog title="批量录入" :visible.sync="batchVisible" width="420px" append-to-body>
        <el-form label-width="90px" size="small">
          <el-form-item label="实盘数量">
            <el-input-number v-model="batchQty" :min="0" :precision="2" style="width:100%" />
          </el-form-item>
          <el-form-item label="应用范围">
            <span class="tip-text">将批量应用到全部未盘点物料</span>
          </el-form-item>
        </el-form>
        <div slot="footer">
          <el-button size="small" @click="batchVisible = false">取消</el-button>
          <el-button size="small" type="primary" @click="applyBatch">应用</el-button>
        </div>
      </el-dialog>
    </template>
  </div>
</template>

<script>
import { getExecuteTasks, getExecuteTaskDetail, saveExecuteDraft, submitExecuteTask, exportExecuteTasks } from '@/api/warehouse'

export default {
  name: 'InventoryExecute',
  data () {
    return {
      statusOptions: { 0: '待执行', 1: '执行中', 2: '已完成', 3: '已逾期' },
      statCards: [
        { key: 'pending', label: '待执行', icon: 'el-icon-time' },
        { key: 'processing', label: '执行中', icon: 'el-icon-loading' },
        { key: 'done', label: '已完成', icon: 'el-icon-check' },
        { key: 'overdue', label: '已逾期', icon: 'el-icon-warning' }
      ],
      viewMode: 'list',
      query: { task_no: '', plan_no: '', location_name: '', status: '' },
      cardStatus: '',
      stats: { pending: 0, processing: 0, done: 0, overdue: 0 },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      // 执行视图
      currentTask: {}, planInfo: {}, materials: [], detailLoading: false,
      scanInput: '', filterType: 'all', sortType: 'code',
      saving: false, submitting: false,
      batchVisible: false, batchQty: 1
    }
  },
  computed: {
    totalCount () { return this.materials.length },
    doneCount () { return this.materials.filter(m => m.actual_quantity !== null && m.actual_quantity !== undefined).length },
    progress () { return this.totalCount > 0 ? Math.round(this.doneCount / this.totalCount * 100) : 0 },
    filteredMaterials () {
      let arr = this.materials.slice()
      if (this.filterType === 'done') arr = arr.filter(m => m.actual_quantity !== null && m.actual_quantity !== undefined)
      else if (this.filterType === 'undone') arr = arr.filter(m => m.actual_quantity === null || m.actual_quantity === undefined)
      else if (this.filterType === 'diff') arr = arr.filter(m => m.actual_quantity !== null && m.actual_quantity !== undefined && m.difference_quantity !== 0)
      const key = this.sortType === 'name' ? 'material_name' : 'material_code'
      arr.sort((a, b) => String(a[key] || '').localeCompare(String(b[key] || '')))
      return arr
    }
  },
  created () { this.loadData() },
  methods: {
    progressColor (p) { return p < 30 ? '#909399' : (p < 70 ? '#E6A23C' : '#67C23A') },
    diffTag (t) { return Number(t) === 1 ? 'success' : (Number(t) === 2 ? 'danger' : 'info') },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.task_no) p.task_no = this.query.task_no
      if (this.query.plan_no) p.plan_no = this.query.plan_no
      if (this.query.location_name) p.location_name = this.query.location_name
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.cardStatus) p.status = this.cardStatus
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getExecuteTasks(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || { pending: 0, processing: 0, done: 0, overdue: 0 }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.cardStatus = ''; this.page = 1; this.loadData() },
    handleReset () { this.query = { task_no: '', plan_no: '', location_name: '', status: '' }; this.cardStatus = ''; this.page = 1; this.loadData() },
    handleCardFilter (key) {
      const map = { pending: '0', processing: '1', done: '2', overdue: '3' }
      this.cardStatus = this.cardStatus === map[key] ? '' : map[key]
      this.page = 1
      this.loadData()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    async openExecute (row) {
      this.detailLoading = true
      this.viewMode = 'execute'
      try {
        const r = await getExecuteTaskDetail(row.id)
        if (r.code === 0 && r.data) {
          this.currentTask = r.data.task || {}
          this.planInfo = r.data.plan || {}
          this.materials = (r.data.materials || []).map(m => ({ ...m, actual_quantity: m.actual_quantity !== null ? Number(m.actual_quantity) : null }))
        }
      } catch (e) {} finally { this.detailLoading = false }
    },
    backToList () {
      const dirty = this.materials.some(m => m.actual_quantity !== null && m.actual_quantity !== undefined)
      if (dirty) {
        this.$confirm('有未保存的盘点数据，确认返回列表吗？', '提示', { type: 'warning' }).then(() => { this.viewMode = 'list'; this.loadData() }).catch(() => {})
      } else {
        this.viewMode = 'list'
        this.loadData()
      }
    },
    onQtyChange (row) {
      if (row.actual_quantity === null || row.actual_quantity === undefined) return
      row.difference_quantity = Math.round((row.actual_quantity - row.system_quantity) * 10000) / 10000
      row.difference_type = row.difference_quantity > 0 ? 1 : (row.difference_quantity < 0 ? 2 : 3)
    },
    handleScan () {
      const kw = this.scanInput.trim()
      if (!kw) return
      const row = this.materials.find(m => m.material_code === kw || m.material_name === kw || (m.material_name || '').includes(kw) || (m.material_code || '').includes(kw))
      if (row) {
        this.$message.success('已定位：' + row.material_name)
        this.scanInput = ''
      } else {
        this.$message.warning('未找到该物料')
      }
    },
    clearRow (row) { row.actual_quantity = null; row.remark = ''; row.difference_quantity = null; row.difference_type = 3 },
    applyBatch () {
      this.materials.forEach(m => {
        if (m.actual_quantity === null || m.actual_quantity === undefined) {
          m.actual_quantity = this.batchQty
          this.onQtyChange(m)
        }
      })
      this.batchVisible = false
      this.$message.success('批量录入完成')
    },
    buildItems () {
      return this.materials.map(m => ({ material_id: m.id, actual_quantity: m.actual_quantity, remark: m.remark || '' }))
    },
    handleSaveDraft () {
      this.saving = true
      saveExecuteDraft({ task_id: this.currentTask.id, items: this.buildItems() }).then(r => {
        if (r.code === 0) { this.$message.success('草稿已保存'); this.loadData() } else this.$message.error(r.msg || '保存失败')
      }).catch(() => {}).finally(() => { this.saving = false })
    },
    handleSubmit () {
      const missing = this.materials.filter(m => m.actual_quantity === null || m.actual_quantity === undefined)
      if (missing.length) { this.$message.error(`尚有 ${missing.length} 个物料未盘点，请全部盘点后再提交`); return }
      this.$confirm('确认提交盘点数据吗？提交后不可再修改', '提交盘点', { type: 'warning' }).then(() => {
        this.submitting = true
        submitExecuteTask(this.currentTask.id, { items: this.buildItems() }).then(r => {
          if (r.code === 0) { this.$message.success('盘点已提交'); this.viewMode = 'list'; this.loadData() } else this.$message.error(r.msg || '提交失败')
        }).catch(() => {}).finally(() => { this.submitting = false })
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const response = await exportExecuteTasks(this.buildParams())
        const url = URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.download = '盘点任务_' + new Date().toISOString().slice(0, 19).replace(/[-:T]/g, '') + '.xlsx'
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
.stat-pending { background: linear-gradient(135deg,#f4f4f5,#e9e9eb); }
.stat-processing { background: linear-gradient(135deg,#fff7e6,#ffe7ba); }
.stat-done { background: linear-gradient(135deg,#f0f9eb,#e1f3d8); }
.stat-overdue { background: linear-gradient(135deg,#fef0f0,#fde2e2); }
.stat-icon { font-size: 34px; color: #909399; margin-right: 14px; }
.stat-num { font-size: 26px; font-weight: 700; line-height: 1.1; }
.num-pending { color: #909399; } .num-processing { color: #E6A23C; }
.num-done { color: #67C23A; } .num-overdue { color: #F56C6C; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 16px 20px; border-radius: 8px; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 600; color: #303133; }
.info-card { margin-bottom: 14px; border-radius: 8px; }
.card-header { display: flex; justify-content: space-between; align-items: center; font-weight: 600; }
.task-progress { margin-top: 14px; }
.scan-bar { display: flex; align-items: center; gap: 12px; background: #fff; padding: 12px 16px; border-radius: 8px; margin-bottom: 10px; }
.filter-group { flex-shrink: 0; }
.mat-table { margin-bottom: 14px; }
.bottom-bar { background: #fff; padding: 14px 16px; border-radius: 8px; display: flex; gap: 10px; position: sticky; bottom: 0; box-shadow: 0 -2px 10px rgba(0,0,0,0.05); }
.diff-plus { color: #67C23A; font-weight: 600; }
.diff-minus { color: #F56C6C; font-weight: 600; }
.diff-zero { color: #909399; }
.danger-text { color: #F56C6C; }
.tip-text { color: #909399; font-size: 12px; }
</style>
