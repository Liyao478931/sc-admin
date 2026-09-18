<template>
  <view class="cockpit">
    <!-- 顶部 -->
    <view class="c-head">
      <view class="c-title">
        <text class="c-title-main">数智管控驾驶舱</text>
        <text class="c-title-sub">{{ today }} · 实时概览</text>
      </view>
      <view class="c-refresh" @click="load"><MIcon class="c-refresh-icon" name="refresh" :size="16" color="#8a9aa8" /></view>
    </view>

    <!-- KPI 卡片 -->
    <view class="kpi-grid">
      <view class="kpi-card" v-for="k in kpis" :key="k.key">
        <view class="kpi-icon" :style="{ background: k.bg }"><MIcon :name="k.icon" :size="24" color="#ffffff" :weight="2" /></view>
        <text class="kpi-num">{{ k.value }}</text>
        <text class="kpi-label">{{ k.label }}</text>
      </view>
    </view>

    <!-- 近7天产量趋势 -->
    <view class="panel">
      <view class="panel-head">
        <text class="panel-title">近7天产量趋势</text>
        <text class="panel-total">合计 {{ trendTotal }}</text>
      </view>
      <view class="bar-chart">
        <view class="bar-col" v-for="(t, i) in trend" :key="i">
          <view class="bar-track">
            <view class="bar-fill" :style="{ height: barHeight(t.production) + '%' }"></view>
          </view>
          <text class="bar-label">{{ t.label }}</text>
          <text class="bar-val">{{ t.production }}</text>
        </view>
      </view>
      <view v-if="!trendTotal" class="empty-tip">暂无产量数据</view>
    </view>

    <!-- 隐患状态分布 -->
    <view class="panel">
      <view class="panel-head">
        <text class="panel-title">隐患状态分布</text>
        <text class="panel-total">共 {{ hazardTotal }} 项</text>
      </view>
      <view v-for="(h, i) in hazardStats" :key="i" class="hazard-row">
        <text class="hazard-label">{{ h.label }}</text>
        <view class="hazard-track">
          <view class="hazard-fill" :style="{ width: hazardPct(h.value) + '%', background: hazardColor(i) }"></view>
        </view>
        <text class="hazard-val">{{ h.value }}</text>
      </view>
      <view v-if="!hazardStats.length" class="empty-tip">暂无隐患数据</view>
    </view>

    <!-- 我的工作 -->
    <view class="panel">
      <view class="panel-head"><text class="panel-title">我的工作</text></view>
      <view class="mine-grid">
        <view class="mine-item" @click="go('/pages/sub/inspection/task-list')">
          <text class="mine-num">{{ kpi.my_inspection }}</text>
          <text class="mine-label">待巡检</text>
        </view>
        <view class="mine-item" @click="go('/pages/sub/maintenance/task-list')">
          <text class="mine-num">{{ kpi.my_maintenance }}</text>
          <text class="mine-label">待保养</text>
        </view>
        <view class="mine-item" @click="go('/pages/approval/todo')">
          <text class="mine-num">{{ kpi.my_todo }}</text>
          <text class="mine-label">审批待办</text>
        </view>
        <view class="mine-item" @click="go('/pages/asset/my-list')">
          <text class="mine-num">{{ kpi.my_assets }}</text>
          <text class="mine-label">我的资产</text>
        </view>
      </view>
    </view>

    <view v-if="loading" class="loading-mask">
      <view class="loading-box">数据加载中...</view>
    </view>
  </view>
</template>

<script>
import { getCockpitOverview } from '../../../api/index.js'

export default {
  data() {
    return {
      loading: true,
      kpi: {},
      trend: [],
      hazardStats: [],
      today: ''
    }
  },
  computed: {
    kpis() {
      const k = this.kpi
      return [
        { key: 'today_production', icon: 'gear', label: '今日产量', value: k.today_production ?? '-', bg: 'linear-gradient(135deg,#4F46E5,#7c6cf0)' },
        { key: 'today_reports', icon: 'clipboard', label: '今日报工', value: k.today_reports ?? '-', bg: 'linear-gradient(135deg,#0ea5e9,#38bdf8)' },
        { key: 'in_progress_orders', icon: 'factory', label: '在制工单', value: k.in_progress_orders ?? '-', bg: 'linear-gradient(135deg,#f59e0b,#fbbf24)' },
        { key: 'pending_approvals', icon: 'inbox', label: '待办审批', value: k.pending_approvals ?? '-', bg: 'linear-gradient(135deg,#10b981,#34d399)' },
        { key: 'today_hazards', icon: 'alert', label: '今日隐患', value: k.today_hazards ?? '-', bg: 'linear-gradient(135deg,#ef4444,#f87171)' }
      ]
    },
    trendTotal() {
      return this.trend.reduce((s, t) => s + (Number(t.production) || 0), 0)
    },
    hazardTotal() {
      return this.hazardStats.reduce((s, h) => s + (Number(h.value) || 0), 0)
    }
  },
  onLoad() {
    const d = new Date()
    const pad = (n) => String(n).padStart(2, '0')
    this.today = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
    this.load()
  },
  methods: {
    go(url) {
      if (url.indexOf('/pages/approval/') === 0 || url.indexOf('/pages/asset/') === 0) {
        uni.navigateTo({ url })
      } else {
        uni.navigateTo({ url })
      }
    },
    barHeight(v) {
      const max = Math.max(...this.trend.map(t => Number(t.production) || 0), 1)
      return Math.max(4, Math.round((Number(v) || 0) / max * 100))
    },
    hazardPct(v) {
      const total = this.hazardTotal || 1
      return Math.round((Number(v) || 0) / total * 100)
    },
    hazardColor(i) {
      const colors = ['#f59e0b', '#0ea5e9', '#ef4444', '#10b981']
      return colors[i % colors.length]
    },
    async load() {
      this.loading = true
      try {
        const r = await getCockpitOverview()
        if (r.code === 0) {
          this.kpi = (r.data && r.data.kpi) || {}
          this.trend = (r.data && r.data.trend) || []
          this.hazardStats = (r.data && r.data.hazard_stats) || []
        }
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>

<style scoped>
.cockpit { min-height: 100vh; background: linear-gradient(180deg, #0b1220 0%, #0e1830 40%, #111c38 100%); padding: 0 16px 40px; box-sizing: border-box; position: relative; }
.c-head { display: flex; align-items: center; justify-content: space-between; padding: 18px 4px 6px; }
.c-title { display: flex; flex-direction: column; }
.c-title-main { font-size: 22px; font-weight: 800; color: #fff; letter-spacing: 2px; }
.c-title-sub { font-size: 12px; color: #7d8db1; margin-top: 4px; }
.c-refresh { width: 36px; height: 36px; border-radius: 50%; background: rgba(79,70,229,0.18); border: 1px solid rgba(124,108,240,0.4); display: flex; align-items: center; justify-content: center; }
.c-refresh-icon { color: #a5b4fc; font-size: 18px; }
.kpi-grid { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 14px; }
.kpi-card { width: calc(33.33% - 7px); background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 14px 10px; display: flex; flex-direction: column; align-items: center; backdrop-filter: blur(8px); }
.kpi-icon { width: 34px; height: 34px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 16px; }
.kpi-num { font-size: 22px; font-weight: 800; color: #fff; margin-top: 8px; font-family: monospace; }
.kpi-label { font-size: 11px; color: #7d8db1; margin-top: 4px; }
.panel { margin-top: 16px; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; padding: 16px; }
.panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.panel-title { font-size: 15px; font-weight: 700; color: #e2e8f0; }
.panel-total { font-size: 12px; color: #7d8db1; }
.bar-chart { display: flex; align-items: flex-end; gap: 8px; height: 150px; }
.bar-col { flex: 1; display: flex; flex-direction: column; align-items: center; height: 100%; justify-content: flex-end; }
.bar-track { width: 60%; height: 100px; background: rgba(255,255,255,0.06); border-radius: 8px 8px 0 0; display: flex; align-items: flex-end; overflow: hidden; }
.bar-fill { width: 100%; background: linear-gradient(180deg, #7c6cf0, #4F46E5); border-radius: 8px 8px 0 0; min-height: 4px; transition: height 0.6s ease; }
.bar-label { font-size: 10px; color: #7d8db1; margin-top: 6px; }
.bar-val { font-size: 10px; color: #a5b4fc; margin-top: 2px; font-family: monospace; }
.hazard-row { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
.hazard-label { width: 56px; font-size: 12px; color: #a5b4fc; }
.hazard-track { flex: 1; height: 8px; background: rgba(255,255,255,0.08); border-radius: 8px; overflow: hidden; }
.hazard-fill { height: 100%; border-radius: 8px; transition: width 0.6s ease; }
.hazard-val { width: 36px; text-align: right; font-size: 13px; font-weight: 700; color: #fff; font-family: monospace; }
.mine-grid { display: flex; flex-wrap: wrap; gap: 10px; }
.mine-item { width: calc(50% - 5px); background: rgba(255,255,255,0.04); border-radius: 14px; padding: 14px; display: flex; flex-direction: column; align-items: center; border: 1px solid rgba(255,255,255,0.06); }
.mine-num { font-size: 24px; font-weight: 800; color: #a5b4fc; font-family: monospace; }
.mine-label { font-size: 12px; color: #7d8db1; margin-top: 4px; }
.empty-tip { text-align: center; color: #5b6b8c; font-size: 12px; padding: 18px 0 6px; }
.loading-mask { position: fixed; inset: 0; background: rgba(11,18,32,0.7); display: flex; align-items: center; justify-content: center; z-index: 99; }
.loading-box { color: #a5b4fc; font-size: 14px; }
</style>
