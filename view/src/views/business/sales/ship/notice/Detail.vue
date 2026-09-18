<!--
  文件：admin/src/views/business/sales/ship/notice/Detail.vue
  功能：发货通知详情（通知信息卡 / 通知明细 / 操作日志时间轴 / 状态操作 / 打印）
  权限：sales:ship:notice:view / add / edit / push
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货通知</el-breadcrumb-item>
      <el-breadcrumb-item>通知详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">发货通知详情 - {{ d.notice_name || '' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/business/sales/ship/notice' })">返回列表</el-button>
        <el-button v-if="d.status === 0" v-permission="'sales:ship:notice:edit'" size="small" icon="el-icon-edit" @click="goEdit">编辑</el-button>
        <el-button v-if="d.status === 0" size="small" type="primary" icon="el-icon-upload2" :loading="submitting" @click="handleSubmit">提交审核</el-button>
        <el-button v-if="d.status === 2" v-permission="'sales:ship:notice:push'" size="small" type="success" icon="el-icon-download" :loading="pushing" @click="handlePush">下推出库单</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <div slot="header" class="card-header">
        <span>通知信息</span>
        <el-tag :type="d.status_tag" size="small">{{ d.status_label }}</el-tag>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="通知单编号">{{ d.notice_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="通知单名称">{{ d.notice_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="销售订单">{{ d.order_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="客户名称">{{ d.customer_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="收货人">{{ d.receiver || '-' }}</el-descriptions-item>
        <el-descriptions-item label="收货电话">{{ d.receiver_phone || '-' }}</el-descriptions-item>
        <el-descriptions-item label="收货地址" :span="2">{{ d.receiver_address || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发货日期">{{ d.ship_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="下推出库单">{{ d.push_out_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核人">{{ d.auditor_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ d.audit_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核备注" :span="2">{{ d.audit_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ d.creator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ d.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ d.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>通知明细</span></div>
      <el-table :data="d.items || []" size="small" border empty-text="暂无明细">
        <el-table-column prop="product_code" label="产品编码" width="110" />
        <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="60" align="center" />
        <el-table-column prop="notice_quantity" label="通知数量" width="100" align="right" />
        <el-table-column prop="out_quantity" label="已出库数量" width="100" align="right"><template slot-scope="s">{{ Number(s.row.out_quantity) || 0 }}</template></el-table-column>
        <el-table-column prop="suggest_location_name" label="存放货位建议" width="130" show-overflow-tooltip><template slot-scope="s">{{ s.row.suggest_location_name || '-' }}</template></el-table-column>
        <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip><template slot-scope="s">{{ s.row.remark || '-' }}</template></el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="never" class="form-card">
      <div slot="header"><span>操作日志</span></div>
      <el-timeline v-if="logs.length" style="padding-left:8px;">
        <el-timeline-item v-for="(lg, i) in logs" :key="i" :timestamp="lg.operator_time" placement="top">
          <div>{{ lg.action_label }} <span style="color:#909399">({{ lg.operator_name }})</span></div>
          <div v-if="lg.from_status_text || lg.to_status_text" style="color:#606266;font-size:12px;">{{ lg.from_status_text }} → {{ lg.to_status_text }}</div>
          <div v-if="lg.remark" style="color:#606266;font-size:12px;">{{ lg.remark }}</div>
        </el-timeline-item>
        <el-timeline-item v-for="(h, i) in d.approval_histories || []" :key="'h' + i" :timestamp="h.created_at" :type="h.result === 'reject' ? 'danger' : (h.action === 'submit' ? 'primary' : 'success')" placement="top">
          <div>【统一审批】{{ h.action_label }}：{{ h.result === 'pass' ? '通过' : (h.result === 'reject' ? '驳回' : '') }} <span style="color:#909399">({{ h.operator_name }})</span></div>
          <div v-if="h.comment" style="color:#606266;font-size:12px;">意见：{{ h.comment }}</div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无操作日志" :image-size="50" />
    </el-card>
  </div>
</template>

<script>
import { getNoticeDetail, submitNotice, pushNotice } from '@/api/sales'

export default {
  name: 'ShipNoticeDetail',
  data () {
    return { d: {}, submitting: false, pushing: false }
  },
  computed: {
    logs () { return this.d.logs || [] }
  },
  created () {
    this.loadDetail(Number(this.$route.params.id))
    if (this.$route.query.print) {
      setTimeout(() => { window.print() }, 600)
    }
  },
  methods: {
    async loadDetail (id) {
      try {
        const r = await getNoticeDetail(id)
        if (r.code === 0 && r.data) this.d = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    goEdit () { this.$router.push({ path: `/business/sales/ship/notice/edit/${this.d.id}` }) },
    handleSubmit () {
      this.$confirm(`确认提交通知 ${this.d.notice_no} 审核吗？提交后将由统一审批流程处理。`, '提交审核', { type: 'warning' }).then(async () => {
        this.submitting = true
        try {
          const r = await submitNotice(this.d.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.loadDetail(this.d.id) } else this.$message.error(r.msg || '提交失败')
        } catch (e) {} finally { this.submitting = false }
      }).catch(() => {})
    },
    handlePush () {
      this.$confirm(`确认将通知 ${this.d.notice_no} 下推为销售出库单吗？`, '下推出库单', { type: 'warning' }).then(async () => {
        this.pushing = true
        try {
          const r = await pushNotice(this.d.id)
          if (r.code === 0) {
            this.$message.success(r.msg || '已下推出库单')
            this.loadDetail(this.d.id)
            if (r.data && r.data.out_id) this.$router.push({ path: `/business/sales/out/detail/${r.data.out_id}` })
          } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.pushing = false }
      }).catch(() => {})
    },
    handlePrint () { window.print() }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.form-card { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
