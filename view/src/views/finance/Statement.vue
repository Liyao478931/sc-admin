<!--
  文件：admin/src/views/finance/Statement.vue
  功能：财务报表（资产负债表 / 利润表 / 现金流量表）
  权限：finance:statement:view
-->
<template>
  <div class="statement-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>财务管理</el-breadcrumb-item>
      <el-breadcrumb-item>财务报表</el-breadcrumb-item>
    </el-breadcrumb>

    <el-tabs v-model="activeTab">
      <!-- ============ 资产负债表 ============ -->
      <el-tab-pane label="资产负债表" name="balance">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" @submit.native.prevent>
            <el-form-item label="截止日期">
              <el-date-picker v-model="bs.asOf" type="date" value-format="yyyy-MM-dd" placeholder="选择日期" style="width:150px" @change="loadBalance" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" :loading="loading" @click="loadBalance">生成报表</el-button>
              <el-button icon="el-icon-download" @click="exportCsv('balance')">导出CSV</el-button>
            </el-form-item>
            <el-form-item v-if="bs.data">
              <el-tag :type="bs.data.balanced ? 'success' : 'danger'" size="small">
                {{ bs.data.balanced ? '✓ 借贷平衡' : '✗ 不平衡，差额 ' + fmt(bs.diff) }}
              </el-tag>
            </el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never" v-loading="loading">
          <div class="bs-grid">
            <div class="bs-col">
              <div class="bs-title">资产</div>
              <el-table :data="bs.data ? bs.data.assets : []" size="small" border stripe>
                <el-table-column label="项目" min-width="180">
                  <template slot-scope="s">
                    <span :class="{ 'row-bold': s.row.bold }">{{ s.row.name }}</span>
                  </template>
                </el-table-column>
                <el-table-column label="期末余额（元）" width="160" align="right">
                  <template slot-scope="s">
                    <span :class="{ 'row-bold': s.row.bold }">{{ fmt(s.row.amount) }}</span>
                  </template>
                </el-table-column>
              </el-table>
            </div>
            <div class="bs-col">
              <div class="bs-title">负债和所有者权益</div>
              <el-table :data="bs.data ? bs.data.liabilities_equity : []" size="small" border stripe>
                <el-table-column label="项目" min-width="180">
                  <template slot-scope="s">
                    <span :class="{ 'row-bold': s.row.bold }">{{ s.row.name }}</span>
                  </template>
                </el-table-column>
                <el-table-column label="期末余额（元）" width="160" align="right">
                  <template slot-scope="s">
                    <span :class="{ 'row-bold': s.row.bold }">{{ fmt(s.row.amount) }}</span>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
          <div class="bs-foot" v-if="bs.data">
            截止 {{ bs.data.as_of_date }}：资产总计 {{ fmt(bs.assetsTotal) }} 元 ＝ 负债和所有者权益总计 {{ fmt(bs.liabTotal) }} 元
          </div>
        </el-card>
      </el-tab-pane>

      <!-- ============ 利润表 ============ -->
      <el-tab-pane label="利润表" name="income">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" @submit.native.prevent>
            <el-form-item label="会计月份">
              <el-date-picker v-model="inc.month" type="month" value-format="yyyy-MM" placeholder="选择月份" style="width:150px" @change="loadIncome" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" :loading="loading" @click="loadIncome">生成报表</el-button>
              <el-button icon="el-icon-download" @click="exportCsv('income')">导出CSV</el-button>
            </el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never" v-loading="loading">
          <el-table :data="inc.rows" size="small" border stripe>
            <el-table-column label="项目" min-width="220">
              <template slot-scope="s">
                <span :class="{ 'row-bold': s.row.bold }">{{ s.row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column label="本期金额（元）" width="180" align="right">
              <template slot-scope="s">
                <span :class="{ 'row-bold': s.row.bold, 'num-negative': s.row.amount < 0 }">{{ fmt(s.row.amount) }}</span>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <!-- ============ 现金流量表 ============ -->
      <el-tab-pane label="现金流量表" name="cash">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" @submit.native.prevent>
            <el-form-item label="会计月份">
              <el-date-picker v-model="cf.month" type="month" value-format="yyyy-MM" placeholder="选择月份" style="width:150px" @change="loadCash" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" :loading="loading" @click="loadCash">生成报表</el-button>
              <el-button icon="el-icon-download" @click="exportCsv('cash')">导出CSV</el-button>
            </el-form-item>
            <el-form-item v-if="cf.data">
              <el-tag size="small" type="info">流入 {{ fmt(cf.data.total_in) }} / 流出 {{ fmt(cf.data.total_out) }} / 净额 {{ fmt(cf.data.net) }}</el-tag>
            </el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never" v-loading="loading">
          <el-table :data="cf.items" size="small" border stripe>
            <el-table-column label="项目" min-width="260">
              <template slot-scope="s">
                <span :class="{ 'row-bold': s.row.bold }">{{ s.row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column label="金额（元）" width="180" align="right">
              <template slot-scope="s">
                <span :class="{ 'row-bold': s.row.bold, 'cf-in': s.row.sign === 'in', 'cf-out': s.row.sign === 'out', 'num-negative': (s.row.amount || 0) < 0 }">{{ s.row.sign === 'out' ? '-' + fmt(s.row.amount) : fmt(s.row.amount) }}</span>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'FinanceStatement',
  data() {
    return {
      activeTab: 'balance',
      loading: false,
      bs: { asOf: new Date().toISOString().slice(0, 10), data: null, assetsTotal: 0, liabTotal: 0, diff: 0 },
      inc: { month: new Date().toISOString().slice(0, 7), rows: [] },
      cf: { month: new Date().toISOString().slice(0, 7), data: null, items: [] }
    }
  },
  created() {
    this.loadBalance()
  },
  methods: {
    fmt(v) {
      return (Number(v) || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    async loadBalance() {
      if (!this.bs.asOf) return
      this.loading = true
      try {
        const res = await request({ url: '/finance/statement/balance-sheet', method: 'get', params: { as_of_date: this.bs.asOf } })
        if (res.code === 0) {
          this.bs.data = res.data
          this.bs.assetsTotal = (res.data.assets.find(x => x.bold && x.name.indexOf('总计') > -1) || { amount: 0 }).amount
          this.bs.liabTotal = (res.data.liabilities_equity.find(x => x.bold && x.name.indexOf('总计') > -1) || { amount: 0 }).amount
          this.bs.diff = Math.abs(this.bs.assetsTotal - this.bs.liabTotal)
        } else {
          this.$message.error(res.msg || '生成失败')
        }
      } finally {
        this.loading = false
      }
    },
    async loadIncome() {
      if (!this.inc.month) return
      this.loading = true
      try {
        const res = await request({ url: '/finance/statement/income-statement', method: 'get', params: { month: this.inc.month } })
        if (res.code === 0) {
          this.inc.rows = res.data.rows
        } else {
          this.$message.error(res.msg || '生成失败')
        }
      } finally {
        this.loading = false
      }
    },
    async loadCash() {
      if (!this.cf.month) return
      this.loading = true
      try {
        const res = await request({ url: '/finance/statement/cash-flow', method: 'get', params: { month: this.cf.month } })
        if (res.code === 0) {
          this.cf.data = res.data
          this.cf.items = res.data.items
        } else {
          this.$message.error(res.msg || '生成失败')
        }
      } finally {
        this.loading = false
      }
    },
    exportCsv(kind) {
      let title = '', rows = []
      if (kind === 'balance') {
        if (!this.bs.data) return this.$message.warning('请先生成报表')
        title = `资产负债表（截止 ${this.bs.data.as_of_date}）`
        rows.push(['资产', '金额（元）'], ...this.bs.data.assets.map(r => [r.name, r.amount]))
        rows.push([])
        rows.push(['负债和所有者权益', '金额（元）'], ...this.bs.data.liabilities_equity.map(r => [r.name, r.amount]))
      } else if (kind === 'income') {
        if (!this.inc.rows.length) return this.$message.warning('请先生成报表')
        title = `利润表（${this.inc.month}）`
        rows.push(['项目', '金额（元）'], ...this.inc.rows.map(r => [r.name, r.amount]))
      } else {
        if (!this.cf.items.length) return this.$message.warning('请先生成报表')
        title = `现金流量表（${this.cf.month}）`
        rows.push(['项目', '金额（元）'], ...this.cf.items.map(r => [r.name, r.sign === 'out' ? -(r.amount || 0) : r.amount]))
      }
      const csv = '\ufeff' + title + '\n' + rows.map(r => r.map(x => `"${String(x).replace(/"/g, '""')}"`).join(',')).join('\n')
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
      const a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = title + '.csv'
      a.click()
      URL.revokeObjectURL(a.href)
    }
  }
}
</script>

<style scoped>
.statement-page { padding: 4px; }
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.bs-grid { display: flex; gap: 12px; flex-wrap: wrap; }
.bs-col { flex: 1 1 380px; min-width: 0; }
.bs-title { font-weight: 600; margin-bottom: 8px; color: #303133; }
.bs-foot { margin-top: 10px; color: #909399; font-size: 12px; }
.row-bold { font-weight: 700; }
.num-negative { color: #F56C6C; }
.cf-in { color: #67C23A; }
.cf-out { color: #F56C6C; }
</style>
