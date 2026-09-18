<template>
  <div class="pref-page">
    <div class="page-head">
      <h2>消息设置</h2>
      <span class="page-sub">管理您的消息接收偏好</span>
    </div>

    <div v-loading="loading" class="pref-body">
      <!-- 消息类型接收设置 -->
      <el-card shadow="never" class="pref-card">
        <div slot="header" class="card-head">
          <span class="card-title">消息类型接收设置</span>
          <span class="card-desc">选择您希望接收的消息类型，关闭后将不再接收该类消息</span>
        </div>
        <div class="type-grid">
          <div v-for="(t, key) in MSG_TYPES" :key="key" class="type-item">
            <div class="type-info">
              <div class="type-name">{{ t.label }}</div>
              <div class="type-desc">{{ t.desc }}</div>
            </div>
            <el-switch v-model="form.msg_types[key]" />
          </div>
        </div>
      </el-card>

      <!-- 接收渠道设置 -->
      <el-card shadow="never" class="pref-card">
        <div slot="header" class="card-head">
          <span class="card-title">接收渠道设置</span>
          <span class="card-desc">选择您希望接收消息的渠道，系统将优先使用已开启的渠道推送消息</span>
        </div>
        <div class="channel-list">
          <div v-for="(c, key) in CHANNELS" :key="key" class="channel-item">
            <div class="channel-info">
              <div class="channel-name">
                {{ c.label }}
                <el-tag v-if="c.must" size="mini" type="warning">必选</el-tag>
              </div>
              <div class="channel-desc">{{ c.desc }}</div>
            </div>
            <el-tooltip :content="c.must ? '站内信为必选渠道，不可关闭' : ''" :disabled="!c.must">
              <el-switch v-model="form.channels[key]" :disabled="c.must" />
            </el-tooltip>
          </div>
        </div>
      </el-card>

      <!-- 免打扰时段设置 -->
      <el-card shadow="never" class="pref-card">
        <div slot="header" class="card-head">
          <span class="card-title">免打扰时段设置</span>
          <span class="card-desc">免打扰时段内，新消息将静音处理，站内信仍正常接收</span>
        </div>
        <div class="quiet-row">
          <span class="quiet-label">启用免打扰</span>
          <el-switch v-model="quietEnabled" />
          <template v-if="quietEnabled">
            <el-time-picker v-model="quietStart" placeholder="开始时间" format="HH:mm" value-format="HH:mm" :picker-options="startPickerOptions" style="width:130px;margin-left:16px;" />
            <span style="margin:0 8px;color:#909399;">至</span>
            <el-time-picker v-model="quietEnd" placeholder="结束时间" format="HH:mm" value-format="HH:mm" style="width:130px;" />
          </template>
        </div>
        <div v-if="quietEnabled" class="quiet-tip">
          <i class="el-icon-info"></i> 免打扰时段内不推送声音和桌面通知
        </div>
      </el-card>

      <!-- 声音与桌面通知设置 -->
      <el-card shadow="never" class="pref-card">
        <div slot="header" class="card-head">
          <span class="card-title">声音与桌面通知设置</span>
        </div>
        <div class="opt-row">
          <div class="opt-info">
            <div class="opt-name">新消息提示音</div>
            <div class="opt-desc">开启后，新消息到达时播放提示音</div>
          </div>
          <div class="opt-actions">
            <el-button size="mini" icon="el-icon-video-play" @click="previewSound">预览</el-button>
            <el-switch v-model="form.sound_enabled" :active-value="1" :inactive-value="0" />
          </div>
        </div>
        <div class="opt-row">
          <div class="opt-info">
            <div class="opt-name">桌面通知</div>
            <div class="opt-desc">开启后，新消息到达时弹出系统桌面通知</div>
          </div>
          <el-switch v-model="form.desktop_enabled" :active-value="1" :inactive-value="0" @change="onDesktopToggle" />
        </div>
        <div class="opt-row">
          <div class="opt-info">
            <div class="opt-name">通知内容摘要</div>
            <div class="opt-desc">开启后，桌面通知显示消息标题和内容摘要；关闭后仅显示“您有一条新消息”</div>
          </div>
          <el-switch v-model="form.desktop_summary" :active-value="1" :inactive-value="0" />
        </div>
      </el-card>
    </div>

    <!-- 底部操作 -->
    <div class="pref-footer">
      <el-button type="primary" :loading="saving" @click="save">保存设置</el-button>
      <el-button @click="resetDefault">恢复默认</el-button>
      <el-button @click="$router.back()">取消</el-button>
    </div>
  </div>
</template>

<script>
import { getNotificationPreference, saveNotificationPreference } from '@/api/notificationPreference'

// 消息类型
const MSG_TYPES = {
  system: { label: '系统公告', desc: '系统发布的重要公告和通知' },
  task: { label: '任务指派', desc: '任务分配、工单派单等指派类通知' },
  approval: { label: '审批通知', desc: '审批流转、审批结果等审批类通知' },
  alert: { label: '预警提醒', desc: '隐患预警、证书到期、年检到期等预警类通知' },
  training: { label: '培训通知', desc: '培训安排、考试安排等培训类通知' },
  order: { label: '工单通知', desc: '维修工单、保养工单等工单类通知' }
}

// 接收渠道
const CHANNELS = {
  inbox: { label: '站内信', desc: '系统内消息列表（必选）', must: true },
  email: { label: '邮件', desc: '通过邮件发送消息' },
  sms: { label: '短信', desc: '通过短信发送消息' },
  wechat: { label: '微信', desc: '通过微信公众号模板消息推送' },
  dingtalk: { label: '钉钉', desc: '通过钉钉工作通知推送' },
  workwx: { label: '企业微信', desc: '通过企业微信应用消息推送' }
}

const DEFAULT = {
  msg_types: { system: true, task: true, approval: true, alert: true, training: true, order: true },
  channels: { inbox: true, email: false, sms: false, wechat: false, dingtalk: false, workwx: false },
  sound_enabled: 1,
  desktop_enabled: 1,
  desktop_summary: 1
}

export default {
  name: 'NotificationPreference',
  data () {
    return {
      MSG_TYPES,
      CHANNELS,
      loading: false,
      saving: false,
      form: JSON.parse(JSON.stringify(DEFAULT)),
      quietEnabled: false,
      quietStart: '',
      quietEnd: '',
      startPickerOptions: {
        selectableRange: '00:00:00-23:59:59'
      }
    }
  },
  created () {
    this.load()
  },
  methods: {
    async load () {
      this.loading = true
      try {
        const r = await getNotificationPreference()
        if (r.code === 0) {
          const d = r.data || {}
          this.form = {
            msg_types: Object.assign({}, DEFAULT.msg_types, d.msg_types || {}),
            channels: Object.assign({}, DEFAULT.channels, d.channels || {}),
            sound_enabled: d.sound_enabled === 0 ? 0 : 1,
            desktop_enabled: d.desktop_enabled === 0 ? 0 : 1,
            desktop_summary: d.desktop_summary === 0 ? 0 : 1
          }
          this.quietEnabled = !!(d.quiet_start && d.quiet_end)
          this.quietStart = d.quiet_start || ''
          this.quietEnd = d.quiet_end || ''
        }
      } catch (e) {} finally { this.loading = false }
    },
    // 桌面通知：开启时请求浏览器权限
    onDesktopToggle (val) {
      if (!val) return
      if (!('Notification' in window)) {
        this.$message.warning('当前浏览器不支持桌面通知')
        this.form.desktop_enabled = 0
        return
      }
      if (Notification.permission === 'granted') return
      Notification.requestPermission().then(perm => {
        if (perm !== 'granted') {
          this.$message.warning('请在浏览器设置中允许桌面通知')
          this.form.desktop_enabled = 0
        }
      })
    },
    // 预览提示音（Web Audio 生成 beep）
    previewSound () {
      try {
        const ctx = new (window.AudioContext || window.webkitAudioContext)()
        const osc = ctx.createOscillator()
        const gain = ctx.createGain()
        osc.connect(gain)
        gain.connect(ctx.destination)
        osc.frequency.value = 880
        osc.type = 'sine'
        gain.gain.setValueAtTime(0.2, ctx.currentTime)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4)
        osc.start()
        osc.stop(ctx.currentTime + 0.4)
      } catch (e) {
        this.$message.error('浏览器不支持音频播放')
      }
    },
    // 保存校验
    validate () {
      // 站内信必选
      if (!this.form.channels.inbox) {
        this.$message.warning('站内信为必选渠道，不可关闭')
        return false
      }
      // 免打扰时间
      if (this.quietEnabled) {
        if (!this.quietStart || !this.quietEnd) {
          this.$message.warning('请选择免打扰开始与结束时间')
          return false
        }
        if (this.quietStart >= this.quietEnd) {
          this.$message.warning('开始时间不能晚于结束时间')
          return false
        }
      }
      return true
    },
    async save () {
      if (!this.validate()) return
      this.saving = true
      try {
        const d = {
          msg_types: this.form.msg_types,
          channels: this.form.channels,
          quiet_start: this.quietEnabled ? this.quietStart : '',
          quiet_end: this.quietEnabled ? this.quietEnd : '',
          sound_enabled: this.form.sound_enabled,
          desktop_enabled: this.form.desktop_enabled,
          desktop_summary: this.form.desktop_summary
        }
        const r = await saveNotificationPreference(d)
        if (r.code === 0) {
          this.$message.success('设置保存成功')
          this.load()
        }
      } catch (e) {} finally { this.saving = false }
    },
    resetDefault () {
      this.$confirm('确认恢复所有设置为默认值？', '提示', { type: 'warning' }).then(() => {
        this.form = JSON.parse(JSON.stringify(DEFAULT))
        this.quietEnabled = false
        this.quietStart = ''
        this.quietEnd = ''
        this.$message.success('已恢复默认，请点击保存生效')
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.pref-page { padding: 16px; background: #f0f2f5; min-height: 100%; padding-bottom: 80px; }
.page-head { margin-bottom: 16px; }
.page-head h2 { margin: 0; font-size: 20px; color: #303133; }
.page-sub { font-size: 12px; color: #909399; margin-left: 8px; }
.pref-card { margin-bottom: 16px; }
.card-head { display: flex; align-items: baseline; gap: 12px; }
.card-title { font-size: 15px; font-weight: 600; color: #303133; }
.card-desc { font-size: 12px; color: #909399; }
.type-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px 24px; }
.type-item, .channel-item, .opt-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 4px; border-bottom: 1px solid #f5f7fa; }
.type-item:last-child, .channel-item:last-child, .opt-row:last-child { border-bottom: none; }
.type-name, .channel-name, .opt-name { font-size: 14px; color: #303133; }
.type-desc, .channel-desc, .opt-desc { font-size: 12px; color: #909399; margin-top: 2px; }
.quiet-row { display: flex; align-items: center; }
.quiet-label { font-size: 14px; color: #303133; margin-right: 12px; }
.quiet-tip { margin-top: 10px; font-size: 12px; color: #E6A23C; }
.opt-actions { display: flex; align-items: center; gap: 10px; }
.pref-footer { position: fixed; bottom: 0; left: 210px; right: 0; background: #fff; padding: 12px 20px; box-shadow: 0 -2px 8px rgba(0,0,0,.06); display: flex; gap: 10px; z-index: 10; }
</style>
