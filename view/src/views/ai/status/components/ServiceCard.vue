<!--
  文件：admin/src/views/ai/status/components/ServiceCard.vue
  功能：单个服务健康状态卡片
    - 状态指示灯（正常绿/异常红/未知灰）
    - 响应时间、可用率、状态描述、最后检查时间
    - 卡片颜色随状态变化，异常卡片红色边框闪烁
    - 点击卡片触发父组件打开服务详情
-->
<template>
  <div class="service-card" :class="'svc-' + status" @click="$emit('click', service)">
    <!-- 卡片头部：图标 + 名称 + 状态点 -->
    <div class="svc-head">
      <div class="svc-icon-wrap">
        <i :class="service.icon || 'el-icon-service'" class="svc-icon"></i>
      </div>
      <div class="svc-title">
        <div class="svc-name">{{ service.name }}</div>
        <div class="svc-status-line">
          <span class="status-dot" :class="'dot-' + status"></span>
          <span class="status-text" :class="'text-' + status">{{ statusText }}</span>
        </div>
      </div>
    </div>

    <!-- 卡片指标 -->
    <div class="svc-metrics">
      <div class="svc-metric">
        <div class="metric-label">响应时间</div>
        <div class="metric-value">{{ service.rt ? service.rt + 'ms' : (status === 'normal' ? '空闲' : '--') }}</div>
      </div>
      <div class="svc-metric">
        <div class="metric-label">可用率(24h)</div>
        <div class="metric-value" :class="{ 'value-danger': availability < 99 }">
          {{ availability !== null && availability !== undefined ? availability + '%' : '--' }}
        </div>
      </div>
    </div>

    <!-- 状态描述 -->
    <div class="svc-desc" :title="service.desc">{{ service.desc }}</div>

    <!-- 最后检查时间 -->
    <div class="svc-footer">
      <i class="el-icon-time"></i>
      <span>{{ lastCheckText }}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ServiceCard',
  props: {
    service: { type: Object, required: true }
  },
  computed: {
    status() { return this.service.status || 'unknown' },
    statusText() { return { normal: '运行正常', error: '响应异常', unknown: '状态未知' }[this.status] || '状态未知' },
    availability() { return this.service.availability },
    lastCheckText() {
      const ts = this.service.check_ts
      if (!ts) return '--'
      const diff = Math.max(0, Math.floor(Date.now() / 1000) - ts)
      if (diff < 5) return '刚刚'
      if (diff < 60) return diff + '秒前'
      if (diff < 3600) return Math.floor(diff / 60) + '分钟前'
      return this.service.last_check || '--'
    }
  }
}
</script>

<style scoped>
.service-card {
  padding: 14px 16px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  transition: all 0.25s;
  height: 100%;
  box-sizing: border-box;
}
.service-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

/* ===== 状态主题：正常 ===== */
.service-card.svc-normal { border-color: #e1f3d8; }
.service-card.svc-normal:hover { border-color: #67c23a; box-shadow: 0 4px 12px rgba(103, 194, 58, 0.15); }
.svc-normal .status-dot.dot-normal { background: #67c23a; box-shadow: 0 0 6px rgba(103, 194, 58, 0.6); }
.svc-normal .status-text.text-normal { color: #67c23a; }

/* ===== 状态主题：异常（红色边框闪烁） ===== */
.service-card.svc-error { border-color: #f56c6c; animation: svc-error-blink 1.6s ease-in-out infinite; }
.service-card.svc-error:hover { box-shadow: 0 4px 12px rgba(245, 108, 108, 0.2); }
.svc-error .status-dot.dot-error { background: #f56c6c; box-shadow: 0 0 6px rgba(245, 108, 108, 0.7); }
.svc-error .status-text.text-error { color: #f56c6c; }

/* ===== 状态主题：未知 ===== */
.service-card.svc-unknown { border-color: #dcdfe6; }
.service-card.svc-unknown:hover { border-color: #909399; }
.svc-unknown .status-dot.dot-unknown { background: #909399; }
.svc-unknown .status-text.text-unknown { color: #909399; }

@keyframes svc-error-blink {
  0%, 100% { border-color: #f56c6c; }
  50% { border-color: #fde2e2; }
}

/* ===== 头部 ===== */
.svc-head { display: flex; align-items: center; margin-bottom: 12px; }
.svc-icon-wrap {
  width: 40px; height: 40px;
  border-radius: 8px;
  background: #ecf5ff;
  display: flex; align-items: center; justify-content: center;
  margin-right: 10px;
  flex-shrink: 0;
}
.svc-icon { font-size: 20px; color: #409eff; }
.svc-error .svc-icon-wrap { background: #fef0f0; }
.svc-error .svc-icon { color: #f56c6c; }
.svc-unknown .svc-icon-wrap { background: #f4f4f5; }
.svc-unknown .svc-icon { color: #909399; }
.svc-title { min-width: 0; }
.svc-name { font-size: 14px; font-weight: 600; color: #303133; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.svc-status-line { display: flex; align-items: center; margin-top: 3px; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 5px; }
.status-text { font-size: 12px; }

/* ===== 指标 ===== */
.svc-metrics { display: flex; justify-content: space-between; margin-bottom: 10px; }
.svc-metric { flex: 1; }
.metric-label { font-size: 12px; color: #909399; }
.metric-value { font-size: 16px; font-weight: 600; color: #303133; margin-top: 2px; }
.metric-value.value-danger { color: #f56c6c; }

/* ===== 描述 ===== */
.svc-desc {
  font-size: 12px; color: #606266;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 36px;
}

/* ===== 底部 ===== */
.svc-footer {
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px dashed #ebeef5;
  font-size: 12px; color: #c0c4cc;
  display: flex; align-items: center; gap: 4px;
}
</style>
