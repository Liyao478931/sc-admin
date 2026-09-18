<template>
  <div class="exam-score-page">
    <!-- 统计卡片 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="4" v-for="card in statCards" :key="card.label">
        <el-card shadow="never" :body-style="{ padding: '14px 16px' }">
          <div class="stat-card">
            <div class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="card.icon" /></div>
            <div class="stat-info"><div class="stat-num">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 趋势图 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <div style="font-size:14px;font-weight:600;margin-bottom:10px;">成绩趋势（近 12 个月）</div>
      <score-trend-chart />
    </el-card>

    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入员工姓名或工号" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable placeholder="全部部门" style="width:130px" @change="onSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.exam_id" clearable placeholder="全部考试" style="width:160px" @change="onSearch">
            <el-option v-for="e in examOptions" :key="e.id" :label="e.exam_name" :value="e.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.paper_id" clearable placeholder="全部试卷" style="width:150px" @change="onSearch">
            <el-option v-for="p in paperOptions" :key="p.id" :label="p.paper_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.exam_type" clearable placeholder="全部类型" style="width:110px" @change="onSearch">
            <el-option v-for="opt in examTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.is_pass" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="合格" :value="1" /><el-option label="不合格" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条成绩记录</span>
          <el-button v-if="hasPerm('safety:training:exam:export')" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出</el-button>
          <el-button icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="员工姓名" width="80">
          <template slot-scope="{ row }">
            <el-link type="primary" :underline="false" @click="openByUser(row)">{{ row.user_name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="department" label="所属部门" width="100" show-overflow-tooltip />
        <el-table-column prop="position" label="岗位" width="100" show-overflow-tooltip />
        <el-table-column label="考试名称" min-width="140" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-link type="primary" :underline="false" @click="openByExam(row)">{{ row.exam_name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="paper_name" label="试卷名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="score" label="得分" width="80" align="center" />
        <el-table-column label="合格状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.is_pass == 1 ? 'success' : 'danger'">{{ row.pass_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="实名验证" width="110" align="center">
          <template slot-scope="{ row }">
            <el-tooltip v-if="row.face_verified == 1 && row.id_card_verified == 1" :content="'身份证✓ 人脸' + (row.face_score ?? '-') + '分' + (row.face_verified_at ? ' ' + row.face_verified_at : '')" placement="top">
              <el-tag size="mini" type="success">已实名</el-tag>
            </el-tooltip>
            <el-tag v-else size="mini" type="info">未实名</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="type_text" label="考试类型" width="80" align="center" />
        <el-table-column prop="start_time" label="考试时间" width="160" align="center" />
        <el-table-column prop="submit_time" label="交卷时间" width="160" align="center" />
        <el-table-column label="操作" width="100" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:exam:query')" size="mini" type="text" @click="openAnswer(row)">答卷</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <score-answer-detail-dialog :visible.sync="answerVisible" :exam-id="answerExamId" :user-id="answerUserId" />
    <exam-score-by-exam-dialog :visible.sync="byExamVisible" :row="byExamRow" @view-answer="openAnswerByExam" />
    <exam-score-by-user-dialog :visible.sync="byUserVisible" :row="byUserRow" @view-answer="openAnswerByUser" />
  </div>
</template>

<script>
import { getScoreList, getScoreStatistics, exportScoreList, getExamList, getPaperList } from '@/api/trainingExam'
import { getDeptTree } from '@/api/organization'
import ScoreTrendChart from './components/ScoreTrendChart.vue'
import ScoreAnswerDetailDialog from './components/ScoreAnswerDetailDialog.vue'
import ExamScoreByExamDialog from './components/ExamScoreByExamDialog.vue'
import ExamScoreByUserDialog from './components/ExamScoreByUserDialog.vue'

export default {
  name: 'ExamScore',
  components: { ScoreTrendChart, ScoreAnswerDetailDialog, ExamScoreByExamDialog, ExamScoreByUserDialog },
  data() {
    return {
      loading: false, exporting: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', department_id: null, exam_id: null, paper_id: null, exam_type: '', is_pass: '' },
      examTypeOptions: [],
      dateRange: null,
      statCards: [
        { label: '总考试人次', value: 0, icon: 'el-icon-user', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '合格人次', value: 0, icon: 'el-icon-circle-check', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '不合格人次', value: 0, icon: 'el-icon-circle-close', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
        { label: '平均分', value: 0, icon: 'el-icon-data-line', color: '#8B5CF6', bg: 'rgba(139,92,246,.12)' },
        { label: '最高分', value: 0, icon: 'el-icon-top', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '通过率(%)', value: 0, icon: 'el-icon-percent', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
      ],
      deptOptions: [], examOptions: [], paperOptions: [],
      answerVisible: false, answerExamId: 0, answerUserId: 0,
      byExamVisible: false, byExamRow: null,
      byUserVisible: false, byUserRow: null,
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadOptions()
    this.loadAll()
    this.loadDicts()
  },
methods: {
  // 考试类型从字典动态加载
  async loadDicts() {
    const { getDictByCode } = await import('../../../../api/dictionary')
    try { const r = await getDictByCode('exam_type'); this.examTypeOptions = r.data || [] } catch (e) { this.examTypeOptions = [] }
  },
  hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || '',
        department_id: this.filters.department_id || '',
        exam_id: this.filters.exam_id || '',
        paper_id: this.filters.paper_id || '',
        exam_type: this.filters.exam_type || '',
        is_pass: this.filters.is_pass === '' ? '' : this.filters.is_pass,
        ...extra,
      }
      if (this.dateRange && this.dateRange.length === 2) {
        p.start_date = this.dateRange[0]
        p.end_date = this.dateRange[1]
      }
      return p
    },
    async loadOptions() {
      try {
        const [d, e, p] = await Promise.all([getDeptTree(), getExamList({ page: 1, limit: 100 }), getPaperList({ page: 1, limit: 100 })])
        this.deptOptions = d.data || []
        this.examOptions = (e.data && e.data.list) || []
        this.paperOptions = (p.data && p.data.list) || []
      } catch (err) {}
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getScoreList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getScoreStatistics()
        if (r.code === 0 && r.data) {
          const d = r.data
          this.statCards[0].value = d.total || 0
          this.statCards[1].value = d.passed || 0
          this.statCards[2].value = d.failed || 0
          this.statCards[3].value = d.avg_score || 0
          this.statCards[4].value = d.max_score || 0
          this.statCards[5].value = d.pass_rate || 0
        }
      } catch (e) {}
    },
    loadAll() { this.loadList(); this.loadStatistics() },
    onSearch() { this.page = 1; this.loadAll() },
    resetFilters() {
      this.filters = { keyword: '', department_id: null, exam_id: null, paper_id: null, exam_type: '', is_pass: '' }
      this.dateRange = null; this.page = 1; this.loadAll()
    },
    openAnswer(row) { this.answerExamId = row.exam_id; this.answerUserId = row.user_id; this.answerVisible = true },
    openByExam(row) { this.byExamRow = row; this.byExamVisible = true },
    openByUser(row) { this.byUserRow = row; this.byUserVisible = true },
    openAnswerByExam(payload) { this.answerExamId = payload.exam_id; this.answerUserId = payload.user_id; this.answerVisible = true },
    openAnswerByUser(payload) { this.answerExamId = payload.exam_id; this.answerUserId = payload.user_id; this.answerVisible = true },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportScoreList(this.buildParams())
        if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
      } catch (e) {}
      this.exporting = false
    },
  },
}
</script>

<style scoped>
.stat-card { display: flex; align-items: center; }
.stat-icon { width: 46px; height: 46px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 24px; margin-right: 12px; }
.stat-num { font-size: 22px; font-weight: 600; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; }
</style>
