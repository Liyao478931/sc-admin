<template>
  <el-dialog title="任务详情" :visible.sync="visible" width="800px" :close-on-click-modal="false">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <div class="info-section">
            <div class="section-title">任务信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="任务编号">{{ detail.task_code || '-' }}</el-descriptions-item>
              <el-descriptions-item label="状态"><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_text }}</el-tag></el-descriptions-item>
              <el-descriptions-item label="计划执行日期">{{ detail.plan_execute_date || '-' }}</el-descriptions-item>
              <el-descriptions-item label="实际执行日期">{{ detail.actual_execute_date || '-' }}</el-descriptions-item>
              <el-descriptions-item label="提醒次数">{{ detail.remind_count || 0 }}</el-descriptions-item>
              <el-descriptions-item label="取消原因">{{ detail.cancel_reason || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
          <div class="info-section">
            <div class="section-title">计划信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="计划名称">{{ detail.plan_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="保养等级">{{ detail.level_name || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
          <div class="info-section">
            <div class="section-title">设备信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="设备名称">{{ detail.device_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="设备编码">{{ detail.device_code || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
          <div class="info-section">
            <div class="section-title">执行信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="执行人">{{ detail.executor_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="验收人">{{ detail.acceptor_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="执行开始">{{ detail.execute_start_time || '-' }}</el-descriptions-item>
              <el-descriptions-item label="执行结束">{{ detail.execute_end_time || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
        </el-tab-pane>

        <!-- 模板预览 -->
        <el-tab-pane label="模板预览" name="template">
          <el-table :data="detail.template_items || []" size="small" border stripe>
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="item_name" label="项目名称" min-width="140" />
            <el-table-column prop="operation_content" label="操作内容" min-width="160" show-overflow-tooltip />
            <el-table-column prop="check_standard" label="检查标准" min-width="140" show-overflow-tooltip />
            <el-table-column label="必做" width="60" align="center">
              <template slot-scope="{row}"><el-tag :type="row.is_required ? 'success' : 'info'" size="mini">{{ row.is_required ? '是' : '否' }}</el-tag></template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!detail.template_items || !detail.template_items.length" description="无模板项目" :image-size="60" />
        </el-tab-pane>

        <!-- 状态历史 -->
        <el-tab-pane label="状态历史" name="history">
          <el-timeline v-if="detail.status_history && detail.status_history.length">
            <el-timeline-item v-for="h in detail.status_history" :key="h.id" :timestamp="h.created_at" placement="top">
              <div class="history-item">
                <div><strong>{{ h.action }}</strong> <span style="color:#909399;font-size:12px">by {{ h.real_name || 'system' }}</span></div>
                <div style="font-size:13px;color:#606266">{{ h.detail }}</div>
              </div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无状态历史" :image-size="60" />
        </el-tab-pane>
      </el-tabs>
    </div>
    <span slot="footer"><el-button type="primary" @click="visible = false">关闭</el-button></span>
  </el-dialog>
</template>

<script>
import { getTaskDetail } from '@/api/maintenanceTask'

export default {
  name: 'TaskDetailDialog',
  props: {
    visible: Boolean,
    taskId: { type: Number, default: 0 }
  },
  data() {
    return {
      activeTab: 'info', loading: false, detail: {}
    }
  },
  watch: {
    visible(v) { if (v) this.loadDetail() }
  },
  methods: {
    async loadDetail() {
      this.loading = true
      try { const r = await getTaskDetail(this.taskId); if (r.code === 0) this.detail = r.data } catch (e) {}
      this.loading = false
    },
    statusType(s) { return { pending: '', in_progress: 'warning', completed: 'success', overdue: 'danger', cancelled: 'info' }[s] || '' }
  }
}
</script>

<style scoped>
.info-section { margin-bottom: 16px; }
.section-title { font-weight: 600; margin-bottom: 8px; padding-left: 8px; border-left: 3px solid #409EFF; }
</style>
