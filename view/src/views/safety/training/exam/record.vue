<template>
  <div class="exam-record-page">
    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入考试名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.exam_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="opt in examTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="onSearch">
            <el-option v-for="opt in examStatusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.paper_id" clearable placeholder="全部试卷" style="width:160px" @change="onSearch">
            <el-option v-for="p in paperOptions" :key="p.id" :label="p.paper_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条考试</span>
          <el-button v-if="hasPerm('safety:training:exam:add')" type="primary" icon="el-icon-plus" @click="openCreate">创建考试</el-button>
          <el-button icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="exam_code" label="考试编号" width="160" show-overflow-tooltip />
        <el-table-column label="考试名称" min-width="160">
          <template slot-scope="{ row }">
            <el-link type="primary" :underline="false" @click="openDetail(row)">{{ row.exam_name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="paper_name" label="试卷名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="考试类型" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.exam_type === 'formal' ? 'danger' : 'success'">{{ row.type_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="考试时间" width="320" align="center">
          <template slot-scope="{ row }">{{ row.start_time }} ~ {{ row.end_time }}</template>
        </el-table-column>
        <el-table-column prop="total_participants" label="应考人数" width="90" align="center" />
        <el-table-column prop="actual_participants" label="实考人数" width="90" align="center" />
        <el-table-column prop="pass_count" label="通过人数" width="90" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTag(row.status)">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="{ row }">
            <template v-if="row.status === 'pending'">
              <el-button v-if="hasPerm('safety:training:exam:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
              <el-button v-if="hasPerm('safety:training:exam:delete')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
              <el-button v-if="hasPerm('safety:training:exam:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
            <template v-else-if="row.status === 'in_progress'">
              <el-button v-if="hasPerm('safety:training:exam:list')" size="mini" type="text" style="color:#67C23A" @click="openMonitor(row)">监控</el-button>
              <el-button v-if="hasPerm('safety:training:exam:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
            <template v-else>
              <el-button v-if="hasPerm('safety:training:exam:list')" size="mini" type="text" @click="openScore(row)">成绩</el-button>
              <el-button v-if="hasPerm('safety:training:exam:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 创建/编辑 -->
    <exam-create-dialog :visible.sync="createVisible" :row="currentRow" :paper-options="paperOptions" @saved="onSaved" />
    <!-- 监控 -->
    <exam-monitor-dialog :visible.sync="monitorVisible" :row="monitorRow" @saved="onSaved" />
    <!-- 成绩 -->
    <exam-score-dialog :visible.sync="scoreVisible" :row="scoreRow" />
    <!-- 详情 -->
    <el-dialog title="考试详情" :visible.sync="detailVisible" width="760px" append-to-body>
      <el-descriptions v-if="detail" :column="2" size="small" border>
        <el-descriptions-item label="考试编号">{{ detail.exam_code }}</el-descriptions-item>
        <el-descriptions-item label="考试名称">{{ detail.exam_name }}</el-descriptions-item>
        <el-descriptions-item label="试卷名称">{{ detail.paper_name }}</el-descriptions-item>
        <el-descriptions-item label="考试类型">{{ detail.type_text }}</el-descriptions-item>
        <el-descriptions-item label="考试时间">{{ detail.start_time }} ~ {{ detail.end_time }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ detail.status_text }}</el-descriptions-item>
        <el-descriptions-item label="时长">{{ detail.duration_minutes }} 分钟</el-descriptions-item>
        <el-descriptions-item label="应考人数">{{ detail.total_participants }}</el-descriptions-item>
        <el-descriptions-item label="考试须知" :span="2">{{ detail.exam_notice || '-' }}</el-descriptions-item>
      </el-descriptions>
      <el-table v-if="detail && detail.attendees && detail.attendees.length" :data="detail.attendees" size="mini" border style="margin-top:12px;" max-height="240">
        <el-table-column prop="user_name" label="姓名" width="120" />
        <el-table-column label="状态" width="100">
          <template slot-scope="{ row }">{{ ['未开始','进行中','已交卷'][row.status] || '未开始' }}</template>
        </el-table-column>
        <el-table-column label="实名验证" width="110" align="center">
          <template slot-scope="{ row }">
            <el-tooltip v-if="row.face_verified == 1 && row.id_card_verified == 1" :content="'身份证✓ 人脸' + (row.face_score ?? '-') + '分'" placement="top">
              <el-tag size="mini" type="success">已实名</el-tag>
            </el-tooltip>
            <el-tag v-else size="mini" type="info">未实名</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="score" label="得分" width="80" align="center" />
        <el-table-column prop="submit_time" label="交卷时间" show-overflow-tooltip />
      </el-table>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getExamList, getExamDetail, deleteExam, getAvailablePapers } from '@/api/trainingExam'
import ExamCreateDialog from './components/ExamCreateDialog.vue'
import ExamMonitorDialog from './components/ExamMonitorDialog.vue'
import ExamScoreDialog from './components/ExamScoreDialog.vue'

export default {
  name: 'ExamRecord',
  components: { ExamCreateDialog, ExamMonitorDialog, ExamScoreDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', exam_type: '', status: '', paper_id: null },
      examTypeOptions: [], examStatusOptions: [],
      paperOptions: [],
      createVisible: false, monitorVisible: false, scoreVisible: false,
      currentRow: null, monitorRow: null, scoreRow: null,
      detailVisible: false, detail: null,
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadPapers(); this.loadList(); this.loadDicts()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    // 考试类型/状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('exam_type'); this.examTypeOptions = r.data || [] } catch (e) { this.examTypeOptions = [] }
      try { const r = await getDictByCode('exam_status'); this.examStatusOptions = r.data || [] } catch (e) { this.examStatusOptions = [] }
    },
    async loadPapers() {
      try { const r = await getAvailablePapers(); this.paperOptions = r.data || [] } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getExamList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          exam_type: this.filters.exam_type || '',
          status: this.filters.status || '',
          paper_id: this.filters.paper_id || '',
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', exam_type: '', status: '', paper_id: null }; this.page = 1; this.loadList() },
    statusTag(s) { return { pending: '', in_progress: 'success', ended: 'info' }[s] || 'info' },
    onSaved() { this.loadList(); this.loadPapers() },
    openCreate() { this.currentRow = null; this.createVisible = true },
    openEdit(row) { this.currentRow = row; this.createVisible = true },
    openMonitor(row) { this.monitorRow = row; this.monitorVisible = true },
    openScore(row) { this.scoreRow = row; this.scoreVisible = true },
    async openDetail(row) {
      try {
        const r = await getExamDetail(row.id)
        if (r.code === 0) { this.detail = r.data; this.detailVisible = true }
      } catch (e) {}
    },
    doDelete(row) {
      this.$confirm(`确认删除考试「${row.exam_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteExam(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
  },
}
</script>
