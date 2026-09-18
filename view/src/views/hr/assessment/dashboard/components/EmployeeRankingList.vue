<!-- 个人排名列表（前/后 TOP） -->
<template>
  <div class="panel-card">
    <div class="panel-head">
      <span class="panel-title">🏅 个人排名 {{ order === 'desc' ? 'TOP' + list.length : '后' + list.length }}</span>
      <el-radio-group v-model="order" size="mini" @change="$emit('order-change', order)">
        <el-radio-button label="desc">前{{ list.length }}</el-radio-button>
        <el-radio-button label="asc">后{{ list.length }}</el-radio-button>
      </el-radio-group>
    </div>
    <el-table :data="list" size="small" border stripe empty-text="暂无排名数据" max-height="300" @row-click="row => $emit('view', row)">
      <el-table-column prop="rank" label="排名" width="60" align="center" />
      <el-table-column prop="employee_name" label="姓名" width="80" />
      <el-table-column prop="department_name" label="部门" width="100" />
      <el-table-column prop="score" label="得分" width="70" align="center" />
      <el-table-column prop="grade" label="等级" width="60" align="center">
        <template slot-scope="s"><span class="grade-badge" :style="gradeStyle(s.row.grade)">{{ s.row.grade }}</span></template>
      </el-table-column>
      <el-table-column prop="top_deduction" label="主要扣分项" min-width="140" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.top_deduction || '—' }}</template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script>
const GRADE_COLORS = { A: '#00b42a', B: '#1e6fff', C: '#ffb020', D: '#f53f3f' }

export default {
  name: 'DashboardEmployeeRanking',
  props: {
    list: { type: Array, default: () => [] },
    order: { type: String, default: 'desc' }
  },
  methods: {
    gradeStyle (g) {
      return { background: (GRADE_COLORS[g] || '#909399') + '22', color: GRADE_COLORS[g] || '#909399' }
    }
  }
}
</script>

<style scoped>
.panel-card { background: #fff; border: 1px solid #e8ecf1; border-radius: 12px; padding: 14px 16px; }
.panel-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.panel-title { font-size: 14px; font-weight: 600; color: #1d2129; }
.grade-badge { display: inline-block; width: 22px; height: 22px; line-height: 22px; border-radius: 50%; font-weight: 600; font-size: 12px; }
</style>
