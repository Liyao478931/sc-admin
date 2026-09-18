<!--
  文件：admin/src/views/business/receive/Detail.vue
  功能：产品接收单详情（信息/明细/运输/操作日志时间轴）
  权限：business:receive:list/edit/confirm
-->
<template>
  <div class="rc-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品接收管理</el-breadcrumb-item>
      <el-breadcrumb-item>接收单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">接收单详情 - {{ receipt.receipt_no || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/receive/list')">返回列表</el-button>
        <el-button v-if="receipt.status === 0" v-permission="'business:receive:edit'" size="small" @click="$router.push('/business/receive/edit/' + id)">编辑</el-button>
        <el-button v-if="receipt.status === 0" v-permission="'business:receive:confirm'" type="primary" size="small" @click="handleConfirm">确认接收</el-button>
        <el-button v-if="receipt.status === 1" size="small" @click="handleWarehouse">生成入库单</el-button>
        <el-button size="small" @click="window.print()">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="$router.push('/business/receive/list')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="receipt.id">
        <!-- 接收单信息 -->
        <div class="section-title">接收单信息</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="接收单编号">{{ receipt.receipt_no }}</el-descriptions-item>
          <el-descriptions-item label="接收类型"><el-tag size="mini" :type="typeTag(receipt.receipt_type)">{{ receipt.receipt_type_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="客户">{{ receipt.customer_name || receipt.source_location || '-' }}</el-descriptions-item>
          <el-descriptions-item label="关联维修工单">
            <span v-if="receipt.work_order_id" class="link" @click="$router.push('/business/order?category=repair')">{{ receipt.work_order_no }}</span>
            <span v-else>-</span>
          </el-descriptions-item>
          <el-descriptions-item label="客户">{{ receipt.customer_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="接收日期">{{ receipt.receipt_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="接收人">{{ receipt.receiver_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="产品状态"><el-tag size="mini" :type="pStatusTag(receipt.product_status)">{{ receipt.product_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="接收状态"><el-tag size="mini" :type="statusTag(receipt.status)">{{ receipt.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="创建人">{{ receipt.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ receipt.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ receipt.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 产品明细 -->
        <div class="section-title">产品明细</div>
        <el-table :data="items" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column prop="product_code" label="产品编码" width="110" show-overflow-tooltip />
          <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格型号" width="100" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="55" align="center" />
          <el-table-column prop="quantity" label="数量" width="70" align="right" />
          <el-table-column label="产品状态" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="pStatusTag(s.row.product_status)">{{ pStatusLabel(s.row.product_status) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="serial_no" label="设备编号" width="120" show-overflow-tooltip />
          <el-table-column prop="source_location" label="客户" width="140" show-overflow-tooltip />
        </el-table>

        <!-- 运输信息 -->
        <template v-if="transport">
          <div class="section-title">运输信息</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="运输单号">{{ transport.transport_no }}</el-descriptions-item>
            <el-descriptions-item label="运输方式">{{ transport.transport_type_label }}</el-descriptions-item>
            <el-descriptions-item label="车牌号">{{ transport.plate_no || '-' }}</el-descriptions-item>
            <el-descriptions-item label="司机">{{ (transport.driver_name || '') + (transport.driver_phone ? ' ' + transport.driver_phone : '') || '-' }}</el-descriptions-item>
            <el-descriptions-item label="物流公司">{{ transport.logistics_company || '-' }}</el-descriptions-item>
            <el-descriptions-item label="物流单号">{{ transport.track_no || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发车日期">{{ transport.depart_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="预计到达">{{ transport.expected_arrive_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="实际到达">{{ transport.actual_arrive_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="运费">{{ transport.freight_amount ? '¥ ' + Number(transport.freight_amount).toFixed(2) : '-' }}</el-descriptions-item>
            <el-descriptions-item label="发货地址" :span="2">{{ transport.ship_address || '-' }}</el-descriptions-item>
            <el-descriptions-item label="收货地址" :span="2">{{ transport.receive_address || '-' }}</el-descriptions-item>
          </el-descriptions>
        </template>

        <!-- 操作日志 -->
        <div class="section-title">操作日志</div>
        <el-timeline v-if="logs.length">
          <el-timeline-item v-for="(l, i) in logs" :key="i" :timestamp="l.create_time">
            <div><b>{{ l.operator_name || '系统' }}</b> {{ l.action }}{{ l.content ? '：' + l.content : '' }}</div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无操作日志" :image-size="50" />
      </template>
    </el-card>
  </div>
</template>

<script>
import { getReceiveDetail, confirmReceive, warehouseReceive } from '../../../api/purchase'

export default {
  name: 'ProductReceiveDetail',
  data () {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false, loadFailed: false,
      receipt: {}, items: [], transport: null, logs: []
    }
  },
  created () { this.fetchDetail() },
  methods: {
    async fetchDetail () {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getReceiveDetail(this.id)
        if (r.code === 0 && r.data) {
          this.receipt = r.data.receipt || {}
          this.items = r.data.items || []
          this.transport = r.data.transport || null
          this.logs = r.data.logs || []
        } else this.loadFailed = true
      } catch (e) { this.loadFailed = true } finally { this.loading = false }
    },
    typeTag (v) { return { 1: 'primary', 2: 'success', 3: 'warning', 4: 'primary', 5: 'info' }[v] || 'info' },
    pStatusTag (v) { return { 1: 'success', 2: 'warning', 3: 'primary', 4: 'danger', 5: 'info' }[v] || 'info' },
    pStatusLabel (v) { return { 1: '完好', 2: '待维修', 3: '待保养', 4: '报废', 5: '待检验' }[v] || '未知' },
    statusTag (v) { return { 0: 'info', 1: 'primary', 2: 'success', 3: 'primary' }[v] || 'info' },
    handleConfirm () {
      this.$confirm('确认接收该接收单？确认后不可再编辑。', '确认接收', { type: 'info' }).then(async () => {
        try { const r = await confirmReceive(this.id); if (r.code === 0) { this.$message.success('已确认接收'); this.fetchDetail() } } catch (e) {}
      }).catch(() => {})
    },
    handleWarehouse () {
      this.$confirm('确认生成入库单？接收单状态将变为"已入库"。', '生成入库单', { type: 'info' }).then(async () => {
        try { const r = await warehouseReceive(this.id); if (r.code === 0) { this.$message.success(r.msg || '已生成入库单'); this.fetchDetail() } else this.$message.error(r.msg || '操作失败') } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.rc-detail-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.section-title { font-size: 15px; font-weight: 600; margin: 16px 0 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; display: inline-block; vertical-align: middle; }
.link { color: #409EFF; cursor: pointer; }
</style>
