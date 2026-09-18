<template>
  <div class="notification-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8">
        <div class="stat-card" @click="resetFilter">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-message"></i></div>
          <div class="stat-body">
            <div class="stat-value" style="color:#409EFF;">{{ stats.total }}</div>
            <div class="stat-label">总消息数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="stat-card clickable" @click="filterUnread">
          <div class="stat-icon" style="background:#F56C6C1a;color:#F56C6C;"><i class="el-icon-bell"></i></div>
          <div class="stat-body">
            <div class="stat-value" style="color:#F56C6C;">{{ stats.unread }}</div>
            <div class="stat-label">未读消息（点击筛选）</div>
          </div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="stat-card" @click="resetFilter">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-s-promotion"></i></div>
          <div class="stat-body">
            <div class="stat-value" style="color:#67C23A;">{{ stats.today }}</div>
            <div class="stat-label">今日新增</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item label="消息类型">
          <el-select v-model="filters.msg_type" clearable placeholder="全部" style="width:130px" @change="onFilterChange">
            <el-option v-for="(t, k) in TYPE_MAP" :key="k" :label="t.label" :value="Number(k)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.status" clearable placeholder="全部" style="width:110px" @change="onFilterChange">
            <el-option label="已读" value="1" />
            <el-option label="未读" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="filters.dateRange" type="daterange" value-format="yyyy-MM-dd"
            range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" @change="onFilterChange" />
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入消息标题或内容" clearable style="width:220px" @keyup.enter.native="onFilterChange" @clear="onFilterChange" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onFilterChange">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <div class="toolbar-left">
          <span>共 <b>{{ total }}</b> 条消息</span>
          <span v-if="selection.length" class="sel-tip">已选 <b style="color:#409EFF">{{ selection.length }}</b> 条</span>
        </div>
        <div class="toolbar-right">
          <el-button v-if="hasPerm('notification:send')" size="small" type="primary" icon="el-icon-s-promotion" @click="sendVisible = true">发送消息</el-button>
          <el-button size="small" :disabled="!selection.length" icon="el-icon-check" @click="batchRead">批量标记已读</el-button>
          <el-button size="small" type="danger" plain :disabled="!selection.length" icon="el-icon-delete" @click="batchDelete">批量删除</el-button>
          <el-button size="small" icon="el-icon-finished" @click="readAll">全部标记已读</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 消息列表 -->
      <el-table :data="list" v-loading="loading" size="small" stripe @selection-change="s => (selection = s)" @row-click="rowClick">
        <el-table-column type="selection" width="44" />
        <el-table-column label="类型" width="92">
          <template slot-scope="{ row }">
            <el-tag size="mini" :style="tagStyle(typeOf(row.msg_type))">{{ typeOf(row.msg_type).label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="消息标题" min-width="220" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <span class="title-cell" :class="{ unread: row.status === 0 }" @click.stop="openDetail(row)">
              <i v-if="row.status === 0" class="dot"></i>{{ row.title }}
            </span>
          </template>
        </el-table-column>
        <el-table-column label="发送人" width="110">
          <template slot-scope="{ row }">{{ row.from_user_name || '系统' }}</template>
        </el-table-column>
        <el-table-column label="发送时间" width="140">
          <template slot-scope="{ row }">{{ formatRelative(row.send_time) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="80">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 0 ? 'danger' : 'info'">{{ row.status === 0 ? '未读' : '已读' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click.stop="openDetail(row)">详情</el-button>
            <el-button v-if="row.status === 0" type="text" size="mini" @click.stop="markRead(row)">标为已读</el-button>
            <el-button v-else type="text" size="mini" @click.stop="markUnread(row)">标为未读</el-button>
            <el-button type="text" size="mini" style="color:#F56C6C" @click.stop="removeOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 消息详情弹窗 -->
    <el-dialog title="消息详情" :visible.sync="detailVisible" width="640px" top="8vh" @closed="detail = {}">
      <div v-if="detail.id" class="detail-wrap">
        <div class="detail-head">
          <h3>{{ detail.title }}</h3>
          <div class="detail-meta">
            <el-tag size="mini" :style="tagStyle(typeOf(detail.msg_type))">{{ typeOf(detail.msg_type).label }}</el-tag>
            <span>发送人：{{ detail.from_user_name || '系统' }}</span>
            <span>时间：{{ detail.send_time }}</span>
          </div>
        </div>
        <!-- 消息内容（支持富文本） -->
        <div class="detail-content" v-html="detail.content"></div>
        <!-- 附件列表 -->
        <div v-if="detail.attachments && detail.attachments.length" class="detail-attach">
          <div class="attach-title"><i class="el-icon-paperclip"></i> 附件</div>
          <div v-for="(f, i) in detail.attachments" :key="i" class="attach-item">
            <i class="el-icon-document"></i>
            <a :href="f.url" target="_blank" rel="noopener">{{ f.name || f.url }}</a>
          </div>
        </div>
        <!-- 跳转链接 -->
        <div v-if="detail.link_url" class="detail-link">
          <el-button type="primary" size="small" icon="el-icon-right" @click="goLink(detail.link_url)">{{ detail.link_text || '查看详情' }}</el-button>
        </div>
      </div>
      <span slot="footer">
        <el-button size="small" @click="detailVisible = false">关闭</el-button>
        <el-button v-if="detail.status === 0" size="small" type="primary" @click="markRead(detail, true)">标记已读</el-button>
        <el-button v-else size="small" type="primary" plain @click="markUnread(detail, true)">标记未读</el-button>
        <el-button size="small" type="danger" plain @click="removeOne(detail, true)">删除</el-button>
      </span>
    </el-dialog>

    <!-- 发送消息弹窗 -->
    <notification-send-dialog v-if="sendVisible" :visible.sync="sendVisible" @sent="loadAll" />
  </div>
</template>

<script>
import {
  getNotificationList, getNotificationStatistics, getNotificationDetail,
  readNotification, unreadNotification, readNotificationsBatch, readAllNotifications,
  deleteNotification, deleteNotificationsBatch
} from '@/api/notification'
import NotificationSendDialog from './components/NotificationSendDialog.vue'

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
  name: 'NotificationMessages',
  components: { NotificationSendDialog },
  data () {
    return {
      TYPE_MAP,
      list: [],
      total: 0,
      page: 1,
      limit: 10,
      loading: false,
      selection: [],
      stats: { total: 0, unread: 0, today: 0 },
      filters: { msg_type: '', status: '', dateRange: null, keyword: '' },
      detailVisible: false,
      detail: {},
      sendVisible: false
    }
  },
  created () {
    this.loadAll()
    // 支持从顶部铃铛跳转直接打开详情
    const qid = this.$route.query.id
    if (qid) this.openDetail({ id: Number(qid), status: 0 })
  },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    typeOf (type) { return TYPE_MAP[type] || { label: '未知', color: '#909399' } },
    tagStyle (t) { return { color: t.color, borderColor: t.color, background: t.color + '1a' } },
    // 相对时间
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
    // 加载统计 + 列表
    async loadAll () {
      this.loading = true
      try {
        await Promise.all([this.loadStats(), this.loadList()])
      } catch (e) {
        this.$message.error('消息加载失败')
      } finally {
        this.loading = false
      }
    },
    async loadStats () {
      const r = await getNotificationStatistics()
      if (r.code === 0) this.stats = r.data || { total: 0, unread: 0, today: 0 }
    },
    async loadList () {
      const params = { page: this.page, limit: this.limit }
      if (this.filters.msg_type) params.msg_type = this.filters.msg_type
      if (this.filters.status !== '' && this.filters.status !== null) params.status = this.filters.status
      if (this.filters.dateRange && this.filters.dateRange.length === 2) {
        params.start_date = this.filters.dateRange[0]
        params.end_date = this.filters.dateRange[1]
      }
      if (this.filters.keyword) params.keyword = this.filters.keyword
      const r = await getNotificationList(params)
      if (r.code === 0) {
        this.list = r.data.list || []
        this.total = r.data.total || 0
      }
    },
    onFilterChange () { this.page = 1; this.loadAll() },
    resetFilter () {
      this.filters = { msg_type: '', status: '', dateRange: null, keyword: '' }
      this.page = 1
      this.loadAll()
    },
    filterUnread () {
      this.filters.status = '0'
      this.page = 1
      this.loadAll()
    },
    // 详情（后端自动标记已读）
    async openDetail (row) {
      try {
        const r = await getNotificationDetail(row.id)
        if (r.code === 0) {
          this.detail = r.data || {}
          this.detailVisible = true
          // 若原未读，刷新列表与统计
          if (row.status === 0) this.loadAll()
        }
      } catch (e) {}
    },
    rowClick (row) { this.openDetail(row) },
    // 标记已读
    async markRead (row, fromDialog) {
      try {
        const r = await readNotification(row.id)
        if (r.code === 0) {
          this.$message.success('已标记为已读')
          if (fromDialog) { this.detail.status = 1; this.detail.read_at = new Date().toLocaleString() }
          this.loadAll()
        }
      } catch (e) {}
    },
    // 标记未读
    async markUnread (row, fromDialog) {
      try {
        const r = await unreadNotification(row.id)
        if (r.code === 0) {
          this.$message.success('已标记为未读')
          if (fromDialog) { this.detail.status = 0; this.detail.read_at = null }
          this.loadAll()
        }
      } catch (e) {}
    },
    // 批量标记已读
    async batchRead () {
      if (!this.selection.length) return
      try {
        const r = await readNotificationsBatch(this.selection.map(s => s.id))
        if (r.code === 0) { this.$message.success('批量标记成功'); this.loadAll() }
      } catch (e) {}
    },
    // 批量删除
    batchDelete () {
      if (!this.selection.length) return
      this.$confirm(`确定删除选中的 ${this.selection.length} 条消息？删除后不可恢复。`, '批量删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteNotificationsBatch(this.selection.map(s => s.id))
          if (r.code === 0) { this.$message.success('批量删除成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    // 全部标记已读
    async readAll () {
      try {
        const r = await readAllNotifications()
        if (r.code === 0) { this.$message.success('已全部标记为已读'); this.loadAll() }
      } catch (e) {}
    },
    // 删除单条
    removeOne (row, fromDialog) {
      this.$confirm(`确定删除消息「${row.title}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteNotification(row.id)
          if (r.code === 0) {
            this.$message.success('删除成功')
            if (fromDialog) this.detailVisible = false
            this.loadAll()
          }
        } catch (e) {}
      }).catch(() => {})
    },
    // 跳转业务链接
    goLink (url) {
      if (!url) return
      if (/^https?:\/\//.test(url)) { window.open(url, '_blank'); return }
      // 兼容历史遗留的 /admin/#/ 前缀链接：去前缀后按路由路径跳转
      if (url.indexOf('/admin/#/') === 0) { this.$router.push(url.replace(/^\/admin\/#\//, '/')); return }
      this.$router.push(url)
    }
  }
}
</script>

<style scoped>
.notification-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 16px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); cursor: pointer; }
.stat-icon { width: 48px; height: 48px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 24px; margin-right: 14px; }
.stat-value { font-size: 26px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-left { font-size: 13px; color: #606266; }
.sel-tip { margin-left: 12px; }
.title-cell { cursor: pointer; display: inline-flex; align-items: center; }
.title-cell.unread { font-weight: 700; color: #303133; }
.title-cell .dot { width: 8px; height: 8px; border-radius: 50%; background: #F56C6C; display: inline-block; margin-right: 6px; flex-shrink: 0; }
.pager { margin-top: 14px; text-align: right; }
.detail-head h3 { margin: 0 0 10px; font-size: 18px; color: #303133; }
.detail-meta { display: flex; align-items: center; gap: 14px; font-size: 12px; color: #909399; padding-bottom: 12px; border-bottom: 1px solid #EBEEF5; }
.detail-content { padding: 14px 0; font-size: 14px; line-height: 1.8; color: #333; word-break: break-all; }
.detail-attach { padding: 10px 0; border-top: 1px solid #EBEEF5; }
.attach-title { font-size: 13px; color: #909399; margin-bottom: 6px; }
.attach-item { font-size: 13px; padding: 4px 0; }
.attach-item a { color: #409EFF; text-decoration: none; margin-left: 4px; }
.detail-link { padding-top: 12px; border-top: 1px solid #EBEEF5; }
</style>
