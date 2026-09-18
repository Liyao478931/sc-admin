<!--
  文件：admin/src/views/production/mrp/Detail.vue
  功能：MRP物料需求计划 - 运算批次详情（批次汇总 + 需求明细/筛选/状态流转/导出）
  权限：production:mrp:view/run/export
-->
<template>
  <div class="mrp-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产计划</el-breadcrumb-item>
      <el-breadcrumb-item>物料需求计划</el-breadcrumb-item>
      <el-breadcrumb-item>批次详情</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 批次汇总 -->
    <el-card shadow="never" class="summary-card" v-if="run">
      <el-row :gutter="12">
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">批次编号</div><div class="sum-value">{{ run.run_no }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">运算名称</div><div class="sum-value ellipsis" :title="run.run_name">{{ run.run_name }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">运算范围</div><div class="sum-value">{{ run.scope_type_text }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">状态</div><div class="sum-value"><el-tag size="mini" :type="run.status === 2 ? 'success' : (run.status === 3 ? 'warning' : 'info')">{{ run.status_text }}</el-tag></div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">参与工单</div><div class="sum-value">{{ run.total_orders }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">需求物料</div><div class="sum-value">{{ run.total_items }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">毛需求总量</div><div class="sum-value highlight">{{ run.total_demand }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">净需求总量</div><div class="sum-value warn">{{ run.total_net }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">建议行数</div><div class="sum-value">{{ run.total_suggest }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">无BOM产品</div><div class="sum-value ellipsis" :title="run.no_bom_products || '-'">{{ run.no_bom_products || '-' }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">创建人</div><div class="sum-value">{{ run.created_by_name }}</div></div></el-col>
        <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">运算时间</div><div class="sum-value ellipsis">{{ run.create_time }}</div></div></el-col>
      </el-row>
    </el-card>

    <!-- 需求明细 -->
    <el-card shadow="never">
      <div class="toolbar">
        <span class="bar-title">需求明细</span>
        <el-input v-model="queryParams.keyword" placeholder="物料编码/名称" clearable size="small" style="width:200px" @keyup.enter.native="handleSearch" @clear="handleSearch" />
        <el-select v-model="queryParams.suggest_type" placeholder="建议类型" clearable size="small" style="width:120px" @change="handleSearch">
          <el-option label="采购" value="1" />
          <el-option label="自制" value="2" />
          <el-option label="外协" value="3" />
        </el-select>
        <el-select v-model="queryParams.demand_status" placeholder="状态" clearable size="small" style="width:120px" @change="handleSearch">
          <el-option label="待处理" value="1" />
          <el-option label="已转采购" value="2" />
          <el-option label="已关闭" value="3" />
        </el-select>
        <el-button type="primary" size="small" icon="el-icon-search" @click="handleSearch">搜索</el-button>
        <el-button v-permission="'production:mrp:export'" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="product_code" label="物料编码" width="110" show-overflow-tooltip />
        <el-table-column prop="product_name" label="物料名称" width="140" show-overflow-tooltip />
        <el-table-column prop="product_spec" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="60" align="center" />
        <el-table-column prop="level" label="层级" width="60" align="center" />
        <el-table-column label="来源" width="80" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.source_type === 1 ? 'warning' : (s.row.source_type === 2 ? 'success' : 'primary')">{{ s.row.source_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="demand_qty" label="毛需求" width="100" align="right" />
        <el-table-column prop="stock_qty" label="现有库存" width="100" align="right" />
        <el-table-column prop="in_transit_qty" label="在途" width="90" align="right" />
        <el-table-column prop="net_demand" label="净需求" width="110" align="right">
          <template slot-scope="s"><span :class="Number(s.row.net_demand) > 0 ? 'warn' : ''">{{ s.row.net_demand }}</span></template>
        </el-table-column>
        <el-table-column label="建议类型" width="80" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.suggest_type === 1 ? 'success' : (s.row.suggest_type === 2 ? 'warning' : 'primary')">{{ s.row.suggest_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="suggestion" label="建议说明" min-width="260" show-overflow-tooltip />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 1 ? 'info' : (s.row.status === 2 ? 'success' : 'danger')">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="from_orders" label="来源工单" width="160" show-overflow-tooltip />
        <el-table-column label="操作" width="140" align="center" fixed="right">
          <template slot-scope="s">
            <el-button v-if="s.row.status === 1 && s.row.suggest_type === 1" v-permission="'production:mrp:run'" type="text" size="mini" @click="changeStatus(s.row.id, 2)">转采购</el-button>
            <el-button v-if="s.row.status === 1" v-permission="'production:mrp:run'" type="text" size="mini" class="danger" @click="changeStatus(s.row.id, 3)">关闭</el-button>
            <span v-if="s.row.status !== 1">-</span>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        class="pager"
        background
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        :page-size="queryParams.pageSize"
        :current-page="queryParams.page"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>
  </div>
</template>

<script>
import { getMrpDetail, exportMrp, updateMrpStatus } from '../../../api/production'

export default {
  name: 'ProductionMrpDetail',
  data() {
    return {
      runId: 0,
      loading: false,
      run: null,
      list: [],
      total: 0,
      queryParams: { page: 1, pageSize: 10, keyword: '', suggest_type: '', demand_status: '' }
    }
  },
  created() {
    this.runId = Number(this.$route.params.id || 0)
    this.getDetail()
  },
  methods: {
    async getDetail() {
      this.loading = true
      try {
        const r = await getMrpDetail(this.runId, this.queryParams)
        if (r.code === 0) { this.run = r.data.run || null; this.list = r.data.items || []; this.total = r.data.total || 0 }
        else { this.$message.error(r.msg || '加载失败') }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    handleSearch() { this.queryParams.page = 1; this.getDetail() },
    handlePageChange(p) { this.queryParams.page = p; this.getDetail() },
    handleSizeChange(size) { this.queryParams.pageSize = size; this.queryParams.page = 1; this.getDetail() },
    handleExport() {
      exportMrp(this.runId).then(res => {
        const blob = new Blob([res], { type: 'text/csv;charset=utf-8' })
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = 'MRP_' + (this.run ? this.run.run_no : this.runId) + '.csv'
        link.click()
      })
    },
    changeStatus(id, status) {
      const tip = status === 2 ? '确认将该物料需求标记为「已转采购」？' : '确认关闭该物料需求？'
      this.$confirm(tip, '提示', { type: 'warning' }).then(async () => {
        const r = await updateMrpStatus(id, status)
        if (r.code === 0) { this.$message.success('已更新'); this.getDetail() } else { this.$message.error(r.msg || '操作失败') }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.breadcrumb { margin-bottom: 12px; }
.summary-card { margin-bottom: 12px; }
.sum-item { padding: 8px 4px; }
.sum-label { color: #909399; font-size: 12px; margin-bottom: 4px; }
.sum-value { font-size: 15px; font-weight: 600; color: #303133; }
.sum-value.highlight { color: #409EFF; }
.sum-value.warn { color: #E6A23C; }
.sum-value.ellipsis { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.toolbar { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
.bar-title { font-size: 14px; font-weight: 600; margin-right: 8px; }
.flex-1 { flex: 1; }
.total-tip { color: #909399; font-size: 13px; }
.warn { color: #E6A23C; font-weight: 600; }
.danger { color: #F56C6C; }
.pager { margin-top: 12px; text-align: right; }
</style>
