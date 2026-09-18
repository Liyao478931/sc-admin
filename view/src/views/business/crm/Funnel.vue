<template>
  <div class="page-container">
    <el-row :gutter="14" class="stat-row">
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ totalCount }}</div><div class="stat-label">商机总数</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ winCount }}</div><div class="stat-label">赢单数</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ openCount }}</div><div class="stat-label">进行中</div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num red">¥{{ totalAmount.toLocaleString() }}</div><div class="stat-label">商机金额</div></el-card></el-col>
    </el-row>
    <el-row :gutter="14">
      <el-col :span="10">
        <el-card shadow="never" header="销售漏斗">
          <div v-loading="loading" style="height:420px">
            <div v-for="(f, i) in funnel" :key="f.stage" class="funnel-item">
              <div class="funnel-label">{{ f.name }} <span class="funnel-sub">({{ f.count }}个 / ¥{{ Number(f.amount || 0).toLocaleString() }})</span></div>
              <div class="funnel-bar-wrap">
                <div class="funnel-bar" :style="{ width: barWidth(f, i), background: barColor(i) }"></div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="14">
        <el-card shadow="never" header="各阶段明细">
          <el-table :data="funnel" v-loading="loading" border stripe size="small">
            <el-table-column prop="name" label="阶段" width="120" />
            <el-table-column prop="count" label="商机数" width="90" />
            <el-table-column prop="amount" label="金额(¥)" min-width="130"><template #default="{row}">{{ Number(row.amount || 0).toLocaleString() }}</template></el-table-column>
            <el-table-column label="占比" min-width="120">
              <template #default="{row}">{{ totalCount ? ((row.count / totalCount) * 100).toFixed(1) + '%' : '0%' }}</template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>
<script>
import request from '@/api/request'
export default {
  name: 'CrmFunnel',
  data() {
    return { loading: false, funnel: [], totalCount: 0, winCount: 0, openCount: 0, totalAmount: 0 }
  },
  created() { this.load() },
  methods: {
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/crm/funnel', method: 'get' })
        if (res.code === 0) {
          this.funnel = res.data.funnel || []
          this.totalCount = this.funnel.reduce((s, x) => s + (x.count || 0), 0)
          this.totalAmount = this.funnel.reduce((s, x) => s + Number(x.amount || 0), 0)
          const win = this.funnel.find(x => x.stage === 5)
          this.winCount = win ? win.count : 0
          this.openCount = this.funnel.filter(x => x.stage >= 1 && x.stage <= 4).reduce((s, x) => s + (x.count || 0), 0)
        }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    barWidth(f, i) {
      const max = Math.max(...this.funnel.map(x => x.count || 0), 1)
      return Math.max(8, Math.round(((f.count || 0) / max) * 100)) + '%'
    },
    barColor(i) {
      const colors = ['#409EFF', '#5CB8FF', '#67C23A', '#E6A23C', '#F56C6C', '#909399']
      return colors[i % colors.length]
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 22px; font-weight: 700; color: #333; }
.stat-num.blue { color: #409EFF; } .stat-num.orange { color: #E6A23C; } .stat-num.red { color: #F56C6C; }
.stat-label { color: #909399; font-size: 13px; margin-top: 4px; }
.funnel-item { margin-bottom: 18px; }
.funnel-label { font-size: 13px; margin-bottom: 6px; }
.funnel-sub { color: #909399; font-weight: 400; }
.funnel-bar-wrap { background: #f2f6fc; border-radius: 4px; height: 26px; overflow: hidden; }
.funnel-bar { height: 100%; border-radius: 4px; transition: width .4s; }
</style>
