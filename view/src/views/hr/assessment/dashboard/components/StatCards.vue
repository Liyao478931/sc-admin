<!-- 概览统计卡片（6 个） -->
<template>
  <div class="stat-cards">
    <div class="stat-card" :style="{ borderTopColor: '#1e6fff' }" @click="$emit('click-card', { type: 'total' })">
      <div class="sc-icon">👥</div>
      <div class="sc-info">
        <div class="sc-value">{{ data.total_employees || 0 }}</div>
        <div class="sc-label">总人数</div>
      </div>
    </div>
    <div class="stat-card" :style="{ borderTopColor: '#00b42a' }" @click="$emit('click-card', { type: 'avg' })">
      <div class="sc-icon">📈</div>
      <div class="sc-info">
        <div class="sc-value">{{ data.avg_score || 0 }}</div>
        <div class="sc-label">平均分</div>
        <div v-if="data.compare_last_month" class="sc-sub" :class="data.compare_last_month.change_rate >= 0 ? 'up' : 'down'">
          {{ data.compare_last_month.change_rate >= 0 ? '↑' : '↓' }} {{ Math.abs(data.compare_last_month.change_rate) }}% 环比
        </div>
      </div>
    </div>
    <div class="stat-card clickable" :style="{ borderTopColor: '#ffb020' }" @click="$emit('click-card', { type: 'max' })">
      <div class="sc-icon">⭐</div>
      <div class="sc-info">
        <div class="sc-value">{{ data.max_score || '—' }}</div>
        <div class="sc-label">最高分 · {{ data.max_score_employee || '—' }}</div>
      </div>
    </div>
    <div class="stat-card clickable" :style="{ borderTopColor: '#f53f3f' }" @click="$emit('click-card', { type: 'min' })">
      <div class="sc-icon">📉</div>
      <div class="sc-info">
        <div class="sc-value">{{ data.min_score || '—' }}</div>
        <div class="sc-label">最低分 · {{ data.min_score_employee || '—' }}</div>
      </div>
    </div>
    <div class="stat-card" :style="{ borderTopColor: '#ffb020' }">
      <div class="sc-icon">⏳</div>
      <div class="sc-info">
        <div class="sc-value warn">{{ data.pending_deductions || 0 }}</div>
        <div class="sc-label">待确认扣分</div>
        <div class="sc-sub">条扣分明细</div>
      </div>
    </div>
    <div class="stat-card clickable" :style="{ borderTopColor: '#f53f3f' }" @click="$emit('click-card', { type: 'warning' })">
      <div class="sc-icon">🚨</div>
      <div class="sc-info">
        <div class="sc-value warn">{{ data.warning_count || 0 }}</div>
        <div class="sc-label">预警人数</div>
        <div class="sc-sub">低于阈值需关注</div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DashboardStatCards',
  props: {
    data: { type: Object, default: () => ({}) }
  }
}
</script>

<style scoped>
.stat-cards { display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px; }
.stat-card { background: #fff; border: 1px solid #e8ecf1; border-top: 3px solid #1e6fff; border-radius: 12px; padding: 16px; display: flex; align-items: center; gap: 12px; cursor: default; transition: box-shadow .15s; }
.stat-card.clickable { cursor: pointer; }
.stat-card.clickable:hover { box-shadow: 0 4px 14px rgba(0,0,0,.08); }
.sc-icon { font-size: 26px; }
.sc-info { flex: 1; min-width: 0; }
.sc-value { font-size: 22px; font-weight: 600; color: #1d2129; }
.sc-value.warn { color: #f53f3f; }
.sc-label { font-size: 12px; color: #8c8f9c; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.sc-sub { font-size: 11px; color: #8c8f9c; }
.sc-sub.up { color: #00b42a; }
.sc-sub.down { color: #f53f3f; }
@media (max-width: 1400px) { .stat-cards { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 768px) { .stat-cards { grid-template-columns: repeat(2, 1fr); } }
</style>
