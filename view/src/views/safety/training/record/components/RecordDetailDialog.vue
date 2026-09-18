<template>
  <el-dialog title="培训记录详情" :visible.sync="dialogVisible" width="950px" top="5vh" append-to-body @open="loadDetail">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="base">
          <div class="sec-title">记录信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="记录编号">{{ detail.record_code }}</el-descriptions-item>
            <el-descriptions-item label="记录状态">
              <el-tag size="mini" :type="detail.status === 'completed' ? 'success' : 'primary'">{{ detail.status_text }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="培训日期">{{ detail.training_date || '-' }}</el-descriptions-item>
          </el-descriptions>
          <div class="sec-title">计划信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="计划名称">{{ detail.plan_name }}</el-descriptions-item>
            <el-descriptions-item label="培训类型">{{ detail.training_type_name }}</el-descriptions-item>
            <el-descriptions-item label="培训方式">{{ detail.mode_text }}</el-descriptions-item>
            <el-descriptions-item label="培训地点">{{ detail.location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="培训内容" :span="3">{{ detail.content || '-' }}</el-descriptions-item>
          </el-descriptions>
          <div class="sec-title">培训信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="讲师">{{ detail.teacher_names || '-' }}</el-descriptions-item>
            <el-descriptions-item label="课件">{{ detail.courseware_names || '-' }}</el-descriptions-item>
            <el-descriptions-item label="负责人">{{ detail.responsible_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="计划人数">{{ detail.plan_count }}</el-descriptions-item>
            <el-descriptions-item label="实到人数">{{ detail.actual_count }}</el-descriptions-item>
            <el-descriptions-item label="培训时长">{{ detail.duration_hours }}h</el-descriptions-item>
          </el-descriptions>
          <div class="sec-title">签到设置</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="签到地点">{{ detail.checkin_location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="签到范围">{{ detail.checkin_radius || 100 }} 米</el-descriptions-item>
            <el-descriptions-item label="签到经纬度">{{ detail.checkin_lat != null ? detail.checkin_lat + ', ' + detail.checkin_lng : '未设置' }}</el-descriptions-item>
            <el-descriptions-item label="签到开始">{{ detail.checkin_start_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="签到结束">{{ detail.checkin_end_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="实际签到人数">{{ detail.actual_count }}</el-descriptions-item>
          </el-descriptions>
          <div class="sec-title">评估信息</div>
          <el-descriptions :column="3" size="small" border>
            <el-descriptions-item label="评估得分">{{ detail.evaluation_score != null ? detail.evaluation_score : '-' }}</el-descriptions-item>
            <el-descriptions-item label="评估等级">{{ detail.evaluation_level_text || '-' }}</el-descriptions-item>
            <el-descriptions-item label="评估意见" :span="3">{{ detail.evaluation_opinion || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 参训人员 -->
        <el-tab-pane :label="`参训人员(${(detail.attendees || []).length})`" name="attendees">
          <el-table v-if="(detail.attendees || []).length" :data="detail.attendees" size="small" border stripe max-height="420">
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="user_name" label="姓名" min-width="100" />
            <el-table-column prop="department" label="部门" min-width="120">
              <template slot-scope="{ row }">{{ row.department || '-' }}</template>
            </el-table-column>
            <el-table-column prop="position" label="岗位" min-width="120">
              <template slot-scope="{ row }">{{ row.position || '-' }}</template>
            </el-table-column>
            <el-table-column label="完成状态" width="90" align="center">
              <template slot-scope="{ row }">
                <span v-if="detail.is_online === 1">
                  <el-tag v-if="row.is_trained === 1" size="mini" type="success">已完成</el-tag>
                  <el-tag v-else size="mini" type="info">未完成</el-tag>
                </span>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column label="签到状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag v-if="detail.is_online !== 1" size="mini" :type="row.checkin_status === 'signed' ? 'success' : 'info'">{{ row.checkin_status_text }}</el-tag>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column prop="checkin_time" label="签到时间" width="150" align="center">
              <template slot-scope="{ row }">{{ row.checkin_time || '-' }}</template>
            </el-table-column>
            <el-table-column prop="checkin_address" label="签到地点" min-width="120" show-overflow-tooltip>
              <template slot-scope="{ row }">{{ row.checkin_address || (row.checkin_status === 'signed' ? '后台签到' : '-') }}</template>
            </el-table-column>
            <el-table-column label="偏差距离" width="90" align="center">
              <template slot-scope="{ row }">{{ row.checkin_deviation != null ? row.checkin_deviation + 'm' : '-' }}</template>
            </el-table-column>
          </el-table>
          <el-empty v-else description="暂无参训人员" :image-size="60" />
        </el-tab-pane>

        <!-- 课件列表 -->
        <el-tab-pane label="课件列表" name="coursewares">
          <el-table v-if="(detail.coursewares || []).length" :data="detail.coursewares" size="small" border stripe>
            <el-table-column type="index" label="序号" width="60" />
            <el-table-column prop="courseware_name" label="课件名称" min-width="180" />
            <el-table-column prop="file_type" label="文件类型" width="100" align="center" />
            <el-table-column label="操作" width="160" align="center">
              <template slot-scope="{ row }">
                <el-button v-if="row.file_type === 'pdf'" size="mini" type="text" @click="previewCw(row)">预览</el-button>
                <el-button size="mini" type="text" @click="downloadCw(row)">下载</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-else description="暂无关联课件" :image-size="60" />
        </el-tab-pane>

        <!-- 培训总结 -->
        <el-tab-pane label="培训总结" name="summary">
          <div class="summary-box">{{ detail.summary || '暂无培训总结' }}</div>
        </el-tab-pane>
      </el-tabs>
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getRecordDetail } from '@/api/safetyTrainingRecord'
import request from '@/api/request'
import { getToken } from '@/utils/auth'

export default {
  name: 'RecordDetailDialog',
  props: {
    visible: Boolean,
    recordId: { type: Number, default: 0 },
  },
  data() {
    return { dialogVisible: this.visible, loading: false, activeTab: 'base', detail: {} }
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    async loadDetail() {
      if (!this.recordId) return
      this.loading = true
      try {
        const r = await getRecordDetail(this.recordId)
        if (r.code === 0) this.detail = r.data || {}
      } catch (e) {}
      this.loading = false
    },
    previewCw(row) {
      window.open(row.file_path, '_blank')
    },
    async downloadCw(row) {
      // blob 下载：token 走 Authorization header，避免明文 token 进入 URL/日志
      try {
        const resp = await request({ url: '/safety/training/courseware/download/' + row.id, method: 'get', responseType: 'blob' })
        const blob = new Blob([resp.data])
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = (row.courseware_name || 'courseware') + '.' + (row.file_type || 'file')
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('下载失败') }
    }
  }
}
</script>

<style scoped>
.sec-title { font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 14px 0 10px; }
.summary-box { background: #f8f9fb; border-radius: 6px; padding: 16px; font-size: 14px; line-height: 1.8; color: #303133; }
</style>
