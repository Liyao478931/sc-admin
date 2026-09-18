<template>
  <div class="diy-stats-page">
    <div class="page-header">
      <div>
        <h2>页面数据统计</h2>
        <span class="sub-title">DIY 页面访问量 / 独立访客 / 来源 / Top 排行</span>
      </div>
      <div class="filter-bar">
        <el-radio-group v-model="rangeKey" size="small" @change="onRangeChange">
          <el-radio-button label="today">今日</el-radio-button>
          <el-radio-button label="7d">近7天</el-radio-button>
          <el-radio-button label="30d">近30天</el-radio-button>
          <el-radio-button label="month">本月</el-radio-button>
        </el-radio-group>
        <el-select v-model="diyId" size="small" clearable placeholder="全部页面" style="width:180px;margin-left:8px" @change="loadOverview">
          <el-option v-for="p in pageOptions" :key="p.id" :label="p.title || p.name" :value="p.id"></el-option>
        </el-select>
        <el-button size="small" style="margin-left:8px" @click="loadOverview">刷新</el-button>
      </div>
    </div>

    <!-- 统计卡片 -->
    <div class="stat-cards">
      <div class="stat-card">
        <div class="stat-num">{{ overview.total_pv || 0 }}</div>
        <div class="stat-label">总访问量 (PV)</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ overview.total_uv || 0 }}</div>
        <div class="stat-label">独立访客 (UV)</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ overview.page_count || 0 }}</div>
        <div class="stat-label">访问页面数</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ sourceCount }}</div>
        <div class="stat-label">来源渠道数</div>
      </div>
    </div>

    <div class="chart-row">
      <!-- 访问趋势（CSS 柱状） -->
      <div class="chart-box trend-box">
        <div class="chart-title">访问趋势（按日 PV / UV）</div>
        <div class="trend-chart" v-if="trendMax > 0">
          <div class="trend-bar" v-for="(t, i) in trend" :key="i" :title="t.date + ' PV:' + t.pv + ' UV:' + t.uv">
            <div class="trend-col-pv" :style="{ height: (t.pv / trendMax * 100) + '%' }"></div>
            <div class="trend-col-uv" :style="{ height: (t.uv / trendMax * 100) + '%' }"></div>
            <span class="trend-date">{{ t.date.slice(5) }}</span>
          </div>
        </div>
        <div v-else class="chart-empty">暂无数据</div>
      </div>
      <!-- 来源分布（CSS 条形） -->
      <div class="chart-box source-box">
        <div class="chart-title">来源分布</div>
        <div v-if="overview.source_distribution && overview.source_distribution.length">
          <div class="source-row" v-for="(s, i) in overview.source_distribution" :key="i">
            <span class="source-name">{{ s.source_text }}</span>
            <div class="source-bar-wrap">
              <div class="source-bar" :style="{ width: (s.percentage || 0) + '%' }"></div>
            </div>
            <span class="source-num">{{ s.count }} ({{ s.percentage || 0 }}%)</span>
          </div>
        </div>
        <div v-else class="chart-empty">暂无数据</div>
      </div>
    </div>

    <!-- Top 页面排行 -->
    <div class="chart-box" style="margin:0 24px 24px">
      <div class="chart-title">Top 页面排行</div>
      <el-table :data="overview.top_pages || []" size="small" border stripe style="width:100%">
        <el-table-column label="排名" width="70" align="center">
          <template slot-scope="{row, $index}"><span style="font-weight:600;color:#409EFF">{{ $index + 1 }}</span></template>
        </el-table-column>
        <el-table-column prop="page_title" label="页面名称" min-width="160" />
        <el-table-column prop="page_name" label="页面标识" width="140" />
        <el-table-column prop="pv" label="PV" width="90" align="center" />
        <el-table-column prop="uv" label="UV" width="90" align="center" />
        <el-table-column prop="percentage" label="占比" width="100" align="center">
          <template slot-scope="{row}">{{ row.percentage }}%</template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="{row}">
            <el-button size="mini" type="text" @click="openDetail(row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 页面详情弹窗 -->
    <el-dialog title="页面访问详情" :visible.sync="showDetail" width="720px" append-to-body>
      <div v-if="detail" class="detail-body">
        <div class="detail-overview">
          <div class="dov-item"><span class="dov-num">{{ detail.overview.pv || 0 }}</span><span class="dov-label">PV</span></div>
          <div class="dov-item"><span class="dov-num">{{ detail.overview.uv || 0 }}</span><span class="dov-label">UV</span></div>
          <div class="dov-item"><span class="dov-num">{{ detail.overview.source_count || 0 }}</span><span class="dov-label">来源数</span></div>
        </div>
        <div class="detail-section">
          <div class="chart-title">访问趋势</div>
          <div class="trend-chart" v-if="detailMax > 0">
            <div class="trend-bar" v-for="(t, i) in detail.trend" :key="i" :title="t.date + ' PV:' + t.pv + ' UV:' + t.uv">
              <div class="trend-col-pv" :style="{ height: (t.pv / detailMax * 100) + '%' }"></div>
              <span class="trend-date">{{ t.date.slice(5) }}</span>
            </div>
          </div>
          <div v-else class="chart-empty">暂无数据</div>
        </div>
        <div class="detail-section">
          <div class="chart-title">来源分布</div>
          <div v-if="detail.source_distribution && detail.source_distribution.length">
            <div class="source-row" v-for="(s, i) in detail.source_distribution" :key="i">
              <span class="source-name">{{ s.source_text }}</span>
              <div class="source-bar-wrap"><div class="source-bar" :style="{ width: (s.percentage || 0) + '%' }"></div></div>
              <span class="source-num">{{ s.count }} ({{ s.percentage || 0 }}%)</span>
            </div>
          </div>
          <div v-else class="chart-empty">暂无数据</div>
        </div>
        <div class="detail-section">
          <div class="chart-title">最近访问记录</div>
          <el-table :data="detail.recent_visits || []" size="mini" border stripe style="width:100%">
            <el-table-column prop="visit_time" label="时间" width="160" />
            <el-table-column prop="source" label="来源" width="100" />
            <el-table-column prop="platform" label="平台" width="100" />
            <el-table-column prop="ip" label="IP" min-width="120" />
          </el-table>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getDiyStatsOverview, getDiyStatsDetail } from '@/api/diyStats'
import { diyLst } from '@/api/diy'

export default {
  name: 'DiyStatsPage',
  data() {
    return {
      rangeKey: '30d',
      diyId: 0,
      pageOptions: [],
      overview: {},
      detail: null,
      showDetail: false,
    }
  },
  computed: {
    trend() { return this.overview.trend || [] },
    trendMax() { return Math.max(...this.trend.map(t => t.pv || 0), 1) },
    detailMax() { return this.detail ? Math.max(...(this.detail.trend || []).map(t => t.pv || 0), 1) : 1 },
    sourceCount() { return (this.overview.source_distribution || []).length },
  },
  created() { this.loadPages(); this.loadOverview() },
  methods: {
    rangeDays() {
      const now = new Date()
      const fmt = d => d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
      const end = fmt(now)
      let start
      if (this.rangeKey === 'today') start = end
      else if (this.rangeKey === '7d') { const d = new Date(now); d.setDate(d.getDate() - 6); start = fmt(d) }
      else if (this.rangeKey === 'month') start = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-01'
      else { const d = new Date(now); d.setDate(d.getDate() - 29); start = fmt(d) }
      return { start_date: start, end_date: end }
    },
    onRangeChange() { this.loadOverview() },
    async loadPages() {
      try {
        const res = await diyLst({ page: 1, limit: 200 })
        if (res.code === 0) this.pageOptions = res.data.list || []
      } catch (e) {}
    },
    async loadOverview() {
      try {
        const params = { ...this.rangeDays() }
        if (this.diyId) params.diy_id = this.diyId
        const res = await getDiyStatsOverview(params)
        if (res.code === 0) this.overview = res.data || {}
      } catch (e) { this.overview = {} }
    },
    async openDetail(row) {
      try {
        const res = await getDiyStatsDetail({ diy_id: row.diy_id, ...this.rangeDays() })
        if (res.code === 0) { this.detail = res.data || {}; this.showDetail = true }
      } catch (e) { this.$message.error('加载详情失败') }
    },
  },
}
</script>

<style scoped>
.diy-stats-page { padding: 0; background: #f5f7fa; min-height: 100%; }
.page-header { height: 56px; background: #fff; border-bottom: 1px solid #EBEEF5; padding: 0 24px; display: flex; align-items: center; justify-content: space-between; }
.page-header h2 { font-size: 20px; font-weight: bold; color: #303133; margin: 0; display: inline; }
.sub-title { font-size: 13px; color: #909399; margin-left: 12px; }
.filter-bar { display: flex; align-items: center; }
.stat-cards { display: flex; gap: 16px; margin: 16px 24px; }
.stat-card { flex: 1; background: #fff; border-radius: 10px; padding: 20px 24px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.stat-num { font-size: 28px; font-weight: 700; color: #303133; }
.stat-label { margin-top: 6px; font-size: 13px; color: #909399; }
.chart-row { display: flex; gap: 16px; margin: 0 24px 16px; }
.chart-box { background: #fff; border-radius: 10px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.trend-box { flex: 2; }
.source-box { flex: 1; }
.chart-title { font-size: 15px; font-weight: 600; color: #303133; margin-bottom: 12px; }
.chart-empty { padding: 40px; text-align: center; color: #C0C4CC; }
.trend-chart { display: flex; align-items: flex-end; gap: 2px; height: 200px; padding: 0 4px; }
.trend-bar { flex: 1; display: flex; align-items: flex-end; justify-content: flex-end; flex-direction: column; height: 100%; position: relative; }
.trend-col-pv { width: 45%; background: #409EFF; border-radius: 2px 2px 0 0; min-height: 1px; }
.trend-col-uv { width: 45%; background: #7c6cf6; border-radius: 2px 2px 0 0; min-height: 1px; margin-left: 2px; }
.trend-date { position: absolute; bottom: -18px; font-size: 10px; color: #C0C4CC; transform: rotate(-45deg); white-space: nowrap; }
.source-row { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.source-name { width: 70px; font-size: 13px; color: #606266; flex-shrink: 0; }
.source-bar-wrap { flex: 1; background: #f0f2f5; border-radius: 4px; height: 14px; overflow: hidden; }
.source-bar { height: 100%; background: linear-gradient(90deg, #409EFF, #7c6cf6); border-radius: 4px; }
.source-num { width: 90px; font-size: 12px; color: #909399; text-align: right; flex-shrink: 0; }
.detail-body { max-height: 70vh; overflow-y: auto; }
.detail-overview { display: flex; gap: 16px; margin-bottom: 16px; }
.dov-item { flex: 1; background: #f7f9fc; border-radius: 8px; padding: 16px; text-align: center; }
.dov-num { display: block; font-size: 24px; font-weight: 700; color: #409EFF; }
.dov-label { font-size: 12px; color: #909399; }
.detail-section { margin-top: 16px; }
</style>
