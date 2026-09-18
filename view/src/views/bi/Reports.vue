<template>
  <div class="page-container">
    <el-row :gutter="14" class="stat-row">
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ cards.customer_count || 0 }}</div><div class="stat-label">客户数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ cards.supplier_count || 0 }}</div><div class="stat-label">供应商数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ cards.order_count || 0 }}</div><div class="stat-label">订单数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num red">¥{{ Number(cards.order_amount || 0).toLocaleString() }}</div><div class="stat-label">订单金额</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ cards.work_order_count || 0 }}</div><div class="stat-label">工单数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ cards.device_count || 0 }}</div><div class="stat-label">设备数</div></el-card></el-col>
    </el-row>
    <el-row :gutter="14" class="stat-row2">
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ cards.employee_count || 0 }}</div><div class="stat-label">员工数</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ cards.inventory_count || 0 }}</div><div class="stat-label">库存物料数</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num green">¥{{ Number(cards.expense_total || 0).toLocaleString() }}</div><div class="stat-label">费用报销总额</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ cards.contract_count || 0 }}</div><div class="stat-label">合同数</div></el-card></el-col>
    </el-row>
    <el-row :gutter="14">
      <el-col :span="16">
        <el-card shadow="never" header="近6个月订单趋势">
          <div ref="trendChart" style="height:320px"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" header="报表配置">
          <div class="toolbar">
            <el-button v-permission="'bi:report:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增配置</el-button>
          </div>
          <el-table :data="cfgList" v-loading="loading" border stripe size="small" max-height="330">
            <el-table-column prop="name" label="报表名称" min-width="110" />
            <el-table-column prop="code" label="编码" width="90" />
            <el-table-column label="操作" width="110">
              <template #default="{row}">
                <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
                <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
    <el-dialog :title="form.id ? '编辑报表配置' : '新增报表配置'" :visible.sync="formVisible" width="520px">
      <el-form :model="form" label-width="85px" size="small">
        <el-form-item label="报表名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="编码" required><el-input v-model="form.code" placeholder="如 RPT-DASH-01" /></el-form-item>
        <el-form-item label="分类"><el-select v-model="form.category" style="width:100%"><el-option label="综合" value="综合" /><el-option label="销售" value="销售" /><el-option label="生产" value="生产" /><el-option label="财务" value="财务" /><el-option label="人力" value="人力" /></el-select></el-form-item>
        <el-form-item label="配置JSON"><el-input v-model="form.config" type="textarea" :rows="3" placeholder="可选，JSON 配置" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>
<script>
import request from '@/api/request'
import echarts from '@/utils/echarts'
export default {
  name: 'BiReports',
  data() {
    return {
      loading: false, saving: false, cards: {}, trend: [], cfgList: [], formVisible: false, chart: null,
      form: { id: 0, name: '', code: '', category: '综合', config: '', status: 1 }
    }
  },
  created() { this.load() },
  mounted() { this.$nextTick(() => this.renderChart()) },
  methods: {
    async load() {
      this.loading = true
      try {
        const [dataRes, cfgRes] = await Promise.all([
          request({ url: '/bi/data', method: 'get' }),
          request({ url: '/bi/list', method: 'get', params: { page: 1, pageSize: 50 } })
        ])
        if (dataRes.code === 0) { this.cards = dataRes.data.cards || {}; this.trend = dataRes.data.trend || [] }
        if (cfgRes.code === 0) this.cfgList = cfgRes.data.list || []
        this.renderChart()
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    renderChart() {
      if (!this.$refs.trendChart) return
      if (this.chart) this.chart.dispose()
      this.chart = echarts.init(this.$refs.trendChart)
      this.chart.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['订单数', '订单金额'] },
        grid: { left: 50, right: 50, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: this.trend.map(x => x.month) },
        yAxis: [{ type: 'value', name: '订单数' }, { type: 'value', name: '金额' }],
        series: [
          { name: '订单数', type: 'bar', data: this.trend.map(x => x.count), itemStyle: { color: '#409EFF' } },
          { name: '订单金额', type: 'line', yAxisIndex: 1, smooth: true, data: this.trend.map(x => x.amount), itemStyle: { color: '#67C23A' } }
        ]
      })
    },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, name: '', code: '', category: '综合', config: '', status: 1 }
      this.formVisible = true
    },
    async save() {
      if (!this.form.name || !this.form.code) return this.$message.warning('名称和编码必填')
      this.saving = true
      try {
        const res = await request({ url: '/bi/save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    del(row) {
      this.$confirm('确认删除报表配置 ' + row.name + '？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/bi/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.stat-row, .stat-row2 { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 21px; font-weight: 700; color: #333; }
.stat-num.blue { color: #409EFF; } .stat-num.orange { color: #E6A23C; } .stat-num.red { color: #F56C6C; } .stat-num.green { color: #67C23A; }
.stat-label { color: #909399; font-size: 12px; margin-top: 4px; }
.toolbar { margin-bottom: 10px; }
</style>
