<template>
  <!-- 系统更新页：检查 aa 平台发布的更新并一键更新 -->
  <div class="sys-update-page">
    <el-card shadow="never" v-loading="loading">
      <div slot="header" class="card-header">
        <span>系统更新</span>
        <el-button type="primary" size="small" icon="el-icon-refresh" :loading="checking" @click="handleCheck">检查更新</el-button>
      </div>

      <!-- 当前版本 -->
      <div class="version-row">
        <div class="current-version">
          <span class="label">当前版本</span>
          <span class="value">v{{ status.current_version || '0.0.0' }}</span>
        </div>
        <div v-if="status.has_update" class="new-version">
          <span class="label">发现新版本</span>
          <span class="value highlight">v{{ status.new_version }}</span>
          <el-tag v-if="status.force === 1" type="danger" size="small" class="force-tag">强制更新</el-tag>
        </div>
        <div v-else class="no-update">当前已是最新版本</div>
      </div>

      <!-- 更新详情 -->
      <el-card v-if="status.has_update" shadow="never" class="update-detail">
        <div class="update-title">{{ status.title || ('系统更新 v' + status.new_version) }}</div>
        <div class="update-meta">
          <span v-if="status.published_at">发布时间：{{ status.published_at }}</span>
          <span v-if="status.size">包大小：{{ formatSize(status.size) }}</span>
          <span v-if="status.checked_at">检查时间：{{ status.checked_at }}</span>
        </div>
        <div class="update-changelog">
          <div class="section-label">更新日志</div>
          <pre>{{ status.changelog || '（无更新日志）' }}</pre>
        </div>
        <el-button v-if="!applying" type="primary" icon="el-icon-download" :loading="applying" @click="handleApply">立即更新</el-button>
        <div v-else class="applying-tip">
          <i class="el-icon-loading" /> 正在更新（下载 → 校验 → 备份 → 覆盖 → 数据库迁移），请勿关闭页面...
        </div>
        <div class="backup-tip">更新前系统会自动备份当前代码与数据库结构，更新失败将自动回滚。</div>
      </el-card>
    </el-card>

    <!-- 更新历史 -->
    <el-card shadow="never" class="history-card">
      <div slot="header" class="card-header">更新历史</div>
      <el-table :data="history" size="small" empty-text="暂无更新记录">
        <el-table-column prop="version_no" label="版本" width="110">
          <template slot-scope="{ row }"><el-tag type="primary" size="mini">v{{ row.version_no }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="140" show-overflow-tooltip />
        <el-table-column prop="changelog" label="更新内容" min-width="220" show-overflow-tooltip />
        <el-table-column label="状态" width="90">
          <template slot-scope="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : row.status === 2 ? 'danger' : 'info'" size="mini">{{ statusText(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="applied_at" label="更新时间" width="160" />
        <el-table-column label="操作" width="130" fixed="right">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="showHistoryDetail(row)">详情</el-button>
            <el-button v-if="row.status === 1" type="text" size="mini" class="rollback-btn" @click="handleRollback(row)">回滚</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 更新历史详情弹窗 -->
    <el-dialog title="更新详情" :visible.sync="historyVisible" width="560px">
      <el-descriptions v-if="historyDetail" :column="1" border>
        <el-descriptions-item label="版本号">v{{ historyDetail.version_no }}</el-descriptions-item>
        <el-descriptions-item label="标题">{{ historyDetail.title || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ historyDetail.applied_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新内容">
          <pre class="changelog-pre">{{ historyDetail.changelog || '（无更新内容说明）' }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="备注">{{ historyDetail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script>
// 系统更新：检查 aa 平台更新 / 一键更新 / 更新历史
import request from '@/api/request'

export default {
  name: 'SystemUpdate',
  data() {
    return {
      loading: false,
      checking: false,
      applying: false,
      status: {},
      history: [],
      historyVisible: false,
      historyDetail: null,
    }
  },
  created() {
    this.loadStatus()
    this.loadHistory()
  },
  methods: {
    async loadStatus() {
      this.loading = true
      try {
        const r = await request({ url: '/system/update/status', method: 'get' })
        if (r.code === 0) this.status = r.data || {}
        else this.$message.error(r.msg || '获取失败')
      } finally {
        this.loading = false
      }
    },
    async loadHistory() {
      try {
        const r = await request({ url: '/system/update/history', method: 'get' })
        if (r.code === 0) this.history = r.data.list || []
      } catch (e) {}
    },
    async handleCheck() {
      this.checking = true
      try {
        const r = await request({ url: '/system/update/refresh', method: 'post' })
        if (r.code === 0) {
          this.status = r.data || {}
          if (this.status.has_update) {
            const content = (this.status.changelog || this.status.title || '系统有新版本，请执行更新。').slice(0, 300)
            this.$alert('发现新版本 v' + this.status.new_version + '\n\n' + content, '系统更新', {
              confirmButtonText: '立即更新', cancelButtonText: '稍后', type: 'warning', center: true
            }).then(() => this.handleApply()).catch(() => {})
          } else {
            this.$message({ message: '当前已是最新版本 v' + (this.status.current_version || ''), type: 'success', duration: 1500 })
          }
        } else {
          this.$message.error(r.msg || '检查失败')
        }
      } catch (e) {
        this.$message.error('检查失败，请确认服务器可访问 aa 平台')
      } finally {
        this.checking = false
      }
    },
    handleApply() {
      this.$prompt('系统将下载并安装新版本 v' + (this.status.new_version || '') + '，更新前会自动备份，更新过程中请勿中断。请输入当前登录密码确认：', '确认更新（敏感操作）', {
        confirmButtonText: '立即更新',
        cancelButtonText: '取消',
        inputType: 'password',
        inputPlaceholder: '请输入当前登录密码',
        inputValidator: v => { if (!v) return '请输入登录密码'; return true },
        type: 'warning',
      }).then(({ value }) => {
        this.doApply(value)
      }).catch(() => {})
    },
    async doApply(password) {
      this.applying = true
      try {
        const r = await request({ url: '/system/update/apply', method: 'post', data: { password }, timeout: 900000 })
        if (r.code === 0) {
          this.$alert('更新成功，系统已升级到 v' + (this.status.new_version || '') + '。建议清理浏览器缓存后刷新页面。', '更新完成', { confirmButtonText: '知道了', type: 'success' }).then(() => window.location.reload())
        } else {
          this.$message.error(r.msg || '更新失败')
        }
      } catch (e) {
        this.$message.error('更新失败：' + (e.message || '请查看服务器日志'))
      } finally {
        this.applying = false
        this.loadStatus()
        this.loadHistory()
      }
    },
    formatSize(bytes) {
      if (!bytes) return '-'
      if (bytes > 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB'
      if (bytes > 1024) return (bytes / 1024).toFixed(1) + ' KB'
      return bytes + ' B'
    },
    statusText(s) {
      return { 0: '待更新', 1: '已更新', 2: '失败', 3: '已回滚' }[s] || '未知'
    },
    showHistoryDetail(row) {
      this.historyDetail = row
      this.historyVisible = true
    },
    // 回滚到历史版本（敏感操作：需登录密码）
    handleRollback(row) {
      this.$prompt('将回滚到 v' + row.version_no + '（从更新前备份恢复代码），回滚为敏感操作，请输入当前登录密码确认：', '回滚确认（敏感操作）', {
        confirmButtonText: '确认回滚',
        cancelButtonText: '取消',
        inputType: 'password',
        inputPlaceholder: '请输入当前登录密码',
        inputValidator: v => { if (!v) return '请输入登录密码'; return true },
        type: 'warning',
      }).then(({ value }) => this.doRollback(row, value)).catch(() => {})
    },
    async doRollback(row, password) {
      this.$message({ message: '正在回滚，请勿关闭页面...', type: 'warning', duration: 0 })
      try {
        const r = await request({ url: '/system/update/rollback', method: 'post', data: { version_no: row.version_no, password }, timeout: 600000 })
        if (r.code === 0) {
          this.$alert('已回滚至 v' + row.version_no + '，建议清理浏览器缓存后刷新页面。', '回滚完成', { confirmButtonText: '知道了', type: 'success' }).then(() => window.location.reload())
        } else {
          this.$message.error(r.msg || '回滚失败')
        }
      } catch (e) {
        this.$message.error('回滚失败：' + (e.message || '请查看服务器日志'))
      } finally {
        this.$message.closeAll()
        this.loadStatus()
        this.loadHistory()
      }
    },
  },
}
</script>

<style scoped>
.sys-update-page .card-header { display: flex; justify-content: space-between; align-items: center; }
.version-row { display: flex; align-items: center; gap: 32px; padding: 8px 0 4px; flex-wrap: wrap; }
.current-version .label, .new-version .label { color: #909399; margin-right: 8px; font-size: 13px; }
.current-version .value { font-size: 20px; font-weight: bold; }
.new-version .value.highlight { font-size: 20px; font-weight: bold; color: #409EFF; }
.force-tag { margin-left: 10px; }
.no-update { color: #67C23A; font-size: 14px; }
.update-detail { margin-top: 16px; border: 1px solid #EBEEF5; }
.update-title { font-size: 16px; font-weight: bold; margin-bottom: 8px; }
.update-meta { color: #909399; font-size: 12px; display: flex; gap: 20px; margin-bottom: 12px; flex-wrap: wrap; }
.update-changelog { background: #F8F9FB; border-radius: 6px; padding: 12px 16px; margin-bottom: 16px; }
.section-label { font-size: 13px; color: #606266; margin-bottom: 6px; }
.update-changelog pre { margin: 0; white-space: pre-wrap; word-break: break-word; color: #606266; font-size: 13px; line-height: 1.7; font-family: inherit; }
.applying-tip { color: #409EFF; font-size: 14px; }
.backup-tip { color: #909399; font-size: 12px; margin-top: 10px; }
.history-card { margin-top: 16px; }
.rollback-btn { color: #F56C6C; }
.changelog-pre { margin: 0; white-space: pre-wrap; word-break: break-word; font-family: inherit; color: #606266; font-size: 13px; line-height: 1.7; }
</style>
