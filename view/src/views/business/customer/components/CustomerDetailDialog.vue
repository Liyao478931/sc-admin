<!--
  文件：admin/src/views/business/customer/components/CustomerDetailDialog.vue
  功能：客户详情弹窗（750px）
    - 基本信息 / 联系人信息 / 财务信息 / 分类与状态 / 备注
    - 底部业务统计：订单数、设备接收数、合同数
-->
<template>
  <el-dialog
    :title="detail ? detail.customer_name : '客户详情'"
    :visible="visible"
    width="750px"
    :close-on-click-modal="false"
    @close="$emit('update:visible', false)"
  >
    <div v-loading="loading" class="detail-wrap">
      <template v-if="detail">
        <!-- 业务统计 -->
        <el-row :gutter="12" class="stat-row">
          <el-col :span="8"><div class="stat-card"><div class="stat-num">{{ stats.order_count || 0 }}</div><div class="stat-label">销售订单</div></div></el-col>
          <el-col :span="8"><div class="stat-card"><div class="stat-num">{{ stats.receive_count || 0 }}</div><div class="stat-label">设备接收</div></div></el-col>
          <el-col :span="8"><div class="stat-card"><div class="stat-num">{{ stats.contract_count || 0 }}</div><div class="stat-label">合同</div></div></el-col>
        </el-row>

        <el-divider content-position="left">基本信息</el-divider>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="客户编码">{{ detail.customer_code }}</el-descriptions-item>
          <el-descriptions-item label="客户名称">{{ detail.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="客户简称">{{ detail.customer_short_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="客户类型">{{ detail.customer_type_text }}</el-descriptions-item>
          <el-descriptions-item label="所属行业">{{ detail.industry_text || '--' }}</el-descriptions-item>
          <el-descriptions-item label="所属区域">{{ detail.region_text || '--' }}</el-descriptions-item>
          <el-descriptions-item label="客户等级">{{ detail.customer_level_text }}</el-descriptions-item>
          <el-descriptions-item label="客户分类">{{ detail.category_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="状态">{{ detail.status === 1 ? '启用' : '停用' }}</el-descriptions-item>
          <el-descriptions-item label="信用额度">¥{{ Number(detail.credit_limit || 0).toLocaleString() }}</el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">联系人信息</el-divider>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="联系人">{{ detail.contact_person || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ detail.contact_phone || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系邮箱">{{ detail.contact_email || '--' }}</el-descriptions-item>
          <el-descriptions-item label="地址">{{ detail.address || '--' }}</el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">财务信息</el-divider>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="税号">{{ detail.tax_number || '--' }}</el-descriptions-item>
          <el-descriptions-item label="开户银行">{{ detail.bank_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="银行账号">{{ detail.bank_account || '--' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '--' }}</el-descriptions-item>
        </el-descriptions>

        <div v-if="detail.remark" class="remark-block">
          <div class="remark-label">备注</div>
          <div class="remark-content">{{ detail.remark }}</div>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getCustomerDetail } from '../../../../api/businessCustomer'

export default {
  name: 'CustomerDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    customerId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, detail: null, stats: {} }
  },
  watch: {
    visible(val) {
      if (val && this.customerId) this.open()
    }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      try {
        const r = await getCustomerDetail(this.customerId)
        if (r.code === 0 && r.data) {
          this.detail = r.data
          this.stats = r.data.business_stats || {}
        }
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>

<style scoped>
.stat-row { margin-bottom: 8px; }
.stat-card { text-align: center; padding: 12px 0; border: 1px solid #ebeef5; border-radius: 6px; }
.stat-num { font-size: 20px; font-weight: 700; color: #409eff; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.remark-block { margin-top: 12px; }
.remark-label { font-size: 13px; font-weight: 600; color: #303133; margin-bottom: 6px; }
.remark-content { font-size: 13px; color: #606266; background: #f8f9fb; padding: 10px 12px; border-radius: 4px; }
</style>
