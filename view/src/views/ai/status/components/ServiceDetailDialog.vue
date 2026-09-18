<!--
  文件：admin/src/views/ai/status/components/ServiceDetailDialog.vue
  功能：服务详情弹窗
    - 服务基本信息（名称、类型、状态、版本、部署时间）
    - 实时指标（QPS、响应时间、错误率、24h总量）
    - 最近24小时性能趋势图（响应时间 + 请求量，ECharts 折线）
    - 服务依赖关系（上游/下游）
    - 服务配置信息
-->
<template>
  <el-dialog
    :visible="visible"
    :title="(service && service.name) || '服务详情'"
    width="760px"
    :close-on-click-modal="false"
    @opened="onOpened"
    @close="$emit('update:visible', false)"
  >
    <div v-loading="loading" class="svc-detail">
      <template v-if="detail">
        <!-- ===== 基本信息 ===== -->
        <div class="base-info">
          <div class="base-item">
            <span class="base-label">服务名称</span>
            <span class="base-value">{{ detail.service.name }}</span>
          </div>
          <div class="base-item">
            <span class="base-label">服务类型</span>
            <span class="base-value">{{ typeText }}</span>
          </div>
          <div class="base-item">
            <span class="base-label">健康状态</span>
            <span class="base-value">
              <el-tag size="mini" :type="statusTagType">{{ statusText }}</el-tag>
            </span>
          </div>
          <div class="base-item">
            <span class="base-label">响应时间</span>
            <span class="base-value">{{ detail.service.rt ? detail.service.rt + 'ms' : '--' }}</span>
          </div>
          <div class="base-item">
            <span class="base-label">可用率(24h)</span>
            <span class="base-value">{{ detail.service.availability !== null && detail.service.availability !== undefined ? detail.service.availability + '%' : '--' }}</span>
          </div>
          <div class="base-item">
            <span class="base-label">状态描述</span>
            <span class="base-value">{{ detail.service.desc }}</span>
          </div>
        </div>

        <!-- ===== 实时指标 ===== -->
        <div class="realtime-metrics">
          <div class="rt-item">
            <div class="rt-label">QPS（24h均值）</div>
            <div class="rt-value">{{ detail.metrics.qps }}</div>
          </div>
          <div class="rt-item">
            <div class="rt-label">响应时间</div>
            <div class="rt-value">{{ detail.metrics.response_time }}<span class="rt-unit">ms</span></div>
          </div>
          <div class="rt-item">
            <div class="rt-label">错误率(24h)</div>
            <div class="rt-value" :class="{ 'rt-danger': detail.metrics.error_rate >= 10 }">{{ detail.metrics.error_rate }}<span class="rt-unit">%</span></div>
          </div>
          <div class="rt-item">
            <div class="rt-label">24h调用总量</div>
            <div class="rt-value">{{ detail.metrics.total_24h }}</div>
          </div>
        </div>

        <!-- ===== 趋势图 ===== -->
        <div class="trend-block">
          <div class="block-title">最近24小时性能趋势</div>
          <div ref="trendChart" class="trend-chart"></div>
          <div v-if="trendEmpty" class="trend-empty">该服务暂无趋势数据（无业务调用日志）</div>
        </div>

        <!-- ===== 依赖关系 ===== -->
        <div class="depend-block">
          <div class="block-title">服务依赖关系</div>
          <div class="depend-row">
            <span class="depend-label">上游依赖</span>
            <span v-if="detail.depends.upstream.length" class="depend-tags">
              <el-tag v-for="d in detail.depends.upstream" :key="d.key" size="mini" class="depend-tag">{{ d.name }}</el-tag>
            </span>
            <span v-else class="depend-none">无</span>
          </div>
          <div class="depend-row">
            <span class="depend-label">下游服务</span>
            <span v-if="detail.depends.downstream.length" class="depend-tags">
              <el-tag v-for="d in detail.depends.downstream" :key="d.key" size="mini" type="success" class="depend-tag">{{ d.name }}</el-tag>
            </span>
            <span v-else class="depend-none">无</span>
          </div>
        </div>

        <!-- ===== 配置信息 ===== -->
        <div class="config-block" v-if="detail.config && detail.config.length">
          <div class="block-title">服务配置</div>
          <div class="config-row" v-for="c in detail.config" :key="c.key">
            <span class="config-label">{{ c.label }}</span>
            <span class="config-value">{{ c.value || '--' }}</span>
          </div>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import * as echarts from 'echarts'
import { getSystemStatusDetail, getSystemStatusTrend } from '../../../../api/aiStatus'

export default {
  name: 'ServiceDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    service: { type: Object, default: null }
  },
  data() {
    return {
      loading: false,
      detail: null,
      trendList: [],
      chart: null
    }
  },
  computed: {
    status() { return (this.detail && this.detail.service && this.detail.service.status) || (this.service && this.service.status) || 'unknown' },
    statusText() { return { normal: '运行正常', error: '响应异常', unknown: '状态未知' }[this.status] || '状态未知' },
    statusTagType() { return { normal: 'success', error: 'danger', unknown: 'info' }[this.status] || 'info' },
    typeText() { return { core: '核心服务', external: '外部服务', infra: '基础设施' }[this.detail && this.detail.service && this.detail.service.type] || '--' },
    trendEmpty() { return !this.trendList || !this.trendList.length }
  },
  watch: {
    visible(val) {
      if (val && this.service) this.open()
    }
  },
  mounted() {
    // 弹窗内 DOM 在首次打开前不存在，延迟初始化图表
  },
  beforeDestroy() {
    this.disposeChart()
  },
  methods: {
    // 弹窗完全展开后确保图表容器有尺寸，再渲染趋势图
    onOpened() {
      if (this.detail) this.$nextTick(() => this.renderChart())
    },
    async open() {
      this.loading = true
      this.detail = null
      try {
        const [d, t] = await Promise.all([
          getSystemStatusDetail({ service_name: this.service.key }),
          getSystemStatusTrend({ service_name: this.service.key, range: '24h' })
        ])
        this.detail = d.data || {}
        this.trendList = (t.data && t.data.list) || []
        this.$nextTick(() => this.renderChart())
      } catch (e) {
        this.detail = null
      }
      this.loading = false
    },
    renderChart() {
      this.disposeChart()
      if (!this.$refs.trendChart || !this.trendList.length) return
      this.chart = echarts.init(this.$refs.trendChart)
      const times = this.trendList.map(d => d.time)
      const counts = this.trendList.map(d => d.count)
      const rts = this.trendList.map(d => d.rt)
      const hasRt = rts.some(v => v > 0)
      this.chart.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['请求量', '响应时间(ms)'], bottom: 0 },
        grid: { left: 50, right: 50, top: 30, bottom: 40 },
        xAxis: {
          type: 'category', data: times, boundaryGap: false,
          axisLabel: { fontSize: 10, interval: Math.max(0, Math.ceil(times.length / 12) - 1) }
        },
        yAxis: [
          { type: 'value', name: '请求量', axisLabel: { fontSize: 10 } },
          { type: 'value', name: 'ms', axisLabel: { fontSize: 10 } }
        ],
        series: [
          {
            name: '请求量', type: 'bar', data: counts, barMaxWidth: 14,
            itemStyle: { color: '#409eff', borderRadius: [2, 2, 0, 0] }
          },
          {
            name: '响应时间(ms)', type: 'line', smooth: true, yAxisIndex: 1,
            data: rts, showSymbol: false, lineStyle: { color: '#f56c6c' },
            itemStyle: { color: '#f56c6c' }, areaStyle: { opacity: 0.08 }
          }
        ]
      })
    },
    disposeChart() {
      if (this.chart) { this.chart.dispose(); this.chart = null }
    }
  }
}
</script>

<style scoped>
.svc-detail { min-height: 200px; }

/* ===== 基本信息 ===== */
.base-info {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px 16px;
  padding: 12px 14px;
  background: #f8f9fb;
  border-radius: 6px;
  margin-bottom: 14px;
}
.base-item { min-width: 0; }
.base-label { font-size: 12px; color: #909399; display: block; margin-bottom: 2px; }
.base-value { font-size: 13px; color: #303133; word-break: break-all; }

/* ===== 实时指标 ===== */
.realtime-metrics { display: flex; gap: 12px; margin-bottom: 14px; }
.rt-item {
  flex: 1;
  text-align: center;
  padding: 12px 8px;
  border: 1px solid #ebeef5;
  border-radius: 6px;
}
.rt-label { font-size: 12px; color: #909399; margin-bottom: 6px; }
.rt-value { font-size: 18px; font-weight: 700; color: #303133; }
.rt-unit { font-size: 12px; font-weight: 400; color: #909399; margin-left: 2px; }
.rt-value.rt-danger { color: #f56c6c; }

/* ===== 趋势 ===== */
.trend-block { margin-bottom: 14px; }
.block-title { font-size: 13px; font-weight: 600; color: #303133; margin-bottom: 8px; }
.trend-chart { height: 240px; }
.trend-empty { text-align: center; color: #909399; font-size: 12px; padding: 20px 0; border: 1px dashed #ebeef5; border-radius: 6px; }

/* ===== 依赖 ===== */
.depend-block { margin-bottom: 14px; }
.depend-row { display: flex; align-items: flex-start; margin-bottom: 8px; }
.depend-label { width: 70px; flex-shrink: 0; font-size: 12px; color: #909399; line-height: 24px; }
.depend-tags { display: flex; flex-wrap: wrap; gap: 6px; }
.depend-tag { margin: 0; }
.depend-none { font-size: 12px; color: #c0c4cc; line-height: 24px; }

/* ===== 配置 ===== */
.config-block { margin-bottom: 4px; }
.config-row {
  display: flex;
  padding: 8px 0;
  border-bottom: 1px dashed #ebeef5;
}
.config-row:last-child { border-bottom: none; }
.config-label { width: 90px; flex-shrink: 0; font-size: 12px; color: #909399; }
.config-value { font-size: 13px; color: #303133; }
</style>
