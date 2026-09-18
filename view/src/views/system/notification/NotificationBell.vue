<template>
  <el-popover placement="bottom" width="330" trigger="click" v-model="visible" popper-class="bell-popover">
    <div class="bell-panel">
      <div class="bell-head">
        <span class="bell-title">消息通知</span>
        <el-button type="text" size="mini" @click="readAll">全部标记已读</el-button>
      </div>
      <div v-if="items.length" class="bell-list">
        <div v-for="m in items" :key="m.id" class="bell-item" @click="go(m)">
          <el-tag size="mini" :style="tagStyle(typeOf(m.msg_type))">{{ typeOf(m.msg_type).label }}</el-tag>
          <div class="bell-item-body">
            <div class="bell-item-title">{{ m.title }}</div>
            <div class="bell-item-time">{{ formatRelative(m.send_time) }}</div>
          </div>
        </div>
      </div>
      <div v-else class="bell-empty">
        <i class="el-icon-bell"></i>
        <p>暂无未读消息</p>
      </div>
      <div class="bell-foot">
        <el-link type="primary" :underline="false" @click="goAll">查看全部消息 <i class="el-icon-arrow-right"></i></el-link>
      </div>
    </div>
    <el-badge :value="count" :hidden="count <= 0" :max="99" slot="reference" class="bell-badge">
      <i class="el-icon-bell navbar-bell" @click="load"></i>
    </el-badge>
  </el-popover>
</template>

<script>
import { getUnreadCount, getTopUnread, readAllNotifications } from '@/api/notification'

// 消息类型：1系统公告 2任务指派 3审批通知 4预警提醒 5培训通知 6工单通知
const TYPE_MAP = {
  1: { label: '系统公告', color: '#909399' },
  2: { label: '任务指派', color: '#409EFF' },
  3: { label: '审批通知', color: '#E6A23C' },
  4: { label: '预警提醒', color: '#F56C6C' },
  5: { label: '培训通知', color: '#67C23A' },
  6: { label: '工单通知', color: '#8E44AD' }
}

export default {
  name: 'NotificationBell',
  data () {
    return {
      count: 0,
      items: [],
      visible: false,
      timer: null
    }
  },
  mounted () {
    this.load()
    // 未读数轮询（默认 5 秒）
    this.timer = setInterval(() => this.load(), 5000)
  },
  beforeDestroy () {
    if (this.timer) clearInterval(this.timer)
  },
  methods: {
    async load () {
      try {
        const [c, t] = await Promise.all([getUnreadCount(), getTopUnread()])
        if (c.code === 0) this.count = c.data.count || 0
        if (t.code === 0) this.items = t.data.list || []
      } catch (e) {}
    },
    async readAll () {
      try {
        const r = await readAllNotifications()
        if (r.code === 0) {
          this.$message.success('已全部标记为已读')
          this.count = 0
          this.items = []
        }
      } catch (e) {}
    },
    typeOf (type) { return TYPE_MAP[type] || { label: '未知', color: '#909399' } },
    tagStyle (t) { return { color: t.color, borderColor: t.color, background: t.color + '1a' } },
    formatRelative (time) {
      if (!time) return '-'
      const t = new Date(time.replace(/-/g, '/')).getTime()
      if (isNaN(t)) return time
      const diff = (Date.now() - t) / 1000
      if (diff < 60) return '刚刚'
      if (diff < 3600) return Math.floor(diff / 60) + '分钟前'
      if (diff < 86400) return Math.floor(diff / 3600) + '小时前'
      if (diff < 604800) return Math.floor(diff / 86400) + '天前'
      return time.substring(0, 16)
    },
    // 点击消息 → 跳消息列表并打开详情
    go (m) {
      this.visible = false
      this.$router.push({ path: '/system/notification/messages', query: { id: m.id } })
    },
    goAll () {
      this.visible = false
      this.$router.push('/system/notification/messages')
    }
  }
}
</script>

<style scoped>
.bell-badge { display: inline-flex; align-items: center; margin-right: 4px; }
.navbar-bell { font-size: 18px; cursor: pointer; padding: 8px; color: inherit; }
.navbar-bell:hover { color: var(--brand-color, #409EFF); }
.bell-panel { font-family: inherit; }
.bell-head { display: flex; justify-content: space-between; align-items: center; padding-bottom: 8px; border-bottom: 1px solid #EBEEF5; }
.bell-title { font-size: 14px; font-weight: 600; color: #303133; }
.bell-list { max-height: 300px; overflow-y: auto; }
.bell-item { display: flex; align-items: flex-start; gap: 8px; padding: 10px 4px; border-bottom: 1px solid #f0f2f5; cursor: pointer; }
.bell-item:hover { background: #f5f7fa; }
.bell-item-body { flex: 1; min-width: 0; }
.bell-item-title { font-size: 13px; color: #303133; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.bell-item-time { font-size: 11px; color: #909399; margin-top: 2px; }
.bell-empty { text-align: center; color: #909399; padding: 24px 0; font-size: 13px; }
.bell-empty i { font-size: 28px; }
.bell-empty p { margin: 8px 0 0; }
.bell-foot { text-align: center; padding-top: 8px; }
</style>
