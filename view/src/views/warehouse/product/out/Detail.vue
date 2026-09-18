<!--
  文件：admin/src/views/warehouse/product/out/Detail.vue
  功能：产品出库单详情（信息/明细/库存流水/操作日志）
  权限：warehouse:product:out:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备出入库</el-breadcrumb-item>
      <el-breadcrumb-item>产品出库</el-breadcrumb-item>
      <el-breadcrumb-item>出库单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">出库单详情 - {{ detail.out_no || '' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/warehouse/product/out/list' })">返回列表</el-button>
        <el-button v-if="detail.status === 0 || detail.status === 4" v-permission="'warehouse:product:out:edit'" size="small" type="primary" @click="goEdit">编辑</el-button>
        <el-button v-if="detail.status === 0" size="small" @click="handleSubmit">提交审核</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:product:out:audit'" size="small" type="success" @click="handleApprove">审核通过</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:product:out:audit'" size="small" type="danger" @click="handleReject">审核驳回</el-button>
        <el-button v-if="detail.status === 2" v-permission="'warehouse:product:out:confirm'" size="small" type="warning" @click="handleConfirm">确认出库</el-button>
        <el-button size="small" icon="el-icon-printer" @click="window.print()">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-header">
        <span>出库单信息</span>
        <el-tag :type="detail.status_tag" size="small">{{ detail.status_label }}</el-tag>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="出库单编号">{{ detail.out_no }}</el-descriptions-item>
        <el-descriptions-item label="出库类型">{{ detail.out_type_label }}</el-descriptions-item>
        <el-descriptions-item label="来源单据">
          <el-link v-if="detail.source_no" type="primary" @click="goSource">{{ detail.source_no }}</el-link><span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="关联维修工单">
          <el-link v-if="detail.repair_order_no" type="primary" @click="$router.push({ path: '/device/repair/order' })">{{ detail.repair_order_no }}</el-link><span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="关联销售订单">
          <el-link v-if="detail.sales_order_no" type="primary" @click="$router.push({ path: '/business/order' })">{{ detail.sales_order_no }}</el-link><span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="客户名称">{{ detail.customer_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="交付地址" :span="2">{{ detail.delivery_address || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库仓库">{{ detail.warehouse_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库人">{{ detail.out_user_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="出库日期">{{ detail.out_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="总数量">{{ Number(detail.total_quantity).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="总金额">¥ {{ Number(detail.total_amount).toFixed(2) }}</el-descriptions-item>
        <el-descriptions-item label="出库状态">{{ detail.status_label }}</el-descriptions-item>
        <el-descriptions-item label="审核人">{{ detail.auditor_name || detail.auditor_id || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ detail.audit_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核备注" :span="2">{{ detail.audit_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detail.creator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detail.updated_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="card-header"><span>出库明细</span></div>
      <el-table :data="detail.items || []" v-loading="loading" size="small" border empty-text="暂无明细">
        <el-table-column prop="product_code" label="产品编码" width="110" />
        <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column prop="quantity" label="出库数量" width="100" align="right" />
        <el-table-column prop="unit_price" label="出库单价" width="100" align="right" />
        <el-table-column prop="total_price" label="出库总价" width="110" align="right" />
        <el-table-column prop="serial_number" label="设备编号/序列号" width="130" />
        <el-table-column prop="location_name" label="出库货位" width="100" />
        <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
      </el-table>
    </el-card>

    <el-card v-if="detail.status === 3" shadow="never" class="logs-card">
      <div slot="header" class="card-header"><span>库存流水</span></div>
      <el-table :data="detail.stock_flows || []" size="small" border empty-text="暂无流水">
        <el-table-column label="变动类型" width="100" align="center"><template slot-scope="s"><el-tag size="mini" type="danger">产品出库</el-tag></template></el-table-column>
        <el-table-column prop="flow_quantity" label="变动数量" width="100" align="right" />
        <el-table-column prop="cost_price" label="成本单价" width="100" align="right" />
        <el-table-column prop="cost_total" label="成本总价" width="110" align="right" />
        <el-table-column prop="before_stock" label="变动前库存" width="100" align="right" />
        <el-table-column prop="after_stock" label="变动后库存" width="100" align="right" />
        <el-table-column prop="operator_name" label="操作人" width="100" align="center" />
        <el-table-column prop="flow_time" label="变动时间" width="160" align="center" />
      </el-table>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="card-header">
        <span>操作日志</span>
        <span class="log-count">共 {{ (detail.logs || []).length }} 条记录</span>
      </div>
      <el-timeline v-if="detail.logs && detail.logs.length">
        <el-timeline-item v-for="lg in detail.logs" :key="lg.id" :timestamp="lg.operator_time || ''" placement="top" :type="lg.action_tag === 'danger' ? 'danger' : (lg.action_tag === 'success' ? 'success' : 'primary')">
          <div>
            <el-tag :type="lg.action_tag" size="mini">{{ lg.action_label }}</el-tag>
            <span class="log-operator">{{ lg.operator_name }}</span>
            <span v-if="lg.from_status_text || lg.to_status_text" class="log-status">{{ lg.from_status_text }} → {{ lg.to_status_text }}</span>
            <div v-if="lg.remark" class="log-remark">{{ lg.remark }}</div>
          </div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无操作记录" />
    </el-card>
  </div>
</template>

<script>
import { getProductOutDetail, submitProductOut, approveProductOut, rejectProductOut, confirmProductOut } from '../../../../api/warehouse'

export default {
  name: 'WarehouseProductOutDetail',
  data () {
    return { id: 0, loading: false, detail: {} }
  },
  created () {
    this.id = Number(this.$route.params.id)
    this.loadDetail()
  },
  methods: {
    async loadDetail () {
      this.loading = true
      try {
        const r = await getProductOutDetail(this.id)
        if (r.code === 0 && r.data) this.detail = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {} finally { this.loading = false }
    },
    goEdit () { this.$router.push({ path: `/warehouse/product/out/edit/${this.id}` }) },
    goSource () {
      if (this.detail.source_type === 1) this.$router.push({ path: '/device/repair/order' })
      else if (this.detail.source_type === 2) this.$router.push({ path: '/business/order' })
    },
    handleSubmit () {
      this.$confirm(`确认提交出库单 ${this.detail.out_no} 审核吗？提交后不可再编辑。`, '提交审核', { type: 'warning' }).then(async () => {
        try {
          const r = await submitProductOut(this.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.loadDetail() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleApprove () {
      this.$prompt('请输入审核备注（可选）', '审核通过', { inputPlaceholder: '审核备注', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await approveProductOut(this.id, value || '')
          if (r.code === 0) { this.$message.success('审核已通过'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject () {
      this.$prompt('请输入驳回原因（必填）', '审核驳回', { inputPlaceholder: '驳回原因' }).then(async ({ value }) => {
        if (!value || !value.trim()) { this.$message.warning('驳回原因必填'); return }
        try {
          const r = await rejectProductOut(this.id, value.trim())
          if (r.code === 0) { this.$message.success('已驳回'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleConfirm () {
      this.$confirm(`确认出库单 ${this.detail.out_no} 确认出库吗？将扣减库存并生成出库成本流水，此操作不可撤销。`, '确认出库', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmProductOut(this.id)
          if (r.code === 0) { this.$message.success(r.msg || '出库成功'); this.loadDetail() } else this.$message.error(r.msg || '出库失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.info-card { margin-bottom: 16px; }
.logs-card { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.log-count { color: #909399; font-size: 12px; }
.log-operator { margin-left: 8px; color: #606266; font-size: 13px; }
.log-status { margin-left: 8px; color: #909399; font-size: 12px; }
.log-remark { color: #606266; font-size: 13px; margin-top: 4px; }
</style>
