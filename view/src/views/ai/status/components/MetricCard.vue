<!--
  文件：admin/src/views/ai/status/components/MetricCard.vue
  功能：系统性能指标卡片
    - CPU/内存/磁盘：进度条展示，超过80%红色
    - 网络流量：入站/出站速率
    - 数据库连接：当前/峰值
    - Redis连接、队列积压：数值
    - 均带趋势标识（上升/下降/平稳）与说明
-->
<template>
  <div class="metric-card" :class="'m-' + (metric.status || 'ok')">
    <div class="metric-head">
      <span class="metric-label">{{ metric.label }}</span>
      <i :class="trendIcon" class="metric-trend" :title="trendText"></i>
    </div>

    <!-- 进度条型指标（CPU/内存/磁盘） -->
    <template v-if="isPercent">
      <div class="metric-value">
        {{ metric.value }}<span class="metric-unit">{{ metric.unit }}</span>
      </div>
      <el-progress
        :percentage="Number(metric.value)"
        :stroke-width="8"
        :show-text="false"
        :color="progressColor"
      ></el-progress>
    </template>

    <!-- 对象型指标（网络流量 / 数据库连接） -->
    <template v-else-if="isObject">
      <div class="metric-value">{{ objectMainText }}</div>
      <div class="metric-sub">{{ objectSubText }}</div>
    </template>

    <!-- 数值型指标（Redis连接 / 队列积压） -->
    <template v-else>
      <div class="metric-value">
        {{ metric.value }}<span class="metric-unit">{{ metric.unit }}</span>
      </div>
    </template>

    <!-- 说明 -->
    <div class="metric-detail" :title="metric.detail">{{ metric.detail }}</div>
  </div>
</template>

<script>
export default {
  name: 'MetricCard',
  props: {
    metric: { type: Object, required: true }
  },
  computed: {
    isPercent() { return ['cpu', 'memory', 'disk'].includes(this.metric.key) },
    isObject() { return this.metric.value && typeof this.metric.value === 'object' },
    objectMainText() {
      const v = this.metric.value || {}
      if (this.metric.key === 'network') {
        return v.out !== undefined ? this.fmtRate(v.out) : '--'
      }
      if (this.metric.key === 'database') {
        return v.current !== undefined ? (v.current + ' / ' + (v.max || '--')) : '--'
      }
      return '--'
    },
    objectSubText() {
      const v = this.metric.value || {}
      if (this.metric.key === 'network') {
        return v.in !== undefined ? ('入站 ' + this.fmtRate(v.in)) : ''
      }
      return '当前 / 峰值连接数'
    },
    trendIcon() {
      return { up: 'el-icon-top', down: 'el-icon-bottom', flat: 'el-icon-minus' }[this.metric.trend] || 'el-icon-minus'
    },
    trendText() {
      return { up: '趋势上升', down: '趋势下降', flat: '趋势平稳' }[this.metric.trend] || '趋势平稳'
    },
    progressColor() {
      return { danger: '#f56c6c', warning: '#e6a23c', ok: '#409eff' }[this.metric.status] || '#409eff'
    }
  },
  methods: {
    fmtRate(v) {
      if (v === undefined || v === null) return '--'
      if (v >= 1024 * 1024) return (v / 1024 / 1024).toFixed(2) + ' MB/s'
      if (v >= 1024) return (v / 1024).toFixed(1) + ' KB/s'
      return v + ' B/s'
    }
  }
}
</script>

<style scoped>
.metric-card {
  padding: 12px 14px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  background: #fff;
  height: 100%;
  box-sizing: border-box;
  transition: border-color 0.2s;
}
.metric-card.m-danger { border-color: #fde2e2; }
.metric-card.m-warning { border-color: #faecd8; }

.metric-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
.metric-label { font-size: 12px; color: #909399; }
.metric-trend { font-size: 12px; color: #c0c4cc; }
.metric-trend.el-icon-top { color: #f56c6c; }
.metric-trend.el-icon-bottom { color: #67c23a; }

.metric-value { font-size: 20px; font-weight: 700; color: #303133; margin-bottom: 6px; }
.metric-unit { font-size: 12px; font-weight: 400; color: #909399; margin-left: 2px; }
.metric-sub { font-size: 12px; color: #606266; margin-bottom: 4px; }

.metric-detail {
  font-size: 11px;
  color: #c0c4cc;
  margin-top: 8px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
