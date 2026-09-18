<template>
  <el-dialog title="员工培训档案" :visible.sync="dialogVisible" width="900px" top="5vh" append-to-body @open="loadDetail">
    <div v-loading="loading">
      <!-- 员工基本信息 -->
      <el-card shadow="never" style="margin-bottom:14px;">
        <div slot="header"><b>员工信息</b></div>
        <el-descriptions :column="4" size="small" border>
          <el-descriptions-item label="姓名">{{ detail.user ? detail.user.name : '-' }}</el-descriptions-item>
          <el-descriptions-item label="部门">{{ detail.user ? detail.user.department_name : '-' }}</el-descriptions-item>
          <el-descriptions-item label="岗位">{{ detail.user ? detail.user.position_name : '-' }}</el-descriptions-item>
          <el-descriptions-item label="工号">{{ detail.user ? detail.user.employee_id : '-' }}</el-descriptions-item>
          <el-descriptions-item label="入职日期">{{ detail.user ? detail.user.hire_date : '-' }}</el-descriptions-item>
          <el-descriptions-item label="联系方式">{{ detail.user ? detail.user.phone : '-' }}</el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 培训统计 -->
      <el-card shadow="never" style="margin-bottom:14px;">
        <div slot="header"><b>培训统计</b></div>
        <el-row :gutter="16">
          <el-col :span="6"><div class="stat-box"><div class="stat-val">{{ stats.total_count }}</div><div class="stat-lbl">总培训次数</div></div></el-col>
          <el-col :span="6"><div class="stat-box"><div class="stat-val green">{{ stats.completed_count }}</div><div class="stat-lbl">已完成次数</div></div></el-col>
          <el-col :span="6"><div class="stat-box"><div class="stat-val blue">{{ stats.rate }}%</div><div class="stat-lbl">完成率</div></div></el-col>
          <el-col :span="6"><div class="stat-box"><div class="stat-val orange">{{ stats.avg_score }}</div><div class="stat-lbl">平均评估得分</div></div></el-col>
        </el-row>
      </el-card>

      <!-- 培训履历 -->
      <el-card shadow="never">
        <div slot="header" class="card-header">
          <span><b>培训履历</b></span>
          <div>
            <el-select v-model="historyFilters.training_type_id" clearable placeholder="全部类型" size="small" style="width:130px" @change="loadHistory(1)">
              <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
            </el-select>
            <el-select v-model="historyFilters.status" clearable placeholder="全部状态" size="small" style="width:110px" @change="loadHistory(1)">
              <el-option v-for="opt in recordStatusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
            <el-date-picker v-model="historyDateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" size="small" style="width:230px" placeholder="培训日期" />
            <el-button v-if="hasPerm('safety:training:archive:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          </div>
        </div>
        <el-table :data="historyList" size="small" border stripe max-height="320">
          <el-table-column type="index" label="序号" width="55" />
          <el-table-column prop="plan_name" label="培训名称" min-width="150" />
          <el-table-column prop="training_type_name" label="培训类型" width="100" align="center" />
          <el-table-column prop="mode_text" label="方式" width="80" align="center" />
          <el-table-column prop="training_date" label="培训日期" width="110" align="center">
            <template slot-scope="{ row }">{{ row.training_date || '-' }}</template>
          </el-table-column>
          <el-table-column label="状态" width="90" align="center">
            <template slot-scope="{ row }">
              <el-tag size="mini" :type="row.is_completed === 1 ? 'success' : 'info'">{{ row.status_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="evaluation_score" label="评估得分" width="90" align="center">
            <template slot-scope="{ row }">{{ row.evaluation_score != null ? row.evaluation_score : '-' }}</template>
          </el-table-column>
        </el-table>
        <el-pagination v-if="historyTotal > 0" style="margin-top:10px;text-align:right" background layout="total, prev, pager, next" small
          :total="historyTotal" :current-page.sync="historyPage" :page-size="10" @current-change="loadHistory(historyPage)" />
      </el-card>
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getArchiveDetail, getArchiveHistory, exportArchiveHistory, getTypeOptions } from '@/api/safetyTrainingArchive'

export default {
  name: 'ArchiveDetailDialog',
  props: {
    visible: Boolean,
    userId: { type: Number, default: 0 },
  },
  data() {
    return {
      dialogVisible: this.visible,
      loading: false,
      detail: {},
      stats: {},
      historyList: [],
      historyTotal: 0,
      historyPage: 1,
      historyFilters: { training_type_id: null, status: '' },
      historyDateRange: null,
      typeOptions: [],
      recordStatusOptions: []
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val; if (val) this.loadDicts() },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    // 培训记录状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../../api/dictionary')
      try { const r = await getDictByCode('training_record_status'); this.recordStatusOptions = r.data || [] } catch (e) { this.recordStatusOptions = [] }
    },
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadDetail() {
      if (!this.userId) return
      this.loading = true
      try {
        const r = await getArchiveDetail(this.userId)
        if (r.code === 0) { this.detail = r.data || {}; this.stats = r.data.stats || {} }
      } catch (e) {}
      try { const t = await getTypeOptions(); if (t.code === 0) this.typeOptions = t.data || [] } catch (e) {}
      this.loadHistory(1)
      this.loading = false
    },
    async loadHistory(page) {
      this.historyPage = page || 1
      try {
        const r = await getArchiveHistory(this.userId, {
          page: this.historyPage, limit: 10,
          training_type_id: this.historyFilters.training_type_id || '',
          status: this.historyFilters.status || '',
          start_date: this.historyDateRange ? this.historyDateRange[0] : '',
          end_date: this.historyDateRange ? this.historyDateRange[1] : ''
        })
        if (r.code === 0) { this.historyList = r.data.list || []; this.historyTotal = r.data.total || 0 }
      } catch (e) {}
    },
    doExport() {
      this.$confirm('确认导出该员工培训履历？', '导出确认', { type: 'info' }).then(async () => {
        try {
          const r = await exportArchiveHistory(this.userId, {
            training_type_id: this.historyFilters.training_type_id || '',
            status: this.historyFilters.status || '',
            start_date: this.historyDateRange ? this.historyDateRange[0] : '',
            end_date: this.historyDateRange ? this.historyDateRange[1] : ''
          })
          if (r.code === 0 && r.data && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.stat-box { background: #f8f9fb; border-radius: 8px; padding: 14px; text-align: center; }
.stat-val { font-size: 24px; font-weight: 700; color: #303133; }
.stat-val.green { color: #67C23A; }
.stat-val.blue { color: #409EFF; }
.stat-val.orange { color: #E6A23C; }
.stat-lbl { font-size: 12px; color: #909399; margin-top: 4px; }
</style>
