<!--
  文件：admin/src/views/ai/status/components/AlertList.vue
  功能：最近告警列表
    - 告警级别标签（提示/一般/重要/紧急，颜色区分）
    - 告警内容、触发时间、状态（触发中/已恢复）
    - 紧急告警置顶显示
    - 点击告警跳转监控告警详情页
-->
<template>
  <div class="alert-list">
    <div class="list-toolbar">
      <span class="list-title">最近告警</span>
      <span class="list-count" :class="{ 'has-alert': total > 0 }">{{ total }} 条</span>
    </div>

    <el-scrollbar class="alert-scroll" v-if="sortedAlerts.length">
      <div
        v-for="a in sortedAlerts"
        :key="a.id"
        class="alert-item"
        :class="{ 'is-emergency': a.level === 'emergency' }"
        @click="goDetail(a)"
      >
        <div class="alert-line">
          <el-tag size="mini" :type="levelType(a.level)">{{ a.level_text }}</el-tag>
          <span class="alert-status" :class="'st-' + a.status">{{ a.status_text }}</span>
        </div>
        <div class="alert-content" :title="a.message || a.rule_name">
          {{ a.message || a.rule_name }}
        </div>
        <div class="alert-meta">
          <span>{{ a.rule_name }}</span>
          <span class="alert-time">{{ a.trigger_time }}</span>
        </div>
      </div>
    </el-scrollbar>

    <el-empty v-else description="暂无告警记录" :image-size="50" />
  </div>
</template>

<script>
export default {
  name: 'AlertList',
  props: {
    alerts: { type: Array, default: () => [] },
    total: { type: Number, default: 0 }
  },
  computed: {
    // 紧急告警置顶：后端已按级别排序，前端再兜底排序一次
    sortedAlerts() {
      const weight = { emergency: 0, critical: 1, warning: 2, info: 3 }
      return [...(this.alerts || [])].sort((a, b) => {
        const w = (weight[a.level] ?? 9) - (weight[b.level] ?? 9)
        if (w !== 0) return w
        return String(b.trigger_time || '').localeCompare(String(a.trigger_time || ''))
      })
    }
  },
  methods: {
    // 告警级别标签颜色（与监控告警页保持一致）
    levelType(lv) {
      return { info: 'primary', warning: 'success', critical: 'warning', emergency: 'danger' }[lv] || 'info'
    },
    // 点击跳转到监控告警页（告警历史 Tab，查看详情）
    goDetail(alert) {
      this.$router.push({ path: '/ai/operation/monitor', query: { tab: 'history', alert_id: alert.alert_id } }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.alert-list {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.list-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 10px;
}
.list-title { font-size: 14px; font-weight: 600; color: #303133; }
.list-count { font-size: 12px; color: #c0c4cc; }
.list-count.has-alert { color: #e6a23c; }

.alert-scroll { max-height: 330px; }

.alert-item {
  padding: 10px 12px;
  border: 1px solid #ebeef5;
  border-radius: 6px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: all 0.2s;
  background: #fff;
}
.alert-item:hover { border-color: #409eff; box-shadow: 0 2px 8px rgba(64, 158, 255, 0.12); }
.alert-item.is-emergency { border-color: #fde2e2; background: #fffafa; }
.alert-item.is-emergency:hover { border-color: #f56c6c; }

.alert-line { display: flex; align-items: center; justify-content: space-between; }
.alert-status { font-size: 12px; }
.alert-status.st-triggered { color: #f56c6c; }
.alert-status.st-confirmed { color: #e6a23c; }
.alert-status.st-recovered { color: #67c23a; }

.alert-content {
  font-size: 13px;
  color: #303133;
  margin: 6px 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.alert-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 11px;
  color: #c0c4cc;
}
</style>
