<!--
  文件：admin/src/views/production/Cost.vue
  功能：成本核算（自动归集/手工录入/差异分析/费率配置）
  权限：production:cost:view/add/edit/delete/run/config
-->
<template>
  <div class="cost-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>成本核算</el-breadcrumb-item>
    </el-breadcrumb>

    <el-tabs v-model="activeTab" @tab-click="onTab">
      <!-- ============ 核算列表 ============ -->
      <el-tab-pane label="核算列表" name="list">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" label-width="80px" @submit.native.prevent>
            <el-form-item label="关键词">
              <el-input v-model="queryParams.keyword" placeholder="成本单号/产品/工单" clearable style="width:200px" @keyup.enter.native="handleSearch" />
            </el-form-item>
            <el-form-item label="核算期间">
              <el-input v-model="queryParams.period" placeholder="如 2026-09" clearable style="width:110px" @keyup.enter.native="handleSearch" />
            </el-form-item>
            <el-form-item label="核算方式">
              <el-select v-model="queryParams.cost_type" placeholder="全部" clearable style="width:120px" @change="handleSearch">
                <el-option label="自动归集" value="1" />
                <el-option label="手工录入" value="2" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="handleSearch">查询</el-button>
              <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never">
          <div class="toolbar">
            <el-button v-permission="'production:cost:run'" type="primary" size="small" icon="el-icon-cpu" :loading="running" @click="openRun">自动成本核算</el-button>
            <el-button v-permission="'production:cost:add'" size="small" icon="el-icon-plus" @click="openForm()">手工录入</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
            <span class="flex-1"></span>
            <span class="total-tip">共 {{ total }} 条</span>
          </div>

          <el-table :data="list" v-loading="loading" size="small" stripe border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="cost_no" label="成本单号" width="150" align="center" />
            <el-table-column prop="order_no" label="关联工单" width="150" show-overflow-tooltip />
            <el-table-column prop="product_name" label="产品" width="120" show-overflow-tooltip />
            <el-table-column prop="quantity" label="完工数量" width="90" align="right" />
            <el-table-column prop="material_cost" label="材料成本" width="100" align="right" />
            <el-table-column prop="standard_material_cost" label="标准材料" width="110" align="right">
              <template slot-scope="s"><span class="std">{{ s.row.standard_material_cost }}</span></template>
            </el-table-column>
            <el-table-column prop="labor_cost" label="人工成本" width="100" align="right" />
            <el-table-column prop="overhead_cost" label="制造费用" width="100" align="right" />
            <el-table-column prop="total_cost" label="总成本" width="110" align="right">
              <template slot-scope="s"><b class="total">{{ s.row.total_cost }}</b></template>
            </el-table-column>
            <el-table-column prop="unit_cost" label="单位成本" width="110" align="right" />
            <el-table-column label="核算方式" width="90" align="center">
              <template slot-scope="s"><el-tag size="mini" :type="s.row.cost_type === 1 ? 'success' : 'info'">{{ s.row.cost_type_text }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="period" label="期间" width="90" align="center" />
            <el-table-column prop="create_by" label="创建人" width="90" align="center" />
            <el-table-column prop="created_at" label="核算时间" width="160" align="center" />
            <el-table-column label="操作" width="130" align="center" fixed="right">
              <template slot-scope="s">
                <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
                <el-button v-if="s.row.cost_type === 2" v-permission="'production:cost:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
                <el-button v-permission="'production:cost:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row.id)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>

          <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
            :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="queryParams.pageSize"
            :current-page="queryParams.page" @current-change="p => { queryParams.page = p; getList() }"
            @size-change="s => { queryParams.pageSize = s; queryParams.page = 1; getList() }" />
        </el-card>
      </el-tab-pane>

      <!-- ============ 成本差异分析 ============ -->
      <el-tab-pane label="成本差异分析" name="analysis">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" label-width="80px">
            <el-form-item label="核算期间">
              <el-input v-model="analysisPeriod" placeholder="如 2026-09" clearable style="width:130px" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="getAnalysis">分析</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never" class="summary-card" v-if="analysis.summary">
          <el-row :gutter="12">
            <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">实际材料成本</div><div class="sum-value">{{ analysis.summary.material }}</div></div></el-col>
            <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">标准材料成本</div><div class="sum-value">{{ analysis.summary.standard }}</div></div></el-col>
            <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">成本差异</div><div class="sum-value" :class="analysis.summary.diff > 0 ? 'warn' : 'good'">{{ analysis.summary.diff }}</div></div></el-col>
            <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">人工成本</div><div class="sum-value">{{ analysis.summary.labor }}</div></div></el-col>
            <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">制造费用</div><div class="sum-value">{{ analysis.summary.overhead }}</div></div></el-col>
            <el-col :xs="12" :sm="8" :md="4"><div class="sum-item"><div class="sum-label">成本总额</div><div class="sum-value highlight">{{ analysis.summary.total }}</div></div></el-col>
          </el-row>
        </el-card>

        <el-card shadow="never">
          <el-table :data="analysis.items" v-loading="analysisLoading" size="small" stripe border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="order_no" label="工单编号" width="160" />
            <el-table-column prop="product_name" label="产品" width="130" />
            <el-table-column prop="period" label="期间" width="100" align="center" />
            <el-table-column prop="actual" label="实际材料成本" width="130" align="right" />
            <el-table-column prop="standard" label="标准材料成本" width="130" align="right" />
            <el-table-column label="差异额" width="130" align="right">
              <template slot-scope="s"><span :class="s.row.diff > 0 ? 'warn' : 'good'">{{ s.row.diff }}</span></template>
            </el-table-column>
            <el-table-column label="差异率" width="110" align="right">
              <template slot-scope="s"><span :class="s.row.diff_rate > 0 ? 'warn' : 'good'">{{ s.row.diff_rate }}%</span></template>
            </el-table-column>
            <el-table-column label="说明" min-width="200">
              <template slot-scope="s">
                <span v-if="s.row.diff < 0" class="tip-text">实际低于标准（BOM理论），检查领料是否完整</span>
                <span v-else-if="s.row.diff > 0" class="tip-text warn">实际高于标准，检查损耗与价格</span>
                <span v-else>-</span>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!analysisLoading && !analysis.items.length" description="暂无差异分析数据，请先执行自动核算" :image-size="80" />
        </el-card>
      </el-tab-pane>

      <!-- ============ 成本配置 ============ -->
      <el-tab-pane label="成本费率配置" name="config">
        <el-card shadow="never" style="max-width:620px">
          <el-form label-width="160px" size="small" style="margin-top:12px">
            <el-form-item label="工时单价（元/小时）">
              <el-input-number v-model="configForm.labor_hour_rate" :min="0" :precision="2" style="width:200px" />
              <div class="form-tip">人工成本 = 报工工时 × 工时单价</div>
            </el-form-item>
            <el-form-item label="设备小时费率（元/小时）">
              <el-input-number v-model="configForm.equipment_hour_rate" :min="0" :precision="2" style="width:200px" />
              <div class="form-tip">预留：设备折旧/能耗分摊费率</div>
            </el-form-item>
            <el-form-item label="间接费用率（%）">
              <el-input-number v-model="configForm.indirect_cost_rate" :min="0" :max="100" :precision="2" style="width:200px" />
              <div class="form-tip">制造费用 = 间接费用率 ×（材料成本 + 人工成本）</div>
            </el-form-item>
            <el-form-item>
              <el-button v-permission="'production:cost:config'" type="primary" :loading="savingConfig" @click="saveConfig">保存配置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 自动核算弹窗 -->
    <el-dialog title="自动成本核算" :visible.sync="runVisible" width="440px">
      <el-form label-width="100px" size="small">
        <el-form-item label="核算期间">
          <el-input v-model="runPeriod" placeholder="如 2026-09" style="width:200px" />
        </el-form-item>
        <div class="run-tip">
          按期间归集：生产领料 → 材料成本；已通过报工工时 × 工时单价 → 人工成本；间接费率 ×(材料+人工) → 制造费用；按工单生成核算单。
        </div>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="runVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="running" @click="handleRun">开始核算</el-button>
      </div>
    </el-dialog>

    <!-- 手工录入弹窗 -->
    <el-dialog :title="form.id ? '编辑成本核算' : '手工录入成本'" :visible.sync="formVisible" width="520px">
      <el-form ref="costForm" :model="form" label-width="110px" size="small">
        <el-form-item label="产品名称" required>
          <el-input v-model="form.product_name" placeholder="如 液压支架" />
        </el-form-item>
        <el-form-item label="核算期间">
          <el-input v-model="form.period" placeholder="如 2026-09" />
        </el-form-item>
        <el-form-item label="完工数量">
          <el-input-number v-model="form.quantity" :min="0" :precision="4" style="width:200px" />
        </el-form-item>
        <el-form-item label="材料成本">
          <el-input-number v-model="form.material_cost" :min="0" :precision="2" style="width:200px" @change="calcTotal" />
        </el-form-item>
        <el-form-item label="人工成本">
          <el-input-number v-model="form.labor_cost" :min="0" :precision="2" style="width:200px" @change="calcTotal" />
        </el-form-item>
        <el-form-item label="制造费用">
          <el-input-number v-model="form.overhead_cost" :min="0" :precision="2" style="width:200px" @change="calcTotal" />
        </el-form-item>
        <el-form-item label="总成本">
          <b class="total">{{ (form.material_cost + form.labor_cost + form.overhead_cost).toFixed(2) }}</b>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog title="成本核算详情" :visible.sync="detailVisible" width="560px">
      <el-descriptions v-if="detailRow" :column="2" border size="small">
        <el-descriptions-item label="成本单号">{{ detailRow.cost_no }}</el-descriptions-item>
        <el-descriptions-item label="关联工单">{{ detailRow.order_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品">{{ detailRow.product_name }}</el-descriptions-item>
        <el-descriptions-item label="核算期间">{{ detailRow.period }}</el-descriptions-item>
        <el-descriptions-item label="完工数量">{{ detailRow.quantity }}</el-descriptions-item>
        <el-descriptions-item label="核算方式">{{ detailRow.cost_type_text }}</el-descriptions-item>
        <el-descriptions-item label="材料成本">{{ detailRow.material_cost }}</el-descriptions-item>
        <el-descriptions-item label="标准材料成本">{{ detailRow.standard_material_cost }}</el-descriptions-item>
        <el-descriptions-item label="人工成本">{{ detailRow.labor_cost }}</el-descriptions-item>
        <el-descriptions-item label="制造费用">{{ detailRow.overhead_cost }}</el-descriptions-item>
        <el-descriptions-item label="总成本"><b class="total">{{ detailRow.total_cost }}</b></el-descriptions-item>
        <el-descriptions-item label="单位成本">{{ detailRow.unit_cost }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detailRow.create_by || '-' }}</el-descriptions-item>
        <el-descriptions-item label="核算时间">{{ detailRow.created_at }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detailRow.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'ProductionCost',
  data() {
    return {
      activeTab: 'list',
      loading: false, running: false, saving: false, savingConfig: false,
      list: [], total: 0,
      queryParams: { page: 1, pageSize: 10, keyword: '', period: '', cost_type: '' },
      runVisible: false, runPeriod: '',
      formVisible: false, form: { id: 0, product_name: '', period: '', quantity: 0, material_cost: 0, labor_cost: 0, overhead_cost: 0, remark: '' },
      detailVisible: false, detailRow: null,
      analysis: { summary: null, items: [] }, analysisLoading: false, analysisPeriod: '',
      configForm: { labor_hour_rate: 50, equipment_hour_rate: 80, indirect_cost_rate: 15 }
    }
  },
  created() {
    this.getList()
    this.getConfig()
  },
  methods: {
    async req(url, method, data, params) {
      try { return await request({ url, method, data, params }) } catch (e) { this.$message.error('请求失败'); return null }
    },
    async getList() {
      this.loading = true
      const r = await this.req('/cost/list', 'get', null, { ...this.queryParams })
      if (r && r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      this.loading = false
    },
    async getConfig() {
      const r = await this.req('/cost/config', 'get')
      if (r && r.code === 0 && r.data.config) Object.assign(this.configForm, r.data.config)
    },
    async getAnalysis() {
      this.analysisLoading = true
      const r = await this.req('/cost/analysis', 'get', null, { period: this.analysisPeriod })
      if (r && r.code === 0) this.analysis = r.data
      this.analysisLoading = false
    },
    onTab() { if (this.activeTab === 'analysis' && !this.analysis.items.length) this.getAnalysis() },
    handleSearch() { this.queryParams.page = 1; this.getList() },
    handleReset() { this.queryParams = { page: 1, pageSize: this.queryParams.pageSize, keyword: '', period: '', cost_type: '' }; this.handleSearch() },
    openRun() { this.runPeriod = new Date().toISOString().slice(0, 7); this.runVisible = true },
    async handleRun() {
      if (!/^\d{4}-\d{2}$/.test(this.runPeriod || '')) { this.$message.warning('请输入正确的核算期间，如 2026-09'); return }
      this.running = true
      const r = await this.req('/cost/run', 'post', { period: this.runPeriod })
      if (r && r.code === 0) {
        this.$message.success(`核算完成：新增 ${r.data.created} 条，更新 ${r.data.updated} 条（${r.data.orders} 个工单）`)
        this.runVisible = false
        this.getList()
      } else if (r) this.$message.error(r.msg || '核算失败')
      this.running = false
    },
    calcTotal() {},
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, product_name: '', period: new Date().toISOString().slice(0, 7), quantity: 0, material_cost: 0, labor_cost: 0, overhead_cost: 0, remark: '' }
      this.formVisible = true
    },
    async handleSave() {
      if (!this.form.product_name) { this.$message.warning('产品名称不能为空'); return }
      this.saving = true
      const r = await this.req('/cost/save', 'post', this.form)
      if (r && r.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.getList() }
      else if (r) this.$message.error(r.msg || '保存失败')
      this.saving = false
    },
    async handleDelete(id) {
      this.$confirm('确认删除该核算记录？', '提示', { type: 'warning' }).then(async () => {
        const r = await this.req('/cost/delete', 'post', { id })
        if (r && r.code === 0) { this.$message.success('删除成功'); this.getList() }
      }).catch(() => {})
    },
    async viewDetail(id) {
      const r = await this.req(`/cost/detail/${id}`, 'get')
      if (r && r.code === 0) { this.detailRow = r.data.row; this.detailVisible = true }
    },
    async saveConfig() {
      this.savingConfig = true
      const r = await this.req('/cost/config', 'post', this.configForm)
      if (r && r.code === 0) this.$message.success('配置已保存')
      this.savingConfig = false
    }
  }
}
</script>

<style scoped>
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { color: #909399; font-size: 13px; }
.pager { margin-top: 12px; text-align: right; }
.total { color: #409EFF; }
.std { color: #909399; }
.warn { color: #E6A23C; font-weight: 600; }
.good { color: #67C23A; font-weight: 600; }
.highlight { color: #409EFF; }
.sum-item { padding: 8px 4px; }
.sum-label { color: #909399; font-size: 12px; margin-bottom: 4px; }
.sum-value { font-size: 15px; font-weight: 600; color: #303133; }
.summary-card { margin-bottom: 12px; }
.tip-text { color: #909399; font-size: 12px; }
.form-tip { color: #909399; font-size: 12px; margin-top: 4px; }
.run-tip { background: #F0F9EB; border: 1px solid #E1F3D8; color: #67C23A; border-radius: 6px; padding: 10px 12px; font-size: 12px; line-height: 1.7; }
.danger { color: #F56C6C; }
</style>
