<!--
  文件：admin/src/views/business/purchase/request/Detail.vue
  功能：采购申请详情（信息卡 + 明细 + 执行进度；按状态显示操作按钮）
  权限：页面 business:purchase:request:list；编辑 edit；提交 add；生成订单 order:add
-->
<template>
  <div class="request-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购申请</el-breadcrumb-item>
      <el-breadcrumb-item>申请详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">采购申请详情 - {{ req.title || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/purchase/request/list')">返回列表</el-button>
        <el-button v-if="req.approval_status === 0 || req.approval_status === 3" v-permission="'business:purchase:request:edit'" type="primary" size="small" @click="$router.push(`/business/purchase/request/edit/${id}`)">编辑</el-button>
        <el-button v-if="req.approval_status === 0" v-permission="'business:purchase:request:add'" type="primary" size="small" :loading="submitting" @click="handleSubmit">提交审批</el-button>
        <el-button v-if="req.approval_status === 1" v-permission="'business:purchase:request:approve'" type="success" size="small" @click="handleApprove">审批通过</el-button>
        <el-button v-if="req.approval_status === 1" v-permission="'business:purchase:request:approve'" type="danger" size="small" @click="handleReject">审批驳回</el-button>
        <el-button v-if="req.approval_status === 1" type="danger" size="small" plain @click="handleCancel">撤销</el-button>
        <el-button v-if="req.approval_status === 2 && (req.execution_status === 0 || req.execution_status === 1)" v-permission="'business:purchase:order:add'" type="primary" size="small" @click="handleGenOrder">生成采购订单</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="$router.push('/business/purchase/request/list')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="req.id">
        <!-- 申请信息 -->
        <div class="section-title">申请信息</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="申请编号">{{ req.request_code }}</el-descriptions-item>
          <el-descriptions-item label="申请标题">{{ req.title }}</el-descriptions-item>
          <el-descriptions-item label="申请类型"><el-tag size="mini" :type="typeTag(req.request_type)">{{ req.request_type_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="申请部门">{{ req.department_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="申请人">{{ req.applicant_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="申请日期">{{ req.request_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="来源类型"><el-tag size="mini" :type="sourceTag(req.source_type)">{{ req.source_type_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="来源单号">
            <span v-if="req.source_no" class="link-text" @click="viewSource">{{ req.source_no }}</span>
            <span v-else>-</span>
          </el-descriptions-item>
          <el-descriptions-item label="紧急程度"><el-tag size="mini" :type="urgencyTag(req.urgency)">{{ req.urgency_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="预算科目">{{ req.budget_subject || '-' }}</el-descriptions-item>
          <el-descriptions-item label="预算金额">¥ {{ req.budget_amount }}</el-descriptions-item>
          <el-descriptions-item label="明细总金额">¥ {{ totalAmount }}</el-descriptions-item>
          <el-descriptions-item label="审批状态"><el-tag size="mini" :type="approvalTag(req.approval_status)">{{ req.approval_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="执行状态"><el-tag size="mini" :type="execTag(req.execution_status)">{{ req.execution_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="合同状态"><el-tag size="mini" :type="contractTag(req.contract_status)">{{ req.contract_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="期望交付日期">{{ req.expected_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="用途说明" :span="2">{{ req.purpose || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审批人">{{ req.approver_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审批日期">{{ req.approval_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审批备注" :span="2">{{ req.approval_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ req.remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ req.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ req.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ req.update_time || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 采购明细 -->
        <div class="section-title">采购明细</div>
        <el-table :data="items" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column prop="product_code" label="产品编码" width="120" show-overflow-tooltip />
          <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格型号" width="110" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="60" align="center" />
          <el-table-column prop="quantity" label="申请数量" width="80" align="right" />
          <el-table-column prop="ordered_quantity" label="已下单" width="80" align="right" />
          <el-table-column label="采购单价" width="100" align="right">
            <template slot-scope="s">¥ {{ s.row.unit_price }}</template>
          </el-table-column>
          <el-table-column label="总价" width="100" align="right">
            <template slot-scope="s">¥ {{ s.row.total_amount }}</template>
          </el-table-column>
          <el-table-column prop="need_date" label="需求日期" width="100" align="center" />
          <el-table-column label="执行状态" width="100" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="itemExecTag(s.row.execution_status)">{{ s.row.execution_status_label }}</el-tag></template>
          </el-table-column>
        </el-table>

        <!-- 执行进度（已审批时） -->
        <template v-if="tracking">
          <div class="section-title">执行进度</div>
          <RequestTracking :tracking="tracking" />
        </template>
      </template>
    </el-card>
  </div>
</template>

<script>
import RequestTracking from './components/RequestTracking.vue'
import { getRequestDetail, submitRequest, cancelRequest, generateOrder, approveRequest, rejectRequest } from '../../../../api/purchase'

export default {
  name: 'BusinessPurchaseRequestDetail',
  components: { RequestTracking },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,
      loadFailed: false,
      submitting: false,
      req: {},
      items: [],
      tracking: null
    }
  },
  computed: {
    totalAmount() {
      return this.items.reduce((s, it) => s + (Number(it.total_amount) || 0), 0).toFixed(2)
    }
  },
  created() {
    this.fetchDetail()
  },
  methods: {
    typeTag(t) { return { 1: 'primary', 2: 'purple', 3: 'danger', 4: 'warning' }[t] || 'info' },
    sourceTag(t) { return { 1: 'info', 2: 'primary', 3: 'warning', 4: 'success', 5: 'info', 6: 'info', 7: 'purple', 8: 'primary', 9: 'danger' }[t] || 'info' },
    urgencyTag(t) { return ['info', 'warning', 'danger'][t] || 'info' },
    approvalTag(t) { return ['info', 'warning', 'success', 'danger', 'info'][t] || 'info' },
    execTag(t) { return ['info', 'primary', 'success', 'success'][t] || 'info' },
    contractTag(t) { return ['info', 'warning', 'success'][t] || 'info' },
    itemExecTag(t) { return ['info', 'primary', 'warning', 'success', 'info'][t] || 'info' },
    async fetchDetail() {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getRequestDetail(this.id)
        if (r.code === 0 && r.data) {
          this.req = r.data.request || {}
          this.items = r.data.items || []
          this.tracking = r.data.tracking || null
        } else {
          this.loadFailed = true
        }
      } catch (e) { this.loadFailed = true }
      this.loading = false
    },
    viewSource() {
      if (this.req.source_type === 2) this.$router.push('/business/order')
      else if (this.req.source_type === 3) this.$router.push({ path: '/business/order', query: { category: 'repair' } })
      else this.$message.info('该来源类型无跳转链接')
    },
    async handleSubmit() {
      this.submitting = true
      try {
        const r = await submitRequest(this.id)
        if (r.code === 0) { this.$message.success('已提交审批'); this.fetchDetail() }
      } catch (e) {}
      this.submitting = false
    },
    async handleApprove() {
      try {
        const { value } = await this.$prompt('请输入审批意见（选填）', '审批通过', { inputPlaceholder: '审批意见', confirmButtonText: '通过', cancelButtonText: '取消', inputValue: '同意' })
        const r = await approveRequest(this.id, value || '同意')
        if (r.code === 0) { this.$message.success('已审批通过'); this.fetchDetail() } else this.$message.error(r.msg || '审批失败')
      } catch (e) {}
    },
    async handleReject() {
      try {
        const { value } = await this.$prompt('请输入驳回原因', '审批驳回', { inputPlaceholder: '驳回原因', confirmButtonText: '驳回', cancelButtonText: '取消' })
        if (!value) { this.$message.warning('请填写驳回原因'); return }
        const r = await rejectRequest(this.id, value)
        if (r.code === 0) { this.$message.success('已驳回'); this.fetchDetail() } else this.$message.error(r.msg || '驳回失败')
      } catch (e) {}
    },
    handleCancel() {
      this.$confirm('确认撤销该采购申请吗？撤销后需重新提交', '撤销确认', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelRequest(this.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.fetchDetail() }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleGenOrder() {
      try {
        const r = await generateOrder(this.id)
        if (r.code === 0) {
          const n = (r.data && r.data.pending_items) ? r.data.pending_items.length : 0
          this.$confirm(`已获取待下单明细（${n} 项），将跳转到采购订单新增页面并带入该申请，是否继续？`, '生成采购订单', { type: 'info', confirmButtonText: '去下单', cancelButtonText: '取消' })
            .then(() => { this.$router.push(`/business/purchase/order/add?request_id=${this.id}`) })
            .catch(() => {})
        } else {
          this.$message.error(r.msg || '生成失败')
        }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.request-detail-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin: 18px 0 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
.link-text { color: #409eff; cursor: pointer; }
::v-deep .el-tag--purple { background-color: #f3e5f5; border-color: #ce93d8; color: #8e24aa; }
</style>
