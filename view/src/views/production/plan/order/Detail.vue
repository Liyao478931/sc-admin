<!--
  文件：admin/src/views/production/plan/order/Detail.vue
  功能：工单详情（完整信息 + 物料明细 + 状态操作：派工/开始/报工/质检/关闭）
  权限：production:order:view 及各项操作权限
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产计划</el-breadcrumb-item>
      <el-breadcrumb-item>生产工单</el-breadcrumb-item>
      <el-breadcrumb-item>工单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="detail-card" v-loading="loading">
      <div slot="header" class="detail-header">
        <span class="detail-title">{{ detail.order_no || '' }}</span>
        <el-tag v-if="detail.status_label" :type="detail.status_tag" size="small">{{ detail.status_label }}</el-tag>
      </div>

      <div v-if="detail.id" class="detail-body">
        <el-descriptions :column="3" border size="small">
          <el-descriptions-item label="工单类型">{{ detail.order_type_label }}</el-descriptions-item>
          <el-descriptions-item label="来源单据">{{ detail.source_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="优先级">{{ detail.priority_label }}</el-descriptions-item>
          <el-descriptions-item label="产品名称">{{ detail.product_name }}</el-descriptions-item>
          <el-descriptions-item label="规格型号">{{ detail.product_spec || '-' }}</el-descriptions-item>
          <el-descriptions-item label="客户">{{ detail.customer_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="计划数量">{{ fmt(detail.plan_quantity) }}</el-descriptions-item>
          <el-descriptions-item label="完成数量">{{ fmt(detail.completed_quantity) }}</el-descriptions-item>
          <el-descriptions-item label="进度">{{ Number(detail.progress) }}%</el-descriptions-item>
          <el-descriptions-item label="计划开始">{{ detail.planned_start_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="计划完成">{{ detail.planned_end_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="实际开始">{{ detail.actual_start_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="实际完成">{{ detail.actual_end_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ detail.responsible_person_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="负责部门">{{ detail.department_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="3">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 来源订单信息 -->
        <div v-if="sourceOrder" class="source-card">
          <div class="sub-title">来源订单</div>
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="订单编号"><span class="link-blue" @click="goOrderList">{{ sourceOrder.order_no }}</span></el-descriptions-item>
            <el-descriptions-item label="客户">{{ sourceOrder.customer_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="交付日期">{{ sourceOrder.delivery_date || '-' }}</el-descriptions-item>
          </el-descriptions>
        </div>

        <!-- 操作按钮组 -->
        <div class="action-bar">
          <el-button v-if="detail.status === 0" v-permission="'production:order:dispatch'" size="small" type="primary" @click="openDispatch">派工</el-button>
          <el-button v-if="detail.status === 1" v-permission="'production:order:dispatch'" size="small" type="primary" @click="handleStart">开始生产</el-button>
          <el-button v-if="detail.status === 2" v-permission="'production:order:report'" size="small" type="primary" @click="openReport">报工</el-button>
          <el-button v-if="detail.status === 2 && Number(detail.progress) >= 100" v-permission="'production:order:quality'" size="small" type="warning" @click="handleApplyQuality">申请质检</el-button>
          <el-button v-if="detail.status === 3" v-permission="'production:order:quality'" size="small" type="success" @click="openQualityPass">质检通过</el-button>
          <el-button v-if="detail.status === 3" v-permission="'production:order:quality'" size="small" type="danger" @click="openQualityReject">质检驳回</el-button>
          <el-button v-if="detail.status === 4" v-permission="'production:order:close'" size="small" type="warning" @click="handleClose">关闭工单</el-button>
          <el-button size="small" @click="$router.push('/production/plan/order/list')">返回列表</el-button>
        </div>

        <!-- 物料明细 -->
        <div class="sub-title">物料明细</div>
        <el-table :data="detail.items || []" size="small" border>
          <el-table-column type="index" label="#" width="55" align="center" />
          <el-table-column prop="material_code" label="物料编码" width="130" />
          <el-table-column prop="material_name" label="物料名称" min-width="160" />
          <el-table-column prop="specification" label="规格型号" width="140" />
          <el-table-column prop="unit" label="单位" width="80" align="center" />
          <el-table-column label="计划用量" width="110" align="right"><template slot-scope="s">{{ fmt(s.row.plan_quantity) }}</template></el-table-column>
          <el-table-column label="实际用量" width="110" align="right"><template slot-scope="s">{{ fmt(s.row.actual_quantity) }}</template></el-table-column>
          <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
        </el-table>
      </div>
    </el-card>

    <!-- 派工对话框 -->
    <el-dialog title="工单派工" :visible.sync="dispatchVisible" width="480px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="班组/部门">
          <el-select v-model="dispatchForm.department_id" filterable placeholder="请选择班组" style="width:100%">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="负责人">
          <el-select v-model="dispatchForm.responsible_person_id" filterable placeholder="请选择负责人" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
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
        <el-form-item label="完成数量"><el-input-number v-model="reportForm.completed_quantity" :min="1" :max="detail.plan_quantity" :precision="2" style="width:100%" /></el-form-item>
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
import { getOrderDetail, dispatchOrder, startOrder, reportOrder, applyQuality, qualityPass, qualityReject, closeOrder, getOrderUsers, getSourceData } from '@/api/production'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'ProductionOrderDetail',
  data () {
    return {
      detail: {}, sourceOrder: null, loading: false, acting: false,
      deptOptions: [], userOptions: [],
      dispatchVisible: false, dispatchForm: { responsible_person_id: null, department_id: null },
      reportVisible: false, reportForm: { completed_quantity: 1, remark: '' },
      qualityPassVisible: false, qualityPassForm: { result: '', remark: '' },
      qualityRejectVisible: false, qualityRejectForm: { reason: '' }
    }
  },
  created () {
    this.loadDepts()
    this.loadUsers()
    this.loadData()
  },
  methods: {
    fmt (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    async loadUsers () {
      try { const r = await getOrderUsers(); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) { this.userOptions = [] }
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getOrderDetail(this.$route.params.id)
        if (r.code === 0 && r.data) {
          this.detail = r.data
          if ([1, 2].includes(Number(r.data.source_type)) && Number(r.data.source_id) > 0) this.loadSourceOrder()
        }
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {} finally { this.loading = false }
    },
    async loadSourceOrder () {
      try {
        const r = await getSourceData({ source_type: this.detail.source_type, source_id: this.detail.source_id })
        if (r.code === 0 && r.data) this.sourceOrder = r.data
      } catch (e) {}
    },
    goOrderList () { this.$router.push('/business/order') },
    refresh () { this.loadData() },
    openDispatch () { this.dispatchForm = { responsible_person_id: null, department_id: null }; this.dispatchVisible = true },
    openReport () { this.reportForm = { completed_quantity: Number(this.detail.completed_quantity) || 0, remark: '' }; this.reportVisible = true },
    openQualityPass () { this.qualityPassForm = { result: '', remark: '' }; this.qualityPassVisible = true },
    openQualityReject () { this.qualityRejectForm = { reason: '' }; this.qualityRejectVisible = true },
    handleStart () {
      this.$confirm('确认开始生产吗？', '开始生产', { type: 'warning' }).then(async () => {
        try { const r = await startOrder(this.detail.id); if (r.code === 0) { this.$message.success('已开始生产'); this.refresh() } else this.$message.error(r.msg) } catch (e) {}
      }).catch(() => {})
    },
    handleApplyQuality () {
      this.$confirm('确认申请质检吗？', '申请质检', { type: 'warning' }).then(async () => {
        try { const r = await applyQuality(this.detail.id); if (r.code === 0) { this.$message.success('已申请质检'); this.refresh() } else this.$message.error(r.msg) } catch (e) {}
      }).catch(() => {})
    },
    handleClose () {
      this.$confirm('确认关闭该工单吗？', '关闭工单', { type: 'warning' }).then(async () => {
        try { const r = await closeOrder(this.detail.id); if (r.code === 0) { this.$message.success('工单已关闭'); this.refresh() } else this.$message.error(r.msg) } catch (e) {}
      }).catch(() => {})
    },
    async confirmDispatch () {
      if (!this.dispatchForm.department_id || !this.dispatchForm.responsible_person_id) { this.$message.warning('请选择班组和负责人'); return }
      this.acting = true
      try {
        const u = this.userOptions.find(x => x.id === this.dispatchForm.responsible_person_id)
        const d = this.deptOptions.find(x => x.id === this.dispatchForm.department_id)
        const r = await dispatchOrder(this.detail.id, {
          responsible_person_id: this.dispatchForm.responsible_person_id,
          responsible_person_name: u ? (u.real_name || u.username) : '',
          department_id: this.dispatchForm.department_id,
          department_name: d ? d.name : ''
        })
        if (r.code === 0) { this.$message.success('派工成功'); this.dispatchVisible = false; this.refresh() } else this.$message.error(r.msg || '派工失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmReport () {
      if (!this.reportForm.completed_quantity || this.reportForm.completed_quantity <= 0) { this.$message.warning('请填写完成数量'); return }
      this.acting = true
      try {
        const r = await reportOrder(this.detail.id, { completed_quantity: this.reportForm.completed_quantity, remark: this.reportForm.remark })
        if (r.code === 0) { this.$message.success(r.msg || '报工成功'); this.reportVisible = false; this.refresh() } else this.$message.error(r.msg || '报工失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmQualityPass () {
      this.acting = true
      try {
        const r = await qualityPass(this.detail.id, { result: this.qualityPassForm.result, remark: this.qualityPassForm.remark })
        if (r.code === 0) { this.$message.success('质检通过'); this.qualityPassVisible = false; this.refresh() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    async confirmQualityReject () {
      if (!this.qualityRejectForm.reason) { this.$message.warning('请填写驳回原因'); return }
      this.acting = true
      try {
        const r = await qualityReject(this.detail.id, { reason: this.qualityRejectForm.reason })
        if (r.code === 0) { this.$message.success('已驳回'); this.qualityRejectVisible = false; this.refresh() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.detail-card { border-radius: 8px; }
.detail-header { display: flex; align-items: center; gap: 12px; }
.detail-title { font-size: 16px; font-weight: 600; }
.detail-body { padding: 4px 8px; }
.source-card { margin: 16px 0 4px; background: #f8f9fb; padding: 12px; border-radius: 6px; }
.source-card .sub-title { margin: 0 0 10px; }
.link-blue { color: #409EFF; cursor: pointer; }
.action-bar { margin: 16px 0; display: flex; gap: 10px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 8px 0 12px; }
</style>
