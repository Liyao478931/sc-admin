<!-- 文件：admin/src/views/ai/reports/list.vue（v1.65.0 报告列表 + 定时任务） -->
<template>
  <div class="report-list">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>智能报告</span><i class="el-icon-arrow-right"></i><span class="cur">报告列表</span></div>

    <!-- 操作栏 -->
    <div class="toolbar">
      <el-button type="primary" size="small" icon="el-icon-plus" @click="$router.push('/ai/reports/generate')">生成报告</el-button>
      <el-button size="small" icon="el-icon-s-operation" @click="scheduleVisible = true; loadSchedules()">定时任务</el-button>
      <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      <div class="toolbar-right">
        <el-input v-model="keyword" size="small" placeholder="报告名称" clearable style="width:180px" @keyup.enter.native="loadList" />
        <el-select v-model="status" size="small" placeholder="状态" clearable style="width:120px" @change="loadList">
          <el-option label="已完成" :value="1" />
          <el-option label="生成中" :value="0" />
          <el-option label="失败" :value="2" />
        </el-select>
        <el-button size="small" icon="el-icon-search" @click="loadList">查询</el-button>
      </div>
    </div>

    <!-- 列表 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe>
      <el-table-column type="index" label="#" width="50" align="center" />
      <el-table-column prop="report_name" label="报告名称" min-width="180" show-overflow-tooltip />
      <el-table-column prop="template_name" label="模板" width="110" align="center" />
      <el-table-column prop="time_range" label="时间范围" width="130" align="center" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="create_time" label="生成时间" width="150" align="center" />
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-if="s.row.status === 1" type="text" size="mini" @click="viewReport(s.row)">查看</el-button>
          <el-button v-if="s.row.status === 1" type="text" size="mini" @click="download(s.row, 'pdf')">PDF</el-button>
          <el-button v-if="s.row.status === 1" type="text" size="mini" @click="download(s.row, 'word')">Word</el-button>
          <el-button type="text" size="mini" @click="regenerate(s.row)">重新生成</el-button>
          <el-button type="text" size="mini" class="del" @click="remove(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pager">
      <span>共 {{ total }} 条</span>
      <el-pagination background layout="prev, pager, next" :total="total" :page-size="limit" :current-page.sync="page" @current-change="loadList" />
    </div>

    <!-- 预览弹窗 -->
    <el-dialog :title="preview.report_name || '报告预览'" :visible.sync="previewVisible" width="760px" top="6vh">
      <div class="preview-body" v-html="preview.content"></div>
      <span slot="footer">
        <el-button size="small" @click="previewVisible = false">关闭</el-button>
      </span>
    </el-dialog>

    <!-- 定时任务弹窗 -->
    <el-dialog title="定时报告任务" :visible.sync="scheduleVisible" width="720px" top="6vh">
      <el-form :inline="true" size="small">
        <el-form-item label="任务名称"><el-input v-model="scheduleForm.schedule_name" style="width:200px" /></el-form-item>
        <el-form-item label="模板">
          <el-select v-model="scheduleForm.template_id" style="width:140px">
            <el-option v-for="t in templates" :key="t.id" :label="t.template_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="频率">
          <el-select v-model="scheduleForm.frequency" style="width:100px">
            <el-option label="每日" value="daily" />
            <el-option label="每周" value="weekly" />
            <el-option label="每月" value="monthly" />
          </el-select>
        </el-form-item>
        <el-form-item label="执行时间"><el-input v-model="scheduleForm.run_time" style="width:110px" placeholder="09:00 或 1 09:00" /></el-form-item>
        <el-form-item label="时间范围">
          <el-select v-model="scheduleForm.time_range" style="width:120px">
            <el-option label="上月" value="last_month" />
            <el-option label="本月" value="current_month" />
            <el-option label="本季" value="current_quarter" />
          </el-select>
        </el-form-item>
        <el-form-item><el-button type="primary" @click="saveSchedule">保存任务</el-button></el-form-item>
      </el-form>
      <el-table :data="schedules" size="small" border>
        <el-table-column prop="schedule_name" label="任务名称" min-width="140" />
        <el-table-column prop="template_name" label="模板" width="90" />
        <el-table-column prop="frequency_label" label="频率" width="70" align="center" />
        <el-table-column prop="run_time" label="执行时间" width="90" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-switch :value="!!s.row.status" size="mini" @change="v => toggleSchedule(s.row, v)" />
          </template>
        </el-table-column>
        <el-table-column prop="last_run_at" label="上次执行" width="140" align="center">
          <template slot-scope="s">{{ s.row.last_run_at || '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="del" @click="removeSchedule(s.row)">删除</el-button></template>
        </el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script>
import { getReportList, getReportDetail, deleteReport, downloadReportFile, streamReportRegenerate, getReportTemplates, saveReportSchedule, operateReportSchedule, getReportSchedules } from '@/api/aiReport'

export default {
  name: 'AiReportList',
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false,
      keyword: '', status: '',
      previewVisible: false, preview: {},
      scheduleVisible: false, schedules: [], templates: [],
      scheduleForm: { schedule_name: '', template_id: null, frequency: 'daily', run_time: '09:00', time_range: 'last_month' }
    }
  },
  created () { this.loadList(); this.loadTemplates() },
  methods: {
    async loadList () {
      this.loading = true
      try {
        const r = await getReportList({ page: this.page, limit: this.limit, keyword: this.keyword, status: this.status })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async loadTemplates () {
      try { const r = await getReportTemplates(); if (r.code === 0) this.templates = r.data.list || [] } catch (e) {}
    },
    async loadSchedules () {
      try { const r = await getReportSchedules(); if (r.code === 0) this.schedules = r.data.list || [] } catch (e) {}
    },
    async viewReport (row) {
      try {
        const r = await getReportDetail(row.id)
        if (r.code === 0) { this.preview = r.data; this.previewVisible = true }
      } catch (e) {}
    },
    async download (row, fmt) {
      try { await downloadReportFile(row.id, fmt); this.$message.success('下载已开始') } catch (e) { this.$message.error('下载失败') }
    },
    remove (row) {
      this.$confirm(`确认删除报告「${row.report_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try { const r = await deleteReport(row.id); if (r.code === 0) { this.$message.success('已删除'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    async regenerate (row) {
      if (this.regenerating) return
      this.regenerating = true
      this.$message.info('正在重新生成...')
      try {
        await streamReportRegenerate(row.id, (evt) => {
          if (evt.type === 'result') { this.$message.success('重新生成完成'); this.loadList() }
          else if (evt.type === 'error') this.$message.error(evt.message || '重新生成失败')
        })
      } catch (e) { this.$message.error('重新生成失败') } finally { this.regenerating = false }
    },
    async saveSchedule () {
      if (!this.scheduleForm.schedule_name || !this.scheduleForm.template_id) { this.$message.warning('请填写任务名称并选择模板'); return }
      try {
        const r = await saveReportSchedule({ ...this.scheduleForm, action: 'save' })
        if (r.code === 0) { this.$message.success('任务已保存'); this.loadSchedules() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {}
    },
    async toggleSchedule (row, v) {
      try { await operateReportSchedule(row.id, 'toggle', v ? 1 : 0); this.$message.success(v ? '已启用' : '已停用'); this.loadSchedules() } catch (e) {}
    },
    removeSchedule (row) {
      this.$confirm(`确认删除定时任务「${row.schedule_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try { const r = await operateReportSchedule(row.id, 'delete'); if (r.code === 0) { this.$message.success('已删除'); this.loadSchedules() } } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; gap: 8px; padding: 12px 16px; background: #fff; }
.toolbar-right { margin-left: auto; display: flex; gap: 8px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; background: #fff; }
.preview-body { background: #fff; border: 1px solid #ebeef5; border-radius: 6px; padding: 16px; max-height: 60vh; overflow-y: auto; }
.del { color: #f56c6c; }
</style>
