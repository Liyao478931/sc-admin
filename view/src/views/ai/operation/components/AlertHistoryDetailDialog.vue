<template>
  <el-dialog title="告警详情" :visible.sync="visible" width="640px" append-to-body>
    <div v-if="detail" class="alert-detail">
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="告警名称">{{ detail.rule_name }}</el-descriptions-item>
        <el-descriptions-item label="监控指标">{{ detail.metric_text }}</el-descriptions-item>
        <el-descriptions-item label="告警级别">
          <el-tag size="mini" :type="levelType(detail.level)">{{ detail.level_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag size="mini" :type="statusType(detail.status)">{{ detail.status_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="触发值">{{ detail.current_value }}</el-descriptions-item>
        <el-descriptions-item label="阈值">{{ detail.threshold }}</el-descriptions-item>
        <el-descriptions-item label="触发时间">{{ detail.trigger_time }}</el-descriptions-item>
        <el-descriptions-item label="恢复时间">{{ detail.recover_time || '--' }}</el-descriptions-item>
        <el-descriptions-item label="告警消息" :span="2">{{ detail.message || '--' }}</el-descriptions-item>
      </el-descriptions>

      <div class="notify-title">通知记录（{{ (notifications || []).length }}）</div>
      <el-table :data="notifications" size="mini" stripe>
        <el-table-column prop="channel_text" label="渠道" width="90" />
        <el-table-column prop="receiver_name" label="接收人" width="140" />
        <el-table-column prop="send_time" label="发送时间" width="170" />
        <el-table-column label="状态" width="80">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.send_status === 'success' ? 'success' : 'danger'">{{ s.row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="error_message" label="错误信息" min-width="120" show-overflow-tooltip />
      </el-table>
      <el-empty v-if="!notifications || !notifications.length" description="暂无通知记录" :image-size="60" />
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getAlertHistoryDetail } from '../../../../api/aiMonitor'

export default {
  name: 'AlertHistoryDetailDialog',
  data() {
    return {
      visible: false,
      detail: null,
      notifications: []
    }
  },
  methods: {
    levelType(lv) { return { info: 'primary', warning: 'success', critical: 'warning', emergency: 'danger' }[lv] || 'info' },
    statusType(st) { return { triggered: 'danger', confirmed: 'warning', recovered: 'success' }[st] || 'info' },
    async open(id) {
      this.visible = true
      this.detail = null
      this.notifications = []
      try {
        const res = await getAlertHistoryDetail(id)
        this.detail = res.data.alert || {}
        this.notifications = res.data.notifications || []
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.notify-title { margin: 16px 0 8px; font-weight: 600; }
</style>
