<!--
  文件：admin/src/views/business/purchase/request/components/RequestTracking.vue
  功能：采购申请执行进度（总体汇总 + 物料进度 + 关联采购订单 + 关联合同）
  props：tracking（对象）
-->
<template>
  <div class="request-tracking" v-if="tracking">
    <!-- 总体进度 -->
    <div class="summary">
      <div class="summary-item">
        <span class="label">已下单</span>
        <span class="value">{{ fmt(tracking.summary.ordered_quantity) }}/{{ fmt(tracking.summary.total_quantity) }} 件（{{ tracking.summary.ordered_percent }}%）</span>
      </div>
      <div class="summary-item">
        <span class="label">已入库</span>
        <span class="value">{{ fmt(tracking.summary.received_quantity) }}/{{ fmt(tracking.summary.total_quantity) }} 件（{{ tracking.summary.received_percent }}%）</span>
      </div>
    </div>

    <!-- 物料进度 -->
    <div class="section-title">物料执行进度</div>
    <el-table :data="tracking.materials" size="small" border>
      <el-table-column prop="product_name" label="产品名称" min-width="140" show-overflow-tooltip />
      <el-table-column prop="quantity" label="申请数量" width="90" align="right" />
      <el-table-column prop="ordered_quantity" label="已下单" width="90" align="right" />
      <el-table-column prop="un_ordered_quantity" label="未下单" width="90" align="right" />
      <el-table-column prop="received_quantity" label="已入库" width="90" align="right" />
      <el-table-column label="执行状态" width="110" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="execTag(s.row.execution_status)">{{ s.row.execution_status_label }}</el-tag>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!tracking.materials.length" description="暂无物料进度" :image-size="60" />

    <!-- 关联采购订单 -->
    <div class="section-title">关联采购订单</div>
    <el-table :data="tracking.orders" size="small" border>
      <el-table-column label="订单编号" width="160">
        <template slot-scope="s"><span class="link-text" @click="viewOrder(s.row.purchase_order_id)">{{ s.row.purchase_order_no || '-' }}</span></template>
      </el-table-column>
      <el-table-column prop="ordered_quantity" label="下单数量" width="100" align="right" />
      <el-table-column prop="received_quantity" label="入库数量" width="100" align="right" />
      <el-table-column label="关联合同" width="160">
        <template slot-scope="s">
          <span v-if="s.row.contract_no" class="link-text" @click="viewContract(s.row.contract_id)">{{ s.row.contract_no }}</span>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="100" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="viewOrder(s.row.purchase_order_id)">查看订单</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!tracking.orders.length" description="尚未生成采购订单" :image-size="60" />

    <!-- 关联采购合同 -->
    <div class="section-title">关联采购合同</div>
    <el-descriptions :column="2" border size="small" v-if="tracking.contract && tracking.contract.contract_id">
      <el-descriptions-item label="合同编号">
        <span class="link-text" @click="viewContract(tracking.contract.contract_id)">{{ tracking.contract.contract_no || '-' }}</span>
      </el-descriptions-item>
      <el-descriptions-item label="合同状态">
        <el-tag size="mini" :type="contractTag(tracking.contract.contract_status)">{{ tracking.contract.contract_status_label }}</el-tag>
      </el-descriptions-item>
    </el-descriptions>
    <el-empty v-else description="暂无关联合同" :image-size="60" />
  </div>
</template>

<script>
export default {
  name: 'RequestTracking',
  props: {
    tracking: { type: Object, default: null }
  },
  methods: {
    fmt(v) { return String(v) },
    execTag(v) { return ['info', 'primary', 'warning', 'success', 'info'][v] || 'info' },
    contractTag(v) { return ['info', 'warning', 'success'][v] || 'info' },
    viewOrder(id) { if (id) this.$router.push('/business/purchase/order/detail/' + id) },
    viewContract(id) { if (id) this.$router.push({ path: '/business/contract', query: { detail: id } }) }
  }
}
</script>

<style scoped>
.summary { display: flex; gap: 24px; margin-bottom: 14px; }
.summary-item .label { color: #909399; margin-right: 8px; }
.summary-item .value { font-weight: 600; }
.section-title { display: flex; align-items: center; font-size: 14px; font-weight: 600; margin: 16px 0 10px; }
.section-title::before { content: ''; width: 4px; height: 13px; border-radius: 2px; background: #409eff; margin-right: 8px; }
.link-text { color: #409eff; cursor: pointer; }
</style>
