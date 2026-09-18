<!--
  文件：admin/src/views/warehouse/setting/material/detail/Detail.vue
  功能：物料详情（基本信息/库存分布/库存流水）
  权限：warehouse:setting:material:view
-->
<template>
  <div class="detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>物料管理</el-breadcrumb-item>
      <el-breadcrumb-item>物料详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="detail-header">
      <span class="detail-title">物料详情 - {{ detail.material_name || '...' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push('/warehouse/setting/material')">返回列表</el-button>
        <el-button size="small" type="primary" icon="el-icon-edit" @click="$router.push('/warehouse/setting/material')">编辑</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <!-- 基本信息 -->
    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>基本信息</span></div>
      <el-descriptions v-if="detail.id" :column="2" border size="small">
        <el-descriptions-item label="物料编码">{{ detail.material_code }}</el-descriptions-item>
        <el-descriptions-item label="物料名称">{{ detail.material_name }}</el-descriptions-item>
        <el-descriptions-item label="规格型号">{{ detail.specification || '-' }}</el-descriptions-item>
        <el-descriptions-item label="单位">{{ detail.unit }}</el-descriptions-item>
        <el-descriptions-item label="物料类型"><el-tag :type="detail.material_type_tag" size="mini">{{ detail.material_type_label }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="物料分类">{{ detail.category_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="安全库存量">{{ Number(detail.safety_stock || 0).toLocaleString() }} {{ detail.unit }}</el-descriptions-item>
        <el-descriptions-item label="采购周期">{{ detail.purchase_cycle || 0 }} 天</el-descriptions-item>
        <el-descriptions-item label="参考采购单价">¥ {{ Number(detail.reference_price || 0).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="参考成本单价">¥ {{ Number(detail.reference_cost || 0).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="计价方式">{{ detail.costing_method === 2 ? '先进先出' : '移动加权平均' }}</el-descriptions-item>
        <el-descriptions-item label="加权平均单价">¥ {{ Number(detail.avg_cost_price || 0).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="默认供应商">{{ detail.supplier_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="存放货位">{{ detail.location_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态"><el-tag :type="detail.status === 1 ? 'success' : 'info'" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.create_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detail.update_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 库存信息 -->
    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>库存信息</span></div>
      <div class="stock-total">当前总库存：<span :class="detail.current_stock < detail.safety_stock ? 'stock-warning' : ''">{{ Number(detail.current_stock || 0).toLocaleString() }} {{ detail.unit }}</span></div>
      <el-table :data="distribution" size="small" border empty-text="暂无库存记录">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column prop="warehouse_name" label="仓库名称" />
        <el-table-column label="库存数量" align="right"><template slot-scope="s">{{ Number(s.row.stock || 0).toLocaleString() }} {{ detail.unit }}</template></el-table-column>
      </el-table>
    </el-card>

    <!-- 库存流水 -->
    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>库存流水</span></div>
      <el-table :data="flowList" size="small" border empty-text="暂无库存流水">
        <el-table-column prop="flow_time" label="时间" width="170" />
        <el-table-column prop="flow_type_label" label="变动类型" width="100" />
        <el-table-column label="数量" width="110" align="right">
          <template slot-scope="s"><span :class="Number(s.row.flow_quantity) >= 0 ? 'up' : 'down'">{{ Number(s.row.flow_quantity) > 0 ? '+' : '' }}{{ Number(s.row.flow_quantity).toLocaleString() }}</span></template>
        </el-table-column>
        <el-table-column label="变动前库存" width="110" align="right"><template slot-scope="s">{{ Number(s.row.before_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="变动后库存" width="110" align="right"><template slot-scope="s">{{ Number(s.row.after_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column prop="ref_no" label="关联单据" width="150" show-overflow-tooltip />
        <el-table-column label="仓库" width="110" show-overflow-tooltip><template slot-scope="s">{{ s.row.warehouse_name || '-' }}</template></el-table-column>
        <el-table-column prop="operator_name" label="操作人" width="100" />
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="flowTotal" :page-size="flowPageSize" :current-page="flowPage"
        @current-change="p => { flowPage = p; loadFlow() }" v-if="flowTotal > flowPageSize" />
    </el-card>
  </div>
</template>

<script>
import { getMaterialDetail, getMaterialStockDistribution, getMaterialStockFlow } from '../../../../../api/warehouse'

export default {
  name: 'WarehouseSettingMaterialDetail',
  data () {
    return {
      id: Number(this.$route.params.id) || 0,
      detail: {}, distribution: [], flowList: [], flowTotal: 0, flowPage: 1, flowPageSize: 20
    }
  },
  created () {
    this.loadDetail()
    this.loadDistribution()
    this.loadFlow()
  },
  methods: {
    async loadDetail () {
      try {
        const r = await getMaterialDetail(this.id)
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
    },
    async loadDistribution () {
      try {
        const r = await getMaterialStockDistribution(this.id)
        if (r.code === 0) this.distribution = r.data || []
      } catch (e) { this.distribution = [] }
    },
    async loadFlow () {
      try {
        const r = await getMaterialStockFlow(this.id, { page: this.flowPage, pageSize: this.flowPageSize })
        if (r.code === 0 && r.data) { this.flowList = r.data.list || []; this.flowTotal = r.data.total || 0 }
      } catch (e) { this.flowList = [] }
    },
    handlePrint () { window.print() }
  }
}
</script>

<style scoped>
.detail-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.detail-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.detail-title { font-size: 18px; font-weight: 700; color: #303133; }
.info-card { margin-bottom: 14px; }
.card-head { font-size: 15px; font-weight: 600; }
.stock-total { font-size: 14px; margin-bottom: 10px; }
.stock-warning { color: #F56C6C; font-weight: 600; }
.up { color: #67C23A; }
.down { color: #F56C6C; }
.pager { margin-top: 12px; text-align: right; }
</style>
