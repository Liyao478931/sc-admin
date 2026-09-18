<template>
  <el-dialog title="任务详情" :visible.sync="dialogVisible" width="850px" top="5vh" append-to-body @open="loadDetail">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="base">
          <div class="sec-title">任务信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="任务编号">{{ detail && detail.task_code }}</el-descriptions-item>
            <el-descriptions-item label="任务状态">
              <el-tag size="mini" :type="statusTagType(detail.status)">{{ detail.status_text }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="计划执行日期">{{ detail.plan_execute_date }}</el-descriptions-item>
            <el-descriptions-item label="实际执行日期">{{ detail.actual_execute_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="执行耗时">{{ detail.execute_duration != null ? detail.execute_duration + ' 分钟' : '-' }}</el-descriptions-item>
            <el-descriptions-item label="问题数量">{{ detail.issue_count || 0 }}</el-descriptions-item>
          </el-descriptions>

          <div class="sec-title">计划信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="计划名称">{{ detail.plan_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="计划编号">{{ detail.plan_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="检查周期">{{ detail.cycle_type_text || '-' }}</el-descriptions-item>
            <el-descriptions-item label="检查类型">{{ detail.inspection_type_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="检查区域">{{ detail.area || '-' }}</el-descriptions-item>
            <el-descriptions-item label="下次执行">{{ detail.next_execute_date || '-' }}</el-descriptions-item>
          </el-descriptions>

          <div class="sec-title">执行信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="负责人">{{ detail.leader_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="执行人">{{ detail?.executor_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="取消原因">{{ detail.cancel_reason || '-' }}</el-descriptions-item>
          </el-descriptions>
          <div v-if="detail.summary" class="sec-title">检查总结</div>
          <div v-if="detail.summary" style="background:#f8f9fb;border-radius:6px;padding:10px;font-size:13px;line-height:1.8">{{ detail.summary }}</div>
        </el-tab-pane>

        <!-- 检查项目 -->
        <el-tab-pane label="检查项目" name="items">
          <el-empty v-if="!(detail.template_items || []).length" description="暂无检查项目" :image-size="60" />
          <el-table v-else :data="detail.template_items" size="small" border stripe>
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="item_name" label="检查项目" min-width="140" />
            <el-table-column prop="check_standard" label="检查标准" min-width="160" show-overflow-tooltip />
            <el-table-column prop="check_method" label="检查方法" min-width="140" show-overflow-tooltip />
            <el-table-column label="必查" width="70" align="center">
              <template slot-scope="{ row }">{{ row.is_required ? '是' : '否' }}</template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 问题记录 -->
        <el-tab-pane :label="`问题记录${(detail.issues || []).length ? '(' + detail.issues.length + ')' : ''}`" name="issues">
          <el-empty v-if="!(detail.issues || []).length" description="暂无问题记录" :image-size="60" />
          <el-table v-else :data="detail.issues" size="small" border stripe>
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="item_name" label="检查项目" min-width="130" />
            <el-table-column prop="issue_description" label="问题描述" min-width="180" show-overflow-tooltip />
            <el-table-column label="严重程度" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="{ minor: 'info', major: 'warning', critical: 'danger' }[row.severity] || 'info'">{{ row.severity_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="suggest" label="整改建议" min-width="140" show-overflow-tooltip />
            <el-table-column label="隐患" width="90" align="center">
              <template slot-scope="{ row }">
                <el-link v-if="row.hazard_id" type="danger">已转隐患</el-link>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="row.status === 'resolved' ? 'success' : 'info'">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getTaskDetail } from '@/api/safetyInspectionTask'

export default {
  name: 'TaskDetailDialog',
  props: {
    visible: Boolean,
    taskId: { type: Number, default: 0 },
  },
  data() {
    return { dialogVisible: this.visible, loading: false, activeTab: 'base', detail: {} }
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    statusTagType(v) {
      return { pending: 'primary', in_progress: 'warning', completed: 'success', overdue: 'danger', cancelled: 'info' }[v] || 'info'
    },
    async loadDetail() {
      if (!this.taskId) return
      this.loading = true
      try {
        const r = await getTaskDetail(this.taskId)
        if (r.code === 0) this.detail = r.data || {}
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>

<style scoped>
.sec-title { font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 14px 0 10px; }
</style>
