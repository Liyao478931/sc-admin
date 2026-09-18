<!--
  文件：admin/src/views/finance/Aging.vue
  功能：应收应付账龄分析
  权限：finance:aging:view
-->
<template>
  <div class="aging-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>财务管理</el-breadcrumb-item>
      <el-breadcrumb-item>账龄分析</el-breadcrumb-item>
    </el-breadcrumb>

    <el-tabs v-model="type" @tab-click="load">
      <el-tab-pane label="应收账款" name="receivable" />
      <el-tab-pane label="应付账款" name="payable" />
    </el-tabs>

    <!-- 账龄分桶卡片 -->
    <div class="bucket-row">
      <div v-for="b in buckets" :key="b.key" class="bucket-card" :class="'bucket-' + b.key" @click="filterBucket(b.key)">
        <div class="bucket-name">{{ b.name }}</div>
        <div class="bucket-amount">{{ fmt(b.amount) }}</div>
        <div class="bucket-count">{{ b.count }} 笔</div>
      </div>
    </div>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="往来方">
          <el-input v-model="q.partner" placeholder="客户/供应商" clearable style="width:160px" @keyup.enter.native="load" />
        </el-form-item>
        <el-form-item label="账龄区间">
          <el-select v-model="q.bucket" clearable placeholder="全部" style="width:150px" @change="load">
            <el-option v-for="b in buckets" :key="b.key" :label="b.name" :value="b.key" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" :loading="loading" @click="load">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <el-button type="success" icon="el-icon-download" @click="doExport">导出CSV</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <div class="toolbar">
        <span class="total-tip">共 {{ filtered.length }} 笔，余额合计 <b class="sum-text">{{ fmt(filteredTotal) }}</b> 元</span>
        <span style="flex:1"></span>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="load">刷新</el-button>
      </div>
      <el-table :data="filtered" v-loading="loading" size="small" border stripe>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="bill_no" label="单据号" width="160" show-overflow-tooltip />
        <el-table-column prop="partner" label="往来方" min-width="140" show-overflow-tooltip />
        <el-table-column label="单据金额" width="120" align="right">
          <template slot-scope="s">{{ fmt(s.row.amount) }}</template>
        </el-table-column>
        <el-table-column :label="'已' + (type === 'receivable' ? '收款' : '付款')" width="110" align="right">
          <template slot-scope="s">{{ fmt(s.row.settled) }}</template>
        </el-table-column>
        <el-table-column label="余额" width="120" align="right">
          <template slot-scope="s"><b>{{ fmt(s.row.balance) }}</b></template>
        </el-table-column>
        <el-table-column prop="due_date" label="到期日" width="110" align="center" />
        <el-table-column label="逾期天数" width="90" align="center">
          <template slot-scope="s">
            <span v-if="s.row.days_overdue > 0" class="overdue">{{ s.row.days_overdue }} 天</span>
            <span v-else class="not-due">—</span>
          </template>
        </el-table-column>
        <el-table-column label="账龄区间" width="130" align="center">
          <template slot-scope="s">
            <el-tag :type="bucketTag(s.row.bucket)" size="mini">{{ s.row.bucket_name }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="收款状态" width="100" align="center">
          <template slot-scope="s">
            <el-tag :type="s.row.status_text.indexOf('部分') > -1 ? 'warning' : 'info'" size="mini">{{ s.row.status_text }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import request from '@/api/request'
import { getToken } from '@/utils/auth'

export default {
  name: 'FinanceAging',
  data() {
    return {
      type: 'receivable',
      loading: false,
      list: [],
      buckets: [
        { key: 'not_due', name: '未到期', amount: 0, count: 0 },
        { key: 'overdue_30', name: '逾期1-30天', amount: 0, count: 0 },
        { key: 'overdue_60', name: '逾期31-60天', amount: 0, count: 0 },
        { key: 'overdue_90', name: '逾期61-90天', amount: 0, count: 0 },
        { key: 'overdue_plus', name: '逾期90天以上', amount: 0, count: 0 }
      ],
      q: { partner: '', bucket: '' }
    }
  },
  computed: {
    filtered() {
      let rows = this.list
      if (this.q.partner) {
        rows = rows.filter(r => (r.partner || '').indexOf(this.q.partner) > -1)
      }
      if (this.q.bucket) {
        rows = rows.filter(r => r.bucket === this.q.bucket)
      }
      return rows
    },
    filteredTotal() {
      return this.filtered.reduce((s, r) => s + (Number(r.balance) || 0), 0)
    }
  },
  created() {
    this.load()
  },
  methods: {
    fmt(v) {
      return (Number(v) || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/finance/aging', method: 'get', params: { type: this.type } })
        if (res.code === 0) {
          this.list = res.data.list
          this.buckets = [
            { key: 'not_due', name: '未到期', amount: res.data.buckets.not_due.amount, count: res.data.buckets.not_due.count },
            { key: 'overdue_30', name: '逾期1-30天', amount: res.data.buckets.overdue_30.amount, count: res.data.buckets.overdue_30.count },
            { key: 'overdue_60', name: '逾期31-60天', amount: res.data.buckets.overdue_60.amount, count: res.data.buckets.overdue_60.count },
            { key: 'overdue_90', name: '逾期61-90天', amount: res.data.buckets.overdue_90.amount, count: res.data.buckets.overdue_90.count },
            { key: 'overdue_plus', name: '逾期90天以上', amount: res.data.buckets.overdue_plus.amount, count: res.data.buckets.overdue_plus.count }
          ]
        } else {
          this.$message.error(res.msg || '加载失败')
        }
      } finally {
        this.loading = false
      }
    },
    filterBucket(key) {
      this.q.bucket = this.q.bucket === key ? '' : key
    },
    reset() {
      this.q.partner = ''
      this.q.bucket = ''
      this.load()
    },
    bucketTag(k) {
      return { not_due: 'success', overdue_30: '', overdue_60: 'warning', overdue_90: 'warning', overdue_plus: 'danger' }[k] || 'info'
    },
    doExport() {
      const url = '/api/finance/aging/export?type=' + this.type
      fetch(url, { headers: { Authorization: 'Bearer ' + (getToken() || '') } })
        .then(r => r.blob())
        .then(blob => {
          const a = document.createElement('a')
          a.href = URL.createObjectURL(blob)
          a.download = (this.type === 'receivable' ? '应收账龄分析' : '应付账龄分析') + '.csv'
          a.click()
          URL.revokeObjectURL(a.href)
        })
        .catch(() => this.$message.error('导出失败'))
    }
  }
}
</script>

<style scoped>
.aging-page { padding: 4px; }
.breadcrumb { margin-bottom: 12px; }
.bucket-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 12px; }
.bucket-card {
  flex: 1 1 150px; min-width: 0; padding: 12px 14px; border-radius: 10px;
  cursor: pointer; border: 1px solid #ebeef5; background: #fff; transition: all .2s;
}
.bucket-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,.06); }
.bucket-name { font-size: 12px; color: #909399; }
.bucket-amount { font-size: 18px; font-weight: 700; margin: 4px 0 2px; color: #303133; }
.bucket-count { font-size: 12px; color: #c0c4cc; }
.bucket-not_due { border-top: 3px solid #67C23A; }
.bucket-overdue_30 { border-top: 3px solid #409EFF; }
.bucket-overdue_60 { border-top: 3px solid #E6A23C; }
.bucket-overdue_90 { border-top: 3px solid #E6A23C; }
.bucket-overdue_plus { border-top: 3px solid #F56C6C; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin-bottom: 10px; }
.sum-text { color: #409EFF; }
.overdue { color: #F56C6C; font-weight: 600; }
.not-due { color: #c0c4cc; }
</style>
