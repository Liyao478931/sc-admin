<!--
  文件：admin/src/views/business/purchase/request/List.vue
  功能：采购申请管理列表（搜索/分页/导出/审批流转/来源追溯/执行进度）
  权限：business:purchase:request:list/add/edit/delete/export/approve + order:add
-->
<template>
  <div class="purchase-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购申请</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="申请编号">
          <el-input v-model="q.request_code" placeholder="请输入申请编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="申请标题">
          <el-input v-model="q.title" placeholder="请输入申请标题" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="申请部门">
          <el-select v-model="q.department_id" placeholder="全部" clearable style="width:130px" @change="handleSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请类型">
          <el-select v-model="q.request_type" placeholder="全部" clearable style="width:120px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="日常采购" value="1" /><el-option label="项目采购" value="2" /><el-option label="紧急采购" value="3" /><el-option label="备品备件" value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源类型">
          <el-select v-model="q.source_type" placeholder="全部来源" clearable style="width:140px" @change="handleSearch">
            <el-option label="全部来源" value="" /><el-option label="手动创建" value="1" /><el-option label="销售订单" value="2" /><el-option label="维修订单" value="3" /><el-option label="生产工单" value="4" /><el-option label="库存补货" value="5" /><el-option label="消耗品补充" value="6" /><el-option label="项目采购" value="7" /><el-option label="计划采购" value="8" /><el-option label="紧急采购" value="9" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批状态">
          <el-select v-model="q.approval_status" placeholder="全部" clearable style="width:130px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="草稿" value="0" />
            <el-option :label="'待审批(' + (statusCounts['1'] || 0) + ')'" value="1" />
            <el-option label="已审批" value="2" />
            <el-option label="已驳回" value="3" />
            <el-option label="已撤销" value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="执行状态">
          <el-select v-model="q.execution_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="待执行" value="0" /><el-option label="部分执行" value="1" /><el-option label="全部执行" value="2" /><el-option label="全部入库" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="合同状态">
          <el-select v-model="q.contract_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="未签约" value="0" /><el-option label="已签约" value="1" /><el-option label="已生效" value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="紧急程度">
          <el-select v-model="q.urgency" placeholder="全部" clearable style="width:100px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="普通" value="1" /><el-option label="紧急" value="2" /><el-option label="特急" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:purchase:request:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增申请</el-button>
        <el-button v-permission="'business:purchase:request:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无采购申请数据">
        <el-table-column type="index" label="序号" width="50" align="center" />
        <el-table-column prop="request_code" label="申请编号" width="140" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.request_code }}</span></template>
        </el-table-column>
        <el-table-column label="申请标题" min-width="170" show-overflow-tooltip>
          <template slot-scope="s">
            <el-tag v-if="s.row.urgency === 2" size="mini" type="warning" style="margin-right:4px">紧急</el-tag>
            <el-tag v-if="s.row.urgency === 3" size="mini" type="danger" style="margin-right:4px">特急</el-tag>
            <span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.title }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="department_name" label="申请部门" width="110" show-overflow-tooltip />
        <el-table-column prop="applicant_name" label="申请人" width="80" show-overflow-tooltip />
        <el-table-column label="申请类型" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="typeTag(s.row.request_type)">{{ s.row.request_type_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="来源" width="150" show-overflow-tooltip>
          <template slot-scope="s">
            <el-tag size="mini" :type="sourceTag(s.row.source_type)" class="source-tag" :class="{ 'source-link': s.row.source_type === 2 || s.row.source_type === 3 }" @click.native="viewSource(s.row)">{{ s.row.source_type_label }}</el-tag>
            <div v-if="s.row.source_no" class="source-no">{{ s.row.source_no }}</div>
          </template>
        </el-table-column>
        <el-table-column label="预算金额" width="100" align="right">
          <template slot-scope="s">¥ {{ s.row.budget_amount }}</template>
        </el-table-column>
        <el-table-column label="总金额" width="100" align="right">
          <template slot-scope="s">¥ {{ s.row.total_amount }}</template>
        </el-table-column>
        <el-table-column label="执行状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="execTag(s.row.execution_status)">{{ s.row.execution_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="合同" width="80" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="contractTag(s.row.contract_status)">{{ s.row.contract_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="紧急" width="70" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="urgencyTag(s.row.urgency)">{{ s.row.urgency_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="审批状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="approvalTag(s.row.approval_status)">{{ s.row.approval_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="request_date" label="申请日期" width="100" align="center" />
        <el-table-column label="期望交付" width="105" align="center">
          <template slot-scope="s">
            <span :class="{ 'date-overdue': s.row.expected_date && s.row.expected_date < today }">{{ s.row.expected_date || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="240" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
            <el-button v-if="s.row.approval_status === 0 || s.row.approval_status === 3" v-permission="'business:purchase:request:edit'" type="text" size="mini" @click="handleEdit(s.row.id)">编辑</el-button>
            <el-button v-if="s.row.approval_status === 0 || s.row.approval_status === 3" v-permission="'business:purchase:request:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row.id)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-if="s.row.approval_status === 0" v-permission="'business:purchase:request:add'" command="submit">提交审批</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 1" v-permission="'business:purchase:request:approve'" command="approve">审批通过</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 1" v-permission="'business:purchase:request:approve'" command="reject">审批驳回</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 1" command="cancel">撤销申请</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 2 && (s.row.execution_status === 0 || s.row.execution_status === 1)" v-permission="'business:purchase:order:add'" command="genorder">生成采购订单</el-dropdown-item>
                <el-dropdown-item command="copy">复制申请</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 2" command="tracking">查看执行进度</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="handlePageChange" @size-change="handleSizeChange" />
    </el-card>

    <!-- 执行进度弹窗 -->
    <el-dialog title="采购申请执行进度" :visible="trackingVisible" width="800px" :close-on-click-modal="false" @close="trackingVisible = false">
      <RequestTracking :tracking="trackingData" />
    </el-dialog>
  </div>
</template>

<script>
import RequestTracking from './components/RequestTracking.vue'
import {
  getRequestList, deleteRequest, submitRequest, cancelRequest, copyRequest, getRequestTracking,
  exportRequests, getDepartmentList, approveRequest, rejectRequest
} from '../../../../api/purchase'

export default {
  name: 'BusinessPurchaseRequestList',
  components: { RequestTracking },
  data() {
    return {
      loading: false,
      exporting: false,
      list: [],
      total: 0,
      deptOptions: [],
      statusCounts: {},
      dateRange: [],
      today: new Date().toISOString().slice(0, 10),
      q: { page: 1, pageSize: 10, request_code: '', title: '', department_id: '', request_type: '', source_type: '', approval_status: '', execution_status: '', contract_status: '', urgency: '', start_date: '', end_date: '' },
      trackingVisible: false,
      trackingData: null
    }
  },
  created() {
    this.loadDepts()
    this.getList()
  },
  methods: {
    typeTag(t) { return { 1: 'primary', 2: 'purple', 3: 'danger', 4: 'warning' }[t] || 'info' },
    sourceTag(t) { return { 1: 'info', 2: 'primary', 3: 'warning', 4: 'success', 5: 'info', 6: 'info', 7: 'purple', 8: 'primary', 9: 'danger' }[t] || 'info' },
    execTag(t) { return ['info', 'primary', 'success', 'success'][t] || 'info' },
    contractTag(t) { return ['info', 'warning', 'success'][t] || 'info' },
    urgencyTag(t) { return ['info', 'warning', 'danger'][t] || 'info' },
    approvalTag(t) { return ['info', 'warning', 'success', 'danger', 'info'][t] || 'info' },
    async loadDepts() {
      try {
        const r = await getDepartmentList()
        this.deptOptions = (r.code === 0 && Array.isArray(r.data)) ? r.data : []
      } catch (e) { this.deptOptions = [] }
    },
    buildParams() {
      const p = { ...this.q }
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] } else { p.start_date = ''; p.end_date = '' }
      return p
    },
    async getList() {
      this.loading = true
      try {
        const r = await getRequestList(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.statusCounts = r.data.status_counts || {}
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch() { this.q.page = 1; this.getList() },
    handleReset() {
      this.q = { page: 1, pageSize: this.q.pageSize, request_code: '', title: '', department_id: '', request_type: '', source_type: '', approval_status: '', execution_status: '', contract_status: '', urgency: '', start_date: '', end_date: '' }
      this.dateRange = []
      this.handleSearch()
    },
    handlePageChange(p) { this.q.page = p; this.getList() },
    handleSizeChange(size) { this.q.pageSize = size; this.q.page = 1; this.getList() },
    handleAdd() { this.$router.push('/business/purchase/request/add') },
    viewDetail(id) { this.$router.push(`/business/purchase/request/detail/${id}`) },
    handleEdit(id) { this.$router.push(`/business/purchase/request/edit/${id}`) },
    viewSource(row) {
      if (row.source_type === 2) this.$router.push('/business/order')
      else if (row.source_type === 3) this.$router.push({ path: '/business/order', query: { category: 'repair' } })
      else this.$message.info('该来源类型无跳转链接')
    },
    handleDelete(id) {
      this.$confirm('确认删除该采购申请吗？删除后不可恢复', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteRequest(id)
          if (r.code === 0) {
            this.$message.success('删除成功')
            await this.getList()
            if (!this.list.length && this.q.page > 1) { this.q.page -= 1; await this.getList() }
          }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleMore(cmd, row) {
      if (cmd === 'submit') {
        try {
          const r = await submitRequest(row.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.getList() }
        } catch (e) {}
      } else if (cmd === 'approve') {
        this.$prompt('请输入审批意见（选填）', '审批通过', { inputPlaceholder: '审批意见', confirmButtonText: '通过', cancelButtonText: '取消', inputValue: '同意' })
          .then(({ value }) => approveRequest(row.id, value || '同意'))
          .then((r) => {
            if (r.code === 0) { this.$message.success('已审批通过'); this.getList() } else this.$message.error(r.msg || '审批失败')
          }).catch(() => {})
      } else if (cmd === 'reject') {
        this.$prompt('请输入驳回原因', '审批驳回', { inputPlaceholder: '驳回原因', confirmButtonText: '驳回', cancelButtonText: '取消' })
          .then(({ value }) => {
            if (!value) { this.$message.warning('请填写驳回原因'); return Promise.reject('empty') }
            return rejectRequest(row.id, value)
          })
          .then((r) => {
            if (r.code === 0) { this.$message.success('已驳回'); this.getList() } else this.$message.error(r.msg || '驳回失败')
          }).catch(() => {})
      } else if (cmd === 'cancel') {
        this.$confirm('确认撤销该采购申请吗？撤销后需重新提交', '撤销确认', { type: 'warning' }).then(async () => {
          try {
            const r = await cancelRequest(row.id)
            if (r.code === 0) { this.$message.success('已撤销'); this.getList() }
          } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'genorder') {
        this.$router.push('/business/purchase/request/detail/' + row.id + '?genorder=1')
      } else if (cmd === 'copy') {
        try {
          const r = await copyRequest(row.id)
          if (r.code === 0 && r.data) {
            this.$router.push({ path: '/business/purchase/request/add', query: { copyFrom: JSON.stringify(r.data) } })
          }
        } catch (e) {}
      } else if (cmd === 'tracking') {
        try {
          const r = await getRequestTracking(row.id)
          if (r.code === 0) { this.trackingData = r.data; this.trackingVisible = true }
        } catch (e) {}
      }
    },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportRequests(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const filename = this.resolveName(res.headers) || '采购申请列表_' + this.stamp() + '.xlsx'
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
      this.exporting = false
    },
    resolveName(headers) {
      if (!headers) return null
      const d = headers['content-disposition'] || ''
      const star = d.match(/filename\*=(?:UTF-8'')?([^;]+)/i)
      if (star) return decodeURIComponent(star[1].replace(/^"|"$/g, ''))
      const plain = d.match(/filename="?([^";]+)"?/i)
      return plain ? plain[1] : null
    },
    stamp() {
      const n = new Date()
      const pad = x => String(x).padStart(2, '0')
      return `${n.getFullYear()}${pad(n.getMonth() + 1)}${pad(n.getDate())}_${pad(n.getHours())}${pad(n.getMinutes())}${pad(n.getSeconds())}`
    }
  }
}
</script>

<style scoped>
.purchase-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.filter-card { margin-bottom: 14px; }
.filter-btns { display: flex; align-items: center; margin-left: 8px; }
.filter-btns .el-button + .el-button { margin-left: 10px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link-text { color: #409eff; cursor: pointer; }
.source-tag { cursor: default; }
.source-link { cursor: pointer; }
.source-no { font-size: 11px; color: #909399; line-height: 1.6; }
.date-overdue { color: #f56c6c; }
.pager { margin: 20px 0; text-align: right; }
.danger { color: #f56c6c; }
::v-deep .el-tag--purple { background-color: #f3e5f5; border-color: #ce93d8; color: #8e24aa; }
</style>
