<!--
  文件：admin/src/views/business/supplier/components/SupplierDetailDialog.vue
  功能：供应商详情弹窗（750px）
    - 基本信息 / 联系人 / 资质证照 / 分类状态 / 备注
    - 底部业务统计：采购订单数、采购入库数
-->
<template>
  <el-dialog
    :title="detail ? detail.supplier_name : '供应商详情'"
    :visible="visible"
    width="750px"
    :close-on-click-modal="false"
    @close="$emit('update:visible', false)"
  >
    <div v-loading="loading" class="detail-wrap">
      <template v-if="detail">
        <!-- 业务统计 -->
        <el-row :gutter="12" class="stat-row">
          <el-col :span="8"><div class="stat-card"><div class="stat-num">{{ stats.order_count || 0 }}</div><div class="stat-label">采购订单</div></div></el-col>
          <el-col :span="8"><div class="stat-card"><div class="stat-num">{{ stats.inbound_count || 0 }}</div><div class="stat-label">采购入库</div></div></el-col>
          <el-col :span="8"><div class="stat-card"><div class="stat-num">{{ detail.supplier_level_text }}</div><div class="stat-label">供应商评级</div></div></el-col>
        </el-row>

        <el-divider content-position="left">基本信息</el-divider>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="供应商编码">{{ detail.supplier_code }}</el-descriptions-item>
          <el-descriptions-item label="供应商名称">{{ detail.supplier_name }}</el-descriptions-item>
          <el-descriptions-item label="供应商简称">{{ detail.supplier_short_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="供应商类型">{{ detail.supplier_type_text }}</el-descriptions-item>
          <el-descriptions-item label="供应品类">{{ detail.supply_category_text || '--' }}</el-descriptions-item>
          <el-descriptions-item label="所属区域">{{ detail.region_text || '--' }}</el-descriptions-item>
          <el-descriptions-item label="供应商分类">{{ detail.category_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="状态">{{ detail.status === 1 ? '启用' : '停用' }}</el-descriptions-item>
          <el-descriptions-item label="合作开始">{{ detail.cooperation_start || '--' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '--' }}</el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">联系人信息</el-divider>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="联系人">{{ detail.contact_person || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ detail.contact_phone || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系邮箱">{{ detail.contact_email || '--' }}</el-descriptions-item>
          <el-descriptions-item label="地址">{{ detail.address || '--' }}</el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">资质证照</el-divider>
        <el-descriptions :column="1" size="small" border>
          <el-descriptions-item label="税号">{{ detail.tax_number || '--' }}</el-descriptions-item>
          <el-descriptions-item label="开户银行">{{ detail.bank_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="银行账号">{{ detail.bank_account || '--' }}</el-descriptions-item>
        </el-descriptions>
        <el-table v-if="detail.qualifications && detail.qualifications.length" :data="detail.qualifications" size="mini" border style="margin-top:8px">
          <el-table-column prop="name" label="证照名称" />
          <el-table-column prop="number" label="证照编号" />
          <el-table-column prop="expire" label="有效期至" width="130" />
        </el-table>
        <div v-else class="no-data">暂无资质证照</div>

        <div v-if="detail.remark" class="remark-block">
          <div class="remark-label">备注</div>
          <div class="remark-content">{{ detail.remark }}</div>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getSupplierDetail } from '../../../../api/businessSupplier'

export default {
  name: 'SupplierDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    supplierId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, detail: null, stats: {} }
  },
  watch: {
    visible(val) {
      if (val && this.supplierId) this.open()
    }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      try {
        const r = await getSupplierDetail(this.supplierId)
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
.no-data { color: #909399; font-size: 12px; padding: 8px 0; }
.remark-block { margin-top: 12px; }
.remark-label { font-size: 13px; font-weight: 600; color: #303133; margin-bottom: 6px; }
.remark-content { font-size: 13px; color: #606266; background: #f8f9fb; padding: 10px 12px; border-radius: 4px; }
</style>
