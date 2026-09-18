<template>
  <div class="accident-statistics-page">
    <!-- 概览统计卡片 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="4" v-for="card in statCards" :key="card.label">
        <el-card shadow="never" :body-style="{ padding: '14px 16px' }">
          <div class="stat-card">
            <div class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="card.icon" /></div>
            <div class="stat-info"><div class="stat-num">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第一行：趋势 + 类型分布 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
            <span>事故趋势（近12个月）</span>
            <el-select v-model="trendYear" size="mini" style="width:110px;" @change="loadTrend">
              <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
            </el-select>
          </div>
          <div ref="trendChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.trend" class="chart-error">趋势图错误：{{ chartErrors.trend }}</div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header">事故类型分布</div>
          <div ref="typeChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.type" class="chart-error">类型图错误：{{ chartErrors.type }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第二行：等级分布 + 部门分布 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header">事故等级分布</div>
          <div ref="levelChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.level" class="chart-error">等级图错误：{{ chartErrors.level }}</div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header">部门事故分布</div>
          <div ref="deptChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.dept" class="chart-error">部门图错误：{{ chartErrors.dept }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第三行：交叉分析 + 伤亡排行 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header">事故类型×等级交叉分析</div>
          <div ref="crossChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.cross" class="chart-error">交叉图错误：{{ chartErrors.cross }}</div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header">伤亡情况 TOP10</div>
          <div ref="casualtyChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.casualty" class="chart-error">伤亡图错误：{{ chartErrors.casualty }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第四行：经济损失排行 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="24">
        <el-card shadow="never">
          <div slot="header">经济损失 TOP10</div>
          <div ref="economicChart" style="width:100%;height:300px;"></div>
          <div v-if="chartErrors.economic" class="chart-error">损失图错误：{{ chartErrors.economic }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 事故明细 -->
    <el-card shadow="never">
      <div slot="header">事故明细</div>
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-select v-model="filters.accident_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.accident_level" clearable placeholder="全部等级" style="width:120px" @change="onSearch">
            <el-option v-for="l in levelOptions" :key="l.value" :label="l.label" :value="l.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" size="small" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button size="small" icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <el-button v-if="hasPerm('safety:accident:statistics:export')" size="small" type="primary" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出报表</el-button>
        </el-form-item>
      </el-form>
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="accident_code" label="事故编号" width="155" />
        <el-table-column prop="accident_name" label="事故名称" min-width="150" show-overflow-tooltip />
        <el-table-column label="事故类型" width="95" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="typeTag(row.accident_type)">{{ row.type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="事故等级" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="levelTag(row.accident_level)">{{ row.level_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="happen_time" label="发生时间" width="155" align="center" />
        <el-table-column prop="happen_department_name" label="发生部门" width="110" show-overflow-tooltip />
        <el-table-column prop="death_count" label="死亡" width="65" align="center" />
        <el-table-column prop="serious_injury_count" label="重伤" width="65" align="center" />
        <el-table-column prop="minor_injury_count" label="轻伤" width="65" align="center" />
        <el-table-column prop="economic_loss" label="损失(万元)" width="90" align="center" />
        <el-table-column label="状态" width="85" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="statusTag(row.status)">{{ row.status_text }}</el-tag></template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadDetail" @size-change="loadDetail" />
    </el-card>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import {
  getAccidentOverview, getAccidentTrend, getTypeDistribution, getLevelDistribution,
  getDepartmentDistribution, getTypeLevelCross, getCasualtyRanking, getEconomicRanking,
  getAccidentDetailList, exportAccidentStatistics,
} from '@/api/safetyAccident'
import { getDictByCode } from '@/api/dictionary'

export default {
  name: 'AccidentStatistics',
  data() {
    return {
      statCards: [
        { label: '事故总数', value: 0, icon: 'el-icon-document', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '死亡总人数', value: 0, icon: 'el-icon-remove', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
        { label: '重伤总人数', value: 0, icon: 'el-icon-warning', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '轻伤总人数', value: 0, icon: 'el-icon-info', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '经济损失(万元)', value: 0, icon: 'el-icon-money', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '事故率(/百万工时)', value: 0, icon: 'el-icon-data-line', color: '#8B5CF6', bg: 'rgba(139,92,246,.12)' },
      ],
      trendYear: new Date().getFullYear(),
      yearOptions: [],
      typeOptions: [], levelOptions: [],
      filters: { accident_type: '', accident_level: '' },
      dateRange: null,
      list: [], total: 0, page: 1, limit: 10, loading: false, exporting: false,
      charts: {}, chartErrors: {},
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    const y = new Date().getFullYear()
    this.yearOptions = [y - 2, y - 1, y]
    this.loadOptions()
  },
  mounted() {
    window.addEventListener('resize', this.resizeCharts)
    this.$nextTick(() => {
      this.initCharts()
      this.loadAll()
      setTimeout(() => this.resizeCharts(), 300)
    })
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeCharts)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
    this.charts = {}
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadOptions() {
      try {
        const [t, l] = await Promise.all([getDictByCode('safety_accident_type'), getDictByCode('safety_accident_level')])
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
        this.levelOptions = (l.data || []).map(x => ({ label: x.label, value: x.value }))
      } catch (e) {}
    },
    initCharts() {
      const map = { trend: 'trendChart', type: 'typeChart', level: 'levelChart', dept: 'deptChart', cross: 'crossChart', casualty: 'casualtyChart', economic: 'economicChart' }
      Object.entries(map).forEach(([key, ref]) => {
        try {
          const el = this.$refs[ref]
          if (!el) { this.$set(this.chartErrors, key, '图表容器未找到'); return }
          if (!this.charts[key]) this.charts[key] = echarts.init(el)
          this.$set(this.chartErrors, key, '')
        } catch (e) { this.$set(this.chartErrors, key, e.message) }
      })
    },
    resizeCharts() { Object.values(this.charts).forEach(c => { if (c) c.resize() }) },
    safeSet(key, option) {
      try {
        if (!this.charts[key]) { this.$set(this.chartErrors, key, this.chartErrors[key] || '图表未初始化'); return }
        this.charts[key].setOption(option)
        this.charts[key].resize()
        this.$set(this.chartErrors, key, '')
      } catch (e) { this.$set(this.chartErrors, key, e.message) }
    },
    async loadAll() {
      this.loadOverview()
      this.loadTrend()
      this.loadType()
      this.loadLevel()
      this.loadDept()
      this.loadCross()
      this.loadCasualty()
      this.loadEconomic()
      this.loadDetail()
    },
    async loadOverview() {
      try {
        const r = await getAccidentOverview({})
        if (r.code === 0 && r.data) {
          this.statCards[0].value = r.data.total || 0
          this.statCards[1].value = r.data.death || 0
          this.statCards[2].value = r.data.serious || 0
          this.statCards[3].value = r.data.minor || 0
          this.statCards[4].value = r.data.economic_loss || 0
          this.statCards[5].value = r.data.rate || 0
        }
      } catch (e) {}
    },
    async loadTrend() {
      try {
        const r = await getAccidentTrend({ months: 12, year: this.trendYear })
        if (r.code === 0 && r.data) {
          this.safeSet('trend', {
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 30, top: 30, bottom: 30 },
            xAxis: { type: 'category', data: r.data.months || [] },
            yAxis: { type: 'value', minInterval: 1 },
            series: [{ type: 'line', smooth: true, data: r.data.counts || [], lineStyle: { width: 2, color: '#409EFF' }, itemStyle: { color: '#409EFF' }, label: { show: true }, areaStyle: { opacity: 0.08 } }],
          })
        }
      } catch (e) {}
    },
    async loadType() {
      try {
        const r = await getTypeDistribution()
        if (r.code === 0 && r.data) {
          this.safeSet('type', {
            tooltip: { trigger: 'item', formatter: '{b}: {c}（{d}%）' },
            legend: { orient: 'vertical', right: 0, top: 'middle' },
            series: [{ type: 'pie', radius: '55%', center: ['40%', '50%'], data: r.data.list || [], label: { formatter: '{b}: {c}' } }],
          })
        }
      } catch (e) {}
    },
    async loadLevel() {
      try {
        const r = await getLevelDistribution()
        if (r.code === 0 && r.data) {
          const colors = { 一般: '#409EFF', 较大: '#E6A23C', 重大: '#F56C6C', 特别重大: '#C1121F' }
          this.safeSet('level', {
            tooltip: { trigger: 'item', formatter: '{b}: {c}（{d}%）' },
            legend: { orient: 'vertical', right: 0, top: 'middle' },
            series: [{ type: 'pie', radius: '55%', center: ['40%', '50%'], data: (r.data.list || []).map(x => ({ ...x, itemStyle: { color: colors[x.name] || '#409EFF' } })), label: { formatter: '{b}: {c}' } }],
          })
        }
      } catch (e) {}
    },
    async loadDept() {
      try {
        const r = await getDepartmentDistribution()
        if (r.code === 0 && r.data) {
          const list = r.data.list || []
          this.safeSet('dept', {
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 20, top: 30, bottom: 60 },
            xAxis: { type: 'category', data: list.map(x => x.name), axisLabel: { rotate: 30, interval: 0 } },
            yAxis: { type: 'value', minInterval: 1 },
            series: [{ type: 'bar', data: list.map(x => x.value), label: { show: true }, itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#a0cfff' }]) } }],
          })
        }
      } catch (e) {}
    },
    async loadCross() {
      try {
        const r = await getTypeLevelCross()
        if (r.code === 0 && r.data) {
          const types = r.data.types || []
          const levelNames = ['一般', '较大', '重大', '特别重大']
          const levelKeys = ['general', 'major', 'serious', 'critical']
          const levelColors = { general: '#409EFF', major: '#E6A23C', serious: '#F56C6C', critical: '#C1121F' }
          this.safeSet('cross', {
            tooltip: { trigger: 'axis' },
            legend: { data: levelNames, top: 0, right: 0 },
            grid: { left: 40, right: 20, top: 40, bottom: 30 },
            xAxis: { type: 'category', data: types.map(x => x.type) },
            yAxis: { type: 'value', minInterval: 1 },
            series: levelKeys.map(k => ({
              name: levelNames[levelKeys.indexOf(k)],
              type: 'bar', stack: 'total',
              data: types.map(x => x.level[k] || 0),
              itemStyle: { color: levelColors[k] },
              label: { show: true },
            })),
          })
        }
      } catch (e) {}
    },
    async loadCasualty() {
      try {
        const r = await getCasualtyRanking(10)
        if (r.code === 0 && r.data) {
          const list = r.data.list || []
          this.safeSet('casualty', {
            tooltip: { trigger: 'axis' },
            legend: { data: ['死亡', '重伤', '轻伤'], top: 0, right: 0 },
            grid: { left: 40, right: 20, top: 40, bottom: 60 },
            xAxis: { type: 'category', data: list.map(x => x.accident_name), axisLabel: { rotate: 30, interval: 0 } },
            yAxis: { type: 'value', minInterval: 1 },
            series: [
              { name: '死亡', type: 'bar', data: list.map(x => x.death), itemStyle: { color: '#F56C6C' } },
              { name: '重伤', type: 'bar', data: list.map(x => x.serious), itemStyle: { color: '#E6A23C' } },
              { name: '轻伤', type: 'bar', data: list.map(x => x.minor), itemStyle: { color: '#409EFF' } },
            ],
          })
        }
      } catch (e) {}
    },
    async loadEconomic() {
      try {
        const r = await getEconomicRanking(10)
        if (r.code === 0 && r.data) {
          const list = r.data.list || []
          this.safeSet('economic', {
            tooltip: { trigger: 'axis', formatter: '{b}: {c} 万元' },
            grid: { left: 50, right: 30, top: 30, bottom: 60 },
            xAxis: { type: 'category', data: list.map(x => x.accident_name), axisLabel: { rotate: 30, interval: 0 } },
            yAxis: { type: 'value', name: '万元' },
            series: [{ type: 'bar', data: list.map(x => x.economic_loss), label: { show: true, formatter: '{c}' }, itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#E6A23C' }, { offset: 1, color: '#f3d19e' }]) } }],
          })
        }
      } catch (e) {}
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        accident_type: this.filters.accident_type || '',
        accident_level: this.filters.accident_level || '',
        ...extra,
      }
      if (this.dateRange && this.dateRange.length === 2) {
        p.start_date = this.dateRange[0]
        p.end_date = this.dateRange[1]
      }
      return p
    },
    async loadDetail() {
      this.loading = true
      try {
        const r = await getAccidentDetailList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    onSearch() { this.page = 1; this.loadDetail() },
    resetFilters() { this.filters = { accident_type: '', accident_level: '' }; this.dateRange = null; this.page = 1; this.loadDetail() },
    typeTag(t) { return { personal_injury: 'danger', equipment_damage: 'warning', fire: 'danger', explosion: 'danger', leakage: 'warning', other: 'info' }[t] || 'info' },
    levelTag(l) { return { general: '', major: 'warning', serious: 'danger', critical: 'danger' }[l] || 'info' },
    statusTag(s) { return { draft: 'info', pending: 'warning', investigating: '', closed: 'success', archived: 'info' }[s] || 'info' },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportAccidentStatistics(this.buildParams())
        if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
      } catch (e) {}
      this.exporting = false
    },
  },
}
</script>

<style scoped>
.stat-card { display: flex; align-items: center; }
.stat-icon { width: 46px; height: 46px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 24px; margin-right: 12px; }
.stat-num { font-size: 22px; font-weight: 600; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; }
.chart-error { color: #F56C6C; font-size: 13px; padding: 10px; background: #fef0f0; border-radius: 6px; margin-top: 6px; }
</style>
