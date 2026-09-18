<template>
  <el-dialog title="发送详情" :visible="visible" @update:visible="$emit('update:visible', $event)" width="700px" top="6vh" @open="load">
    <div v-loading="loading">
      <template v-if="detail.id">
        <!-- 基本信息 -->
        <div class="sec-title">基本信息</div>
        <div class="detail-meta">
          <span><b>消息标题：</b>{{ detail.title }}</span>
          <span><el-tag size="mini" :style="typeStyle(detail.msg_type)">{{ detail.msg_type_text }}</el-tag></span>
          <span><el-tag size="mini" :style="channelStyle(detail.channel)">{{ detail.channel_text }}</el-tag></span>
          <span><el-tag size="mini" :type="statusType(detail.send_status)">{{ detail.status_text }}</el-tag></span>
          <span><b>发送时间：</b>{{ detail.send_time || '-' }}</span>
        </div>

        <!-- 接收人信息 -->
        <div class="sec-title">接收人信息</div>
        <div class="detail-meta">
          <span><b>姓名：</b>{{ detail.to_user_name || '-' }}</span>
          <span><b>邮箱：</b>{{ detail.to_user_email || '-' }}</span>
          <span><b>手机号：</b>{{ detail.to_user_phone || '-' }}</span>
        </div>

        <!-- 消息内容 -->
        <div class="sec-title">消息内容</div>
        <div class="content-box" v-html="detail.content_snapshot || '（无内容快照）'"></div>

        <!-- 发送结果 -->
        <div class="sec-title">发送结果</div>
        <div class="detail-meta">
          <span><b>响应码：</b>{{ detail.response_code || '-' }}</span>
          <span><b>重试次数：</b>{{ detail.retry_count || 0 }}</span>
        </div>
        <div class="resp-msg"><b>响应信息：</b>{{ detail.response_msg || '-' }}</div>

        <!-- 多渠道明细 -->
        <template v-if="detail.siblings && detail.siblings.length">
          <div class="sec-title">各渠道发送明细</div>
          <el-table :data="detail.siblings" size="mini" border>
            <el-table-column prop="channel_text" label="渠道" width="90" />
            <el-table-column label="状态" width="80">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="statusType(row.send_status)">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="send_time" label="发送时间" width="160" />
            <el-table-column prop="response_code" label="响应码" width="100" />
            <el-table-column prop="retry_count" label="重试" width="60" align="center" />
          </el-table>
        </template>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getNotificationLogDetail } from '@/api/notificationLog'

const TYPE_MAP = {
  1: { label: '系统公告', color: '#909399' },
  2: { label: '任务指派', color: '#409EFF' },
  3: { label: '审批通知', color: '#E6A23C' },
  4: { label: '预警提醒', color: '#F56C6C' },
  5: { label: '培训通知', color: '#67C23A' },
  6: { label: '工单通知', color: '#8E44AD' }
}
const CHANNEL_COLOR = {
  inbox: '#409EFF', email: '#67C23A', sms: '#E6A23C', wechat: '#67C23A', dingtalk: '#409EFF', workwx: '#409EFF'
}

export default {
  name: 'NotificationLogDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    logId: { type: Number, default: 0 }
  },
  data () {
    return { loading: false, detail: {} }
  },
  methods: {
    async load () {
      if (!this.logId) return
      this.loading = true
      try {
        const r = await getNotificationLogDetail(this.logId)
        if (r.code === 0) this.detail = r.data || {}
      } catch (e) {} finally { this.loading = false }
    },
    typeStyle (t) { const c = (TYPE_MAP[t] || {}).color || '#909399'; return { color: c, borderColor: c, background: c + '1a' } },
    channelStyle (c) { const col = CHANNEL_COLOR[c] || '#909399'; return { color: col, borderColor: col, background: col + '1a' } },
    statusType (s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger' }[s] || 'info' }
  }
}
</script>

<style scoped>
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 10px 0 8px; }
.detail-meta { display: flex; flex-wrap: wrap; gap: 14px; font-size: 13px; color: #333; margin-bottom: 6px; align-items: center; }
.content-box { border: 1px solid #EBEEF5; border-radius: 6px; padding: 12px; background: #fafbfc; font-size: 14px; line-height: 1.8; word-break: break-all; max-height: 220px; overflow-y: auto; }
.resp-msg { font-size: 13px; color: #333; margin-top: 6px; word-break: break-all; }
</style>
