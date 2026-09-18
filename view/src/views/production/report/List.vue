<!--
  文件：admin/src/views/production/report/List.vue
  功能：生产报工列表（筛选/状态操作流：提交·审核通过·驳回·撤销/导出）
  权限：production:report:view 及各项操作权限
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>报工记录</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索与筛选区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="报工单编号"><el-input v-model="query.report_no" placeholder="请输入报工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单编号"><el-input v-model="query.work_order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="报工人"><el-input v-model="query.reporter_name" placeholder="请输入报工人姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="任务类型">
          <el-select v-model="query.task_type" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in taskOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="报工状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="关联设备">
          <el-select v-model="query.device_id" clearable filterable placeholder="全部" style="width:150px">
            <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.name}（${d.device_code}）`" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="材料/配件">
          <el-select v-model="query.material_id" clearable filterable placeholder="全部" style="width:150px">
            <el-option v-for="m in materialOptions" :key="m.id" :label="m.material_name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="报工日期">
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
        <el-button v-permission="'production:report:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/production/report/add')">新增报工</el-button>
        <el-button v-permission="'production:report:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <div class="toolbar-right">
        <span class="total-text">共 {{ total }} 条</span>
        <span class="total-text" style="margin-left:12px">
          草稿 <b style="color:#909399">{{ statusCounts[0] }}</b> / 待审核 <b style="color:#E6A23C">{{ statusCounts[1] }}</b> /
          已通过 <b style="color:#67C23A">{{ statusCounts[2] }}</b> / 已驳回 <b style="color:#F56C6C">{{ statusCounts[3] }}</b> /
          已撤销 <b style="color:#909399">{{ statusCounts[4] }}</b>
        </span>
      </div>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无报工数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="报工单编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/report/detail/${s.row.id}`)">{{ s.row.report_no }}</span></template>
      </el-table-column>
      <el-table-column label="关联工单" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.work_order_id}`)">{{ s.row.work_order_no }}</span></template>
      </el-table-column>
      <el-table-column prop="reporter_name" label="报工人" width="90" />
      <el-table-column label="报工模式" width="100" align="center">
        <template slot-scope="s"><el-tag :type="tagType(s.row.report_type_tag)" :class="{ 'tag-purple': s.row.report_type_tag === 'purple' }" size="mini">{{ s.row.report_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="任务类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="tagType(s.row.task_type_tag)" :class="{ 'tag-purple': s.row.task_type_tag === 'purple' }" size="mini">{{ s.row.task_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="workstation_name" label="关联工位" width="100" show-overflow-tooltip />
      <el-table-column prop="device_name" label="关联设备" width="130" show-overflow-tooltip />
      <el-table-column label="完成数量" width="80" align="center"><template slot-scope="s">{{ s.row.quantity || 1 }}</template></el-table-column>
      <el-table-column label="设备工时" width="80" align="right"><template slot-scope="s">{{ Number(s.row.duration || 0) }} h</template></el-table-column>
      <el-table-column label="工分" width="80" align="right"><template slot-scope="s">{{ Number(s.row.calculated_score || 0) }}</template></el-table-column>
      <el-table-column label="总工分" width="90" align="right"><template slot-scope="s"><b>{{ Number(s.row.total_score) }}</b></template></el-table-column>
      <el-table-column prop="report_date" label="报工日期" width="110" align="center" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="250" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$router.push(`/production/report/detail/${s.row.id}`)">查看详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'production:report:edit'" type="text" size="mini" @click="$router.push(`/production/report/edit/${s.row.id}`)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'production:report:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="(cmd) => handleCommand(cmd, s.row)">
            <span class="el-dropdown-link">更多<i class="el-icon-arrow-down el-icon--right" /></span>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" v-permission="'production:report:edit'" command="submit">提交审核</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'production:report:audit'" command="approve">审核通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'production:report:audit'" command="reject">审核驳回</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" v-permission="'production:report:edit'" command="cancel">撤销</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 审核通过对话框 -->
    <el-dialog title="审核通过" :visible.sync="approveVisible" width="560px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="报工单信息">
          <div class="audit-summary">
            {{ currentRow.report_no }} ｜ {{ currentRow.reporter_name }} ｜ 总工分 {{ Number(currentRow.total_score) }} ｜ {{ currentRow.task_description || '-' }}
          </div>
        </el-form-item>
        <el-form-item label="总工分">
          <el-input-number v-model="approveForm.total_score" :min="0.01" :precision="2" style="width:100%" @change="onApproveTotalChange" />
        </el-form-item>
        <el-form-item v-if="currentRow.report_type === 2" label="分配明细">
          <el-table :data="approveForm.items" size="mini" border>
            <el-table-column prop="worker_name" label="成员" />
            <el-table-column label="分配工分" width="160">
              <template slot-scope="s"><el-input-number v-model="s.row.allocated_score" :min="0.01" :precision="2" size="mini" style="width:100%" @change="onApproveItemsChange" /></template>
            </el-table-column>
          </el-table>
          <div v-if="approveBalanceTip" class="balance-warn">{{ approveBalanceTip }}</div>
        </el-form-item>
        <el-form-item label="审核备注"><el-input v-model="approveForm.audit_remark" type="textarea" :rows="3" placeholder="请输入审核备注（可选）" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="approveVisible = false">取消</el-button>
        <el-button size="small" type="success" :loading="acting" @click="confirmApprove">确认通过</el-button>
      </div>
    </el-dialog>

    <!-- 审核驳回对话框 -->
    <el-dialog title="审核驳回" :visible.sync="rejectVisible" width="500px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="报工单信息">
          <div class="audit-summary">{{ currentRow.report_no }} ｜ {{ currentRow.reporter_name }} ｜ 总工分 {{ Number(currentRow.total_score) }}</div>
        </el-form-item>
        <el-form-item label="驳回原因"><el-input v-model="rejectForm.reason" type="textarea" :rows="4" placeholder="请详细填写驳回原因，以便报工人了解问题" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="rejectVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="acting" @click="confirmReject">确认驳回</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getReportList, deleteReport, submitReport, approveReport, rejectReport, cancelReport, exportReport, getReportDetail, getWsDeviceOptions, getOrderMaterials } from '@/api/production'

export default {
  name: 'ProductionReportList',
  data () {
    return {
      statusOptions: { 0: '草稿', 1: '待审核', 2: '已通过', 3: '已驳回', 4: '已撤销' },
      taskOptions: { 1: '拆解', 2: '焊接', 3: '维修', 4: '组装', 5: '喷漆', 6: '质检', 7: '其他' },
      query: { report_no: '', work_order_no: '', reporter_name: '', task_type: '', status: '', device_id: '', material_id: '', dateRange: [] },
      list: [], total: 0, statusCounts: { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0 }, page: 1, pageSize: 10, loading: false, exporting: false, acting: false,
      deviceOptions: [], materialOptions: [],
      approveVisible: false, approveForm: { total_score: 0, items: [], audit_remark: '' },
      rejectVisible: false, rejectForm: { reason: '' },
      currentRow: {}
    }
  },
  computed: {
    approveBalanceTip () {
      if (this.currentRow.report_type !== 2) return ''
      const sum = this.approveForm.items.reduce((s, i) => s + Number(i.allocated_score || 0), 0)
      if (Math.abs(sum - Number(this.approveForm.total_score)) > 0.001) return `分配工分合计（${sum}）与总工分（${this.approveForm.total_score}）不一致，请调整`
      return ''
    }
  },
  created () { this.loadDevices(); this.loadMaterials(); this.loadData() },
  methods: {
    async loadDevices () { try { const r = await getWsDeviceOptions(); if (r.code === 0) this.deviceOptions = r.data.list || [] } catch (e) { this.deviceOptions = [] } },
    async loadMaterials () { try { const r = await getOrderMaterials(); if (r.code === 0) this.materialOptions = r.data.list || [] } catch (e) { this.materialOptions = [] } },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.report_no) p.report_no = this.query.report_no
      if (this.query.work_order_no) p.work_order_no = this.query.work_order_no
      if (this.query.reporter_name) p.reporter_name = this.query.reporter_name
      if (this.query.task_type !== '' && this.query.task_type !== null) p.task_type = this.query.task_type
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.device_id !== '' && this.query.device_id !== null) p.device_id = this.query.device_id
      if (this.query.material_id !== '' && this.query.material_id !== null) p.material_id = this.query.material_id
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getReportList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.statusCounts = r.data.status_counts || { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0 }
        }
      } catch (e) {} finally { this.loading = false }
    },
    tagType (t) { return t === 'purple' ? 'info' : t },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { report_no: '', work_order_no: '', reporter_name: '', task_type: '', status: '', device_id: '', material_id: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleDelete (row) {
      this.$confirm('确认删除该报工单吗？删除后不可恢复', '删除报工', { type: 'warning' }).then(async () => {
        try { const r = await deleteReport(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败') } catch (e) {}
      }).catch(() => {})
    },
    handleCommand (cmd, row) {
      this.currentRow = row
      if (cmd === 'submit') {
        this.$confirm('确认提交该报工单审核吗？', '提交审核', { type: 'warning' }).then(async () => {
          try { const r = await submitReport(row.id); if (r.code === 0) { this.$message.success('已提交审核'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'approve') {
        this.openApprove(row)
      } else if (cmd === 'reject') {
        this.rejectForm = { reason: '' }
        this.rejectVisible = true
      } else if (cmd === 'cancel') {
        this.$confirm('确认撤销该报工单吗？', '撤销报工', { type: 'warning' }).then(async () => {
          try { const r = await cancelReport(row.id); if (r.code === 0) { this.$message.success('已撤销'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
        }).catch(() => {})
      }
    },
    async openApprove (row) {
      this.approveVisible = true
      this.approveForm = { total_score: Number(row.total_score) || 0, items: [], audit_remark: '' }
      try {
        const r = await getReportDetail(row.id)
        if (r.code === 0 && r.data) {
          this.approveForm.items = (r.data.items || []).map(i => ({ ...i }))
        }
      } catch (e) {}
    },
    onApproveTotalChange () {},
    onApproveItemsChange () {},
    async confirmApprove () {
      if (this.currentRow.report_type === 2 && this.approveBalanceTip) { this.$message.warning(this.approveBalanceTip); return }
      this.acting = true
      try {
        const data = { total_score: this.approveForm.total_score, audit_remark: this.approveForm.audit_remark }
        if (this.currentRow.report_type === 2) data.items = this.approveForm.items
        const r = await approveReport(this.currentRow.id, data)
        if (r.code === 0) { this.$message.success(r.msg || '审核通过'); this.approveVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmReject () {
      if (!this.rejectForm.reason) { this.$message.warning('请填写驳回原因'); return }
      this.acting = true
      try {
        const r = await rejectReport(this.currentRow.id, { reason: this.rejectForm.reason })
        if (r.code === 0) { this.$message.success('已驳回并通知报工人'); this.rejectVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        delete params.page
        delete params.pageSize
        const r = await exportReport(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          const d = new Date()
          const pad = n => String(n).padStart(2, '0')
          a.href = url
          a.download = `报工列表_${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}.xlsx`
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
.tag-purple { background: #f5ecfb; color: #9B59B6; border-color: #ecd9f7; }
.audit-summary { font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.el-dropdown-link { cursor: pointer; color: #409EFF; font-size: 13px; }
.balance-warn { color: #F56C6C; font-size: 12px; margin-top: 6px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
