<!--
  文件：admin/src/views/production/plan/order/List.vue
  功能：工单列表（筛选/进度条/状态操作流：派工·开始·报工·质检·关闭/导出）
  权限：production:order:list:view 及各项操作权限
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产计划</el-breadcrumb-item>
      <el-breadcrumb-item>生产工单</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索与筛选区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="工单编号"><el-input v-model="query.order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="来源单据"><el-input v-model="query.source_no" placeholder="请输入来源单据编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品名称"><el-input v-model="query.product_name" placeholder="请输入产品名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单类型">
          <el-select v-model="query.order_type" clearable placeholder="全部" style="width:110px">
            <el-option label="生产工单" :value="1" />
            <el-option label="维修工单" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="工单状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级">
          <el-select v-model="query.priority" clearable placeholder="全部" style="width:100px">
            <el-option v-for="(t, v) in priorityOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联工序">
          <el-select v-model="query.process_id" clearable filterable placeholder="全部" style="width:130px">
            <el-option v-for="p in processOptions" :key="p.id" :label="p.process_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联工位">
          <el-select v-model="query.workstation_id" clearable filterable placeholder="全部" style="width:130px">
            <el-option v-for="w in workstationOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'production:order:create'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/production/plan/order/add')">新建工单</el-button>
        <el-button v-permission="'production:order:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <div class="toolbar-right">
        <span class="total-text">共 {{ total }} 条</span>
        <span class="total-text" style="margin-left:12px">
          待派工 <b style="color:#909399">{{ statusCounts[0] }}</b> / 已派工 <b style="color:#409EFF">{{ statusCounts[1] }}</b> /
          进行中 <b style="color:#E6A23C">{{ statusCounts[2] }}</b> / 待质检 <b style="color:#9B59B6">{{ statusCounts[3] }}</b> /
          已完成 <b style="color:#67C23A">{{ statusCounts[4] }}</b> / 已关闭 <b style="color:#909399">{{ statusCounts[5] }}</b>
        </span>
      </div>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无工单数据，请点击「新建工单」创建">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="工单编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.id}`)">{{ s.row.order_no }}</span></template>
      </el-table-column>
      <el-table-column label="工单类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.order_type_tag" size="mini">{{ s.row.order_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="source_no" label="来源单据" width="140" show-overflow-tooltip>
        <template slot-scope="s"><span v-if="s.row.source_no" class="source-no">{{ s.row.source_no }}</span><span v-else>-</span></template>
      </el-table-column>
      <el-table-column prop="product_name" label="产品名称" min-width="150" show-overflow-tooltip />
      <el-table-column prop="process_name" label="关联工序" width="110" show-overflow-tooltip>
        <template slot-scope="s"><span v-if="s.row.process_name">{{ s.row.process_name }}</span><span v-else>-</span></template>
      </el-table-column>
      <el-table-column prop="workstation_name" label="关联工位" width="110" show-overflow-tooltip>
        <template slot-scope="s"><span v-if="s.row.workstation_name">{{ s.row.workstation_name }}</span><span v-else>-</span></template>
      </el-table-column>
      <el-table-column label="计划数量" width="110" align="right"><template slot-scope="s">{{ fmt(s.row.plan_quantity) }}</template></el-table-column>
      <el-table-column label="完成数量" width="110" align="right"><template slot-scope="s">{{ fmt(s.row.completed_quantity) }}</template></el-table-column>
      <el-table-column label="进度" width="130">
        <template slot-scope="s">
          <div class="progress-cell">
            <el-progress :percentage="Number(s.row.progress)" :color="progressColor(s.row.progress)" :show-text="false" style="width:80px" />
            <span class="progress-text">{{ Number(s.row.progress) }}%</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="工单状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="优先级" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.priority_tag" size="mini">{{ s.row.priority_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="计划完成日期" width="120" align="center">
        <template slot-scope="s"><span :class="{ 'overdue': isOverdue(s.row) }">{{ s.row.planned_end_date || '-' }}</span></template>
      </el-table-column>
      <el-table-column prop="responsible_person_name" label="负责人" width="90" show-overflow-tooltip />
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$router.push(`/production/plan/order/detail/${s.row.id}`)">查看详情</el-button>
          <el-button v-if="s.row.status <= 1" v-permission="'production:order:edit'" type="text" size="mini" @click="$router.push(`/production/plan/order/edit/${s.row.id}`)">编辑</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'production:order:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="(cmd) => handleCommand(cmd, s.row)">
            <span class="el-dropdown-link">更多<i class="el-icon-arrow-down el-icon--right" /></span>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" v-permission="'production:order:dispatch'" command="dispatch">派工</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'production:order:dispatch'" command="start">开始生产</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'production:order:report'" command="report">报工</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2 && Number(s.row.progress) >= 100" v-permission="'production:order:quality'" command="applyQuality">申请质检</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 3" v-permission="'production:order:quality'" command="qualityPass">质检通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 3" v-permission="'production:order:quality'" command="qualityReject">质检驳回</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 4" v-permission="'production:order:close'" command="close">关闭工单</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 派工对话框 -->
    <el-dialog title="工单派工" :visible.sync="dispatchVisible" width="480px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="班组/部门">
          <el-select v-model="dispatchForm.department_id" filterable placeholder="请选择班组" style="width:100%" @change="onDeptChange">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="负责人">
          <el-select v-model="dispatchForm.responsible_person_id" filterable placeholder="请选择负责人" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="(u.real_name || u.username) + (u.department_id ? '（部门' + u.department_id + '）' : '')" :value="u.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dispatchVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="acting" @click="confirmDispatch">确认派工</el-button>
      </div>
    </el-dialog>

    <!-- 报工对话框 -->
    <el-dialog title="工单报工" :visible.sync="reportVisible" width="480px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="完成数量"><el-input-number v-model="reportForm.completed_quantity" :min="1" :max="currentRow.plan_quantity" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="reportForm.remark" type="textarea" :rows="3" placeholder="报工备注（可选）" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="reportVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="acting" @click="confirmReport">确认报工</el-button>
      </div>
    </el-dialog>

    <!-- 质检通过对话框 -->
    <el-dialog title="质检通过" :visible.sync="qualityPassVisible" width="480px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="质检结果"><el-input v-model="qualityPassForm.result" placeholder="合格/不合格（可选）" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="qualityPassForm.remark" type="textarea" :rows="3" placeholder="质检备注（可选）" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="qualityPassVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="acting" @click="confirmQualityPass">确认通过</el-button>
      </div>
    </el-dialog>

    <!-- 质检驳回对话框 -->
    <el-dialog title="质检驳回" :visible.sync="qualityRejectVisible" width="480px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="驳回原因"><el-input v-model="qualityRejectForm.reason" type="textarea" :rows="3" placeholder="必填，驳回原因" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="qualityRejectVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="acting" @click="confirmQualityReject">确认驳回</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getOrderList, deleteOrder, dispatchOrder, startOrder, reportOrder, applyQuality, qualityPass, qualityReject, closeOrder, exportOrder, getOrderUsers, getProcessList, getWorkstationList } from '@/api/production'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'ProductionOrderList',
  data () {
    return {
      statusOptions: { 0: '待派工', 1: '已派工', 2: '进行中', 3: '待质检', 4: '已完成', 5: '已关闭' },
      priorityOptions: { 1: '普通', 2: '紧急', 3: '特急' },
      query: { order_no: '', source_no: '', product_name: '', order_type: '', status: '', priority: '', process_id: '', workstation_id: '', dateRange: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, acting: false,
      statusCounts: { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
      processOptions: [], workstationOptions: [],
      deptOptions: [], userOptions: [],
      dispatchVisible: false, dispatchForm: { responsible_person_id: null, department_id: null },
      reportVisible: false, reportForm: { completed_quantity: 1, remark: '' },
      qualityPassVisible: false, qualityPassForm: { result: '', remark: '' },
      qualityRejectVisible: false, qualityRejectForm: { reason: '' },
      currentRow: {}
    }
  },
  created () {
    this.loadDepts()
    this.loadUsers()
    this.loadProcesses()
    this.loadWorkstations()
    this.loadData()
  },
  methods: {
    fmt (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    progressColor (p) { const v = Number(p); if (v < 30) return '#F56C6C'; if (v < 70) return '#E6A23C'; return '#67C23A' },
    isOverdue (row) {
      if (row.status >= 4 || !row.planned_end_date) return false
      const today = new Date()
      const end = new Date(row.planned_end_date)
      return end < new Date(today.getFullYear(), today.getMonth(), today.getDate())
    },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    async loadProcesses () {
      try { const r = await getProcessList({ page: 1, pageSize: 100, status: 1 }); if (r.code === 0) this.processOptions = r.data.list || [] } catch (e) { this.processOptions = [] }
    },
    async loadWorkstations () {
      try { const r = await getWorkstationList({ page: 1, pageSize: 100, status: 1 }); if (r.code === 0) this.workstationOptions = r.data.list || [] } catch (e) { this.workstationOptions = [] }
    },
    async loadUsers () {
      try {
        const r = await getOrderUsers()
        if (r.code === 0) this.userOptions = r.data.list || []
      } catch (e) { this.userOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.order_no) p.order_no = this.query.order_no
      if (this.query.source_no) p.source_no = this.query.source_no
      if (this.query.product_name) p.product_name = this.query.product_name
      if (this.query.order_type !== '' && this.query.order_type !== null) p.order_type = this.query.order_type
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.priority !== '' && this.query.priority !== null) p.priority = this.query.priority
      if (this.query.process_id !== '' && this.query.process_id !== null) p.process_id = this.query.process_id
      if (this.query.workstation_id !== '' && this.query.workstation_id !== null) p.workstation_id = this.query.workstation_id
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getOrderList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.statusCounts = r.data.status_counts || { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { order_no: '', source_no: '', product_name: '', order_type: '', status: '', priority: '', process_id: '', workstation_id: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleDelete (row) {
      this.$confirm('确认删除该工单吗？删除后不可恢复', '删除工单', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteOrder(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCommand (cmd, row) {
      this.currentRow = row
      if (cmd === 'dispatch') {
        this.dispatchForm = { responsible_person_id: null, department_id: null }
        this.dispatchVisible = true
      } else if (cmd === 'start') {
        this.$confirm(`确认开始生产工单 ${row.order_no} 吗？`, '开始生产', { type: 'warning' }).then(async () => {
          try { const r = await startOrder(row.id); if (r.code === 0) { this.$message.success('已开始生产'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'report') {
        this.reportForm = { completed_quantity: Number(row.completed_quantity) || 0, remark: '' }
        this.reportVisible = true
      } else if (cmd === 'applyQuality') {
        this.$confirm(`确认对工单 ${row.order_no} 申请质检吗？`, '申请质检', { type: 'warning' }).then(async () => {
          try { const r = await applyQuality(row.id); if (r.code === 0) { this.$message.success('已申请质检'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'qualityPass') {
        this.qualityPassForm = { result: '', remark: '' }
        this.qualityPassVisible = true
      } else if (cmd === 'qualityReject') {
        this.qualityRejectForm = { reason: '' }
        this.qualityRejectVisible = true
      } else if (cmd === 'close') {
        this.$confirm(`确认关闭工单 ${row.order_no} 吗？`, '关闭工单', { type: 'warning' }).then(async () => {
          try { const r = await closeOrder(row.id); if (r.code === 0) { this.$message.success('工单已关闭'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
        }).catch(() => {})
      }
    },
    onDeptChange (id) {
      // 部门变更后可过滤负责人（简单实现：仅提示）
    },
    async confirmDispatch () {
      if (!this.dispatchForm.department_id) { this.$message.warning('请选择班组/部门'); return }
      if (!this.dispatchForm.responsible_person_id) { this.$message.warning('请选择负责人'); return }
      this.acting = true
      try {
        const u = this.userOptions.find(x => x.id === this.dispatchForm.responsible_person_id)
        const d = this.deptOptions.find(x => x.id === this.dispatchForm.department_id)
        const r = await dispatchOrder(this.currentRow.id, {
          responsible_person_id: this.dispatchForm.responsible_person_id,
          responsible_person_name: u ? (u.real_name || u.username) : '',
          department_id: this.dispatchForm.department_id,
          department_name: d ? d.name : ''
        })
        if (r.code === 0) { this.$message.success('派工成功'); this.dispatchVisible = false; this.loadData() } else this.$message.error(r.msg || '派工失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmReport () {
      if (!this.reportForm.completed_quantity || this.reportForm.completed_quantity <= 0) { this.$message.warning('请填写完成数量'); return }
      this.acting = true
      try {
        const r = await reportOrder(this.currentRow.id, { completed_quantity: this.reportForm.completed_quantity, remark: this.reportForm.remark })
        if (r.code === 0) { this.$message.success(r.msg || '报工成功'); this.reportVisible = false; this.loadData() } else this.$message.error(r.msg || '报工失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmQualityPass () {
      this.acting = true
      try {
        const r = await qualityPass(this.currentRow.id, { result: this.qualityPassForm.result, remark: this.qualityPassForm.remark })
        if (r.code === 0) { this.$message.success('质检通过'); this.qualityPassVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmQualityReject () {
      if (!this.qualityRejectForm.reason) { this.$message.warning('请填写驳回原因'); return }
      this.acting = true
      try {
        const r = await qualityReject(this.currentRow.id, { reason: this.qualityRejectForm.reason })
        if (r.code === 0) { this.$message.success('已驳回'); this.qualityRejectVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        delete params.page
        delete params.pageSize
        const r = await exportOrder(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          const d = new Date()
          const pad = n => String(n).padStart(2, '0')
          a.href = url
          a.download = `工单列表_${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.toolbar-right { display: flex; align-items: center; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.source-no { color: #409EFF; }
.progress-cell { display: flex; align-items: center; gap: 6px; }
.progress-text { font-size: 12px; color: #606266; }
.overdue { color: #F56C6C; font-weight: 600; }
.danger-text { color: #F56C6C; }
.el-dropdown-link { cursor: pointer; color: #409EFF; font-size: 13px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
