<!-- 低分预警列表 -->
<template>
  <div class="panel-card">
    <div class="panel-head">
      <span class="panel-title">🚨 预警列表</span>
      <span class="panel-count">{{ list.length }} 条</span>
    </div>
    <el-table :data="list" size="small" border stripe empty-text="暂无预警" max-height="300">
      <el-table-column prop="employee_name" label="姓名" width="80" />
      <el-table-column prop="department_name" label="部门" width="100" />
      <el-table-column label="近3月得分" width="140">
        <template slot-scope="s">{{ (s.row.scores || []).join(', ') || '—' }}</template>
      </el-table-column>
      <el-table-column label="趋势" width="60" align="center">
        <template slot-scope="s">
          <span :class="s.row.trend === 'down' ? 'trend-down' : s.row.trend === 'up' ? 'trend-up' : 'trend-stable'">
            {{ s.row.trend === 'down' ? '↓' : s.row.trend === 'up' ? '↑' : '→' }}
          </span>
        </template>
      </el-table-column>
      <el-table-column prop="warning_type" label="预警原因" min-width="140" show-overflow-tooltip />
      <el-table-column label="操作" width="90" align="center">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$emit('view', s.row)">查看</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script>
export default {
  name: 'DashboardWarningList',
  props: {
    list: { type: Array, default: () => [] }
  }
}
</script>

<style scoped>
.panel-card { background: #fff; border: 1px solid #e8ecf1; border-radius: 12px; padding: 14px 16px; }
.panel-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.panel-title { font-size: 14px; font-weight: 600; color: #1d2129; }
.panel-count { font-size: 12px; color: #8c8f9c; }
.trend-down { color: #f53f3f; font-weight: 600; }
.trend-up { color: #00b42a; font-weight: 600; }
.trend-stable { color: #8c8f9c; }
</style>
