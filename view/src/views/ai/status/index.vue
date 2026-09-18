<!--
  文件：admin/src/views/ai/status/index.vue
  功能：AI智能平台 → 工作台 → 系统状态监控页面
    - 顶部：整体状态汇总（总服务数/正常运行/异常/未知）
    - 中部：服务健康状态卡片网格（点击查看详情）
    - 底部左侧：系统性能指标 + 系统运行信息
    - 底部右侧：最近告警列表
    - 自动刷新（30s）+ 手动刷新
-->
<template>
  <div class="ai-status-page">
    <!-- ===== 顶部工具栏 ===== -->
    <div class="filter-bar">
      <span class="page-title">系统状态监控</span>
      <span class="flex-1"></span>
      <el-switch v-model="autoRefresh" active-text="自动刷新(30s)" inactive-text="" style="margin-right: 14px;" />
      <span class="update-time">最后更新：{{ checkTime || '--' }}</span>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" style="margin-left: 10px;" @click="refreshAll">刷新</el-button>
    </div>

    <!-- ===== 一、整体状态汇总 ===== -->
    <el-row :gutter="14" class="summary-row">
      <el-col :span="6">
        <el-card shadow="never" class="summary-card">
          <div class="summary-label">总服务数</div>
          <div class="summary-value">{{ summary.total || 0 }}</div>
          <div class="summary-sub">AI 平台全部服务</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never" class="summary-card sum-normal">
          <div class="summary-label">正常运行</div>
          <div class="summary-value normal">{{ summary.normal || 0 }}</div>
          <div class="summary-sub">健康状态正常</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never" class="summary-card sum-error">
          <div class="summary-label">异常服务</div>
          <div class="summary-value error">{{ summary.error || 0 }}</div>
          <div class="summary-sub">需要关注处理</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never" class="summary-card sum-unknown">
          <div class="summary-label">未知服务</div>
          <div class="summary-value unknown">{{ summary.unknown || 0 }}</div>
          <div class="summary-sub">状态暂未确认</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- ===== 二、服务健康状态卡片 ===== -->
    <el-card shadow="never" class="section-card">
      <div slot="header" class="sec-head">
        <span>服务健康状态</span>
        <span class="sec-sub">点击卡片查看服务详情</span>
      </div>
      <el-row :gutter="14">
        <el-col v-for="s in services" :key="s.key" :span="6" class="svc-col">
          <ServiceCard :service="s" @click="openDetail" />
        </el-col>
      </el-row>
      <el-empty v-if="!services.length" description="暂无服务数据" :image-size="60" />
    </el-card>

    <!-- ===== 三、性能指标 + 告警 ===== -->
    <el-row :gutter="14">
      <!-- 左侧：性能指标 + 运行信息 -->
      <el-col :span="16">
        <el-card shadow="never" class="section-card">
          <div slot="header" class="sec-head">
            <span>性能指标</span>
            <span class="sec-sub">CPU/内存/磁盘超过 80% 将标红提示</span>
          </div>
          <el-row :gutter="14">
            <el-col v-for="m in metrics" :key="m.key" :span="6" class="svc-col">
              <MetricCard :metric="m" />
            </el-col>
          </el-row>
          <el-empty v-if="!metrics.length" description="暂无性能数据" :image-size="50" />
        </el-card>

        <el-card shadow="never" class="section-card">
          <div slot="header" class="sec-head">
            <span>系统运行信息</span>
            <span class="sec-sub" v-if="sysInfo.uptime">已运行 {{ sysInfo.uptime.text }}</span>
          </div>
          <div class="sys-info" v-if="sysInfo.system">
            <div class="info-grid">
              <div class="info-item"><span class="info-label">系统名称</span><span class="info-value">{{ sysInfo.system.app_name }}</span></div>
              <div class="info-item"><span class="info-label">系统版本</span><span class="info-value">{{ sysInfo.system.version }}</span></div>
              <div class="info-item"><span class="info-label">后端框架</span><span class="info-value">{{ sysInfo.system.framework }}</span></div>
              <div class="info-item"><span class="info-label">前端框架</span><span class="info-value">{{ sysInfo.system.frontend_framework }}</span></div>
              <div class="info-item"><span class="info-label">主机名</span><span class="info-value">{{ sysInfo.system.hostname }}</span></div>
              <div class="info-item"><span class="info-label">运行环境</span><span class="info-value">{{ sysInfo.system.env_label }}</span></div>
              <div class="info-item"><span class="info-label">操作系统</span><span class="info-value">{{ sysInfo.system.os }}</span></div>
              <div class="info-item"><span class="info-label">PHP版本</span><span class="info-value">{{ sysInfo.system.php_version }}</span></div>
              <div class="info-item"><span class="info-label">Web服务器</span><span class="info-value">{{ sysInfo.system.web_server }}</span></div>
              <div class="info-item"><span class="info-label">MySQL版本</span><span class="info-value">{{ sysInfo.system.mysql_version || '--' }}</span></div>
              <div class="info-item"><span class="info-label">Redis版本</span><span class="info-value">{{ sysInfo.system.redis_version || '--' }}</span></div>
              <div class="info-item"><span class="info-label">时区</span><span class="info-value">{{ sysInfo.system.timezone }}</span></div>
            </div>

            <!-- 各服务启动时间 -->
            <div class="svc-uptime" v-if="sysInfo.services && sysInfo.services.length">
              <div class="info-grid">
                <div v-for="s in sysInfo.services" :key="s.key" class="info-item">
                  <span class="info-label">{{ s.name }}</span>
                  <span class="info-value">
                    <template v-if="s.start_time">{{ s.start_time }}（{{ s.uptime_text }}）</template>
                    <template v-else>--</template>
                  </span>
                </div>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无运行信息" :image-size="50" />
        </el-card>
      </el-col>

      <!-- 右侧：最近告警 -->
      <el-col :span="8">
        <el-card shadow="never" class="section-card alert-card">
          <AlertList :alerts="alerts" :total="alertTotal" />
        </el-card>
      </el-col>
    </el-row>

    <!-- ===== 服务详情弹窗 ===== -->
    <ServiceDetailDialog :visible="detailVisible" :service="currentService" @update:visible="v => (detailVisible = v)" />
  </div>
</template>

<script>
import ServiceCard from './components/ServiceCard.vue'
import ServiceDetailDialog from './components/ServiceDetailDialog.vue'
import MetricCard from './components/MetricCard.vue'
import AlertList from './components/AlertList.vue'
import {
  getSystemStatusServices,
  getSystemStatusMetrics,
  getSystemStatusInfo,
  getSystemStatusAlerts
} from '../../../api/aiStatus'

export default {
  name: 'AiStatus',
  components: { ServiceCard, ServiceDetailDialog, MetricCard, AlertList },
  data() {
    return {
      autoRefresh: true,
      loading: false,
      checkTime: '',
      // 服务健康状态
      services: [],
      summary: { total: 0, normal: 0, error: 0, unknown: 0 },
      // 性能指标
      metrics: [],
      // 运行信息
      sysInfo: {},
      // 告警
      alerts: [],
      alertTotal: 0,
      // 服务详情弹窗
      detailVisible: false,
      currentService: null,
      // 定时器
      timer: null
    }
  },
  created() {
    this.refreshAll()
    this.timer = setInterval(() => { if (this.autoRefresh) this.refreshAll() }, 30000)
  },
  beforeDestroy() {
    if (this.timer) clearInterval(this.timer)
  },
  methods: {
    async refreshAll() {
      this.loading = true
      await Promise.all([
        this.loadServices(),
        this.loadMetrics(),
        this.loadInfo(),
        this.loadAlerts()
      ])
      this.checkTime = new Date().toLocaleTimeString('zh-CN', { hour12: false })
      this.loading = false
    },
    // 服务健康状态
    async loadServices() {
      try {
        const res = await getSystemStatusServices()
        const d = res.data || {}
        this.services = d.services || []
        this.summary = d.summary || { total: 0, normal: 0, error: 0, unknown: 0 }
        this.checkTime = d.check_time || this.checkTime
      } catch (e) {}
    },
    // 性能指标
    async loadMetrics() {
      try {
        const res = await getSystemStatusMetrics()
        const d = res.data || {}
        this.metrics = d.metrics || []
      } catch (e) {}
    },
    // 运行信息
    async loadInfo() {
      try {
        const res = await getSystemStatusInfo()
        this.sysInfo = res.data || {}
      } catch (e) {}
    },
    // 最近告警
    async loadAlerts() {
      try {
        const res = await getSystemStatusAlerts({ limit: 10 })
        const d = res.data || {}
        this.alerts = d.list || []
        this.alertTotal = d.total || 0
      } catch (e) {}
    },
    // 打开服务详情弹窗
    openDetail(service) {
      this.currentService = service
      this.detailVisible = true
    }
  }
}
</script>

<style scoped>
.ai-status-page { padding: 4px 16px; }

/* ===== 顶部工具栏 ===== */
.filter-bar { display: flex; align-items: center; margin-bottom: 14px; }
.page-title { font-size: 16px; font-weight: 600; color: #303133; }
.update-time { color: #909399; font-size: 12px; }
.flex-1 { flex: 1; }

/* ===== 整体状态汇总 ===== */
.summary-row { margin-bottom: 14px; }
.summary-card { text-align: center; cursor: default; }
.summary-card:hover { box-shadow: 0 2px 10px rgba(0, 0, 0, 0.06); }
.summary-label { font-size: 13px; color: #909399; }
.summary-value { font-size: 28px; font-weight: 700; color: #303133; margin: 6px 0 2px; }
.summary-value.normal { color: #67c23a; }
.summary-value.error { color: #f56c6c; }
.summary-value.unknown { color: #909399; }
.summary-sub { font-size: 11px; color: #c0c4cc; }
.sum-normal { border-top: 2px solid #67c23a; }
.sum-error { border-top: 2px solid #f56c6c; }
.sum-unknown { border-top: 2px solid #909399; }

/* ===== 区块卡片 ===== */
.section-card { margin-bottom: 14px; }
.sec-head { display: flex; align-items: center; justify-content: space-between; }
.sec-sub { font-size: 12px; color: #c0c4cc; font-weight: 400; }
.svc-col { margin-bottom: 14px; }

/* ===== 系统运行信息 ===== */
.sys-info { padding: 0 4px; }
.info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px 20px; margin-bottom: 8px; }
.info-item { display: flex; align-items: baseline; min-width: 0; }
.info-label { width: 84px; flex-shrink: 0; font-size: 12px; color: #909399; }
.info-value {
  font-size: 13px; color: #303133;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.svc-uptime { border-top: 1px dashed #ebeef5; padding-top: 10px; margin-top: 6px; }

/* ===== 告警卡片 ===== */
.alert-card { height: auto; }
.alert-card >>> .el-card__body { padding: 14px 16px; }
</style>
