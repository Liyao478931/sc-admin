<!--
  文件：admin/src/views/approval/Proxy.vue
  功能：审批代理设置（统一审批管理）— 当前代理状态卡片 / 搜索 / 列表 / 新增代理 / 取消 / 详情
  权限：approval:proxy:set
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>审批代理设置</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 当前代理状态卡片 -->
    <el-card class="proxy-status-card" shadow="hover">
      <div slot="header" class="card-header"><span>当前代理状态</span></div>
      <div v-loading="statusLoading">
        <!-- 无代理 -->
        <div v-if="!proxyStatus.has_proxy" class="status-content">
          <i class="el-icon-success status-icon success"></i>
          <span class="status-title">当前无代理</span>
          <span class="status-desc">您当前没有设置审批代理，所有审批任务将由您本人处理</span>
          <el-button v-permission="'approval:proxy:set'" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增代理</el-button>
        </div>
        <!-- 生效中 / 待生效 -->
        <div v-else class="status-content">
          <i class="el-icon-info status-icon" :class="proxyStatus.status === 'active' ? 'info' : 'warning'"></i>
          <span class="status-title">{{ proxyStatus.status_label }}</span>
          <span class="status-desc">{{ proxyStatus.status === 'active' ? '您的审批任务已自动转交给代理人处理，代理到期后将自动恢复' : '您已设置审批代理，将在开始时间后自动生效' }}</span>
          <el-descriptions :column="2" border size="small" class="proxy-desc">
            <el-descriptions-item label="代理人">{{ proxyStatus.proxy_user_name }}</el-descriptions-item>
            <el-descriptions-item :label="proxyStatus.status === 'active' ? '剩余天数' : '剩余等待天数'">{{ proxyStatus.remaining_days }} 天</el-descriptions-item>
            <el-descriptions-item label="代理开始时间">{{ proxyStatus.start_time }}</el-descriptions-item>
            <el-descriptions-item label="代理结束时间">{{ proxyStatus.end_time }}</el-descriptions-item>
            <el-descriptions-item label="代理原因" :span="2">{{ proxyStatus.reason || '-' }}</el-descriptions-item>
          </el-descriptions>
          <el-button v-permission="'approval:proxy:set'" type="danger" size="small" icon="el-icon-close" @click="handleCancelCurrent">取消代理</el-button>
        </div>
      </div>
    </el-card>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="代理人"><el-input v-model="query.proxy_user_name" placeholder="请输入代理人姓名" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="代理状态">
          <el-select v-model="query.status" clearable placeholder="全部状态" style="width:120px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="代理时间">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'approval:proxy:set'" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增代理</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条记录</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无代理记录">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="代理编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="openDetail(s.row)">{{ s.row.proxy_no }}</span></template>
      </el-table-column>
      <el-table-column prop="proxy_user_name" label="代理人" width="100" />
      <el-table-column prop="proxy_time_range" label="代理时间" width="230" />
      <el-table-column prop="reason" label="代理原因" min-width="160" show-overflow-tooltip />
      <el-table-column label="代理状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="statusTag(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="160" align="center" />
      <el-table-column label="操作" width="160" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 1" v-permission="'approval:proxy:set'" type="text" size="mini" class="danger-text" @click="handleCancel(s.row)">取消代理</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增代理对话框 -->
    <el-dialog title="设置审批代理" :visible.sync="dialogVisible" width="550px" :close-on-click-modal="false" append-to-body>
      <el-form ref="form" :model="form" :rules="formRules" label-width="120px" size="small">
        <el-form-item label="代理人" prop="proxy_user_id">
          <el-select v-model="form.proxy_user_id" filterable remote :remote-method="searchUsers" :loading="searching" placeholder="搜索并选择代理人" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="(u.real_name || u.username) + '（' + (u.username || '') + '）'" :value="u.id" :disabled="u.id === myUid" />
          </el-select>
        </el-form-item>
        <el-form-item label="代理开始时间" prop="start_time">
          <el-date-picker v-model="form.start_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="选择开始时间" style="width:100%" :picker-options="{ disabledDate: d => d.getTime() < Date.now() - 86400000 }" />
        </el-form-item>
        <el-form-item label="代理结束时间" prop="end_time">
          <el-date-picker v-model="form.end_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="选择结束时间" style="width:100%" :picker-options="{ disabledDate: d => d.getTime() < (this.form.start_time ? new Date(this.form.start_time).getTime() : Date.now()) }" />
        </el-form-item>
        <el-form-item label="代理原因" prop="reason">
          <el-input v-model="form.reason" type="textarea" :rows="3" maxlength="200" placeholder="请填写代理原因，如：出差、休假、培训等" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200" placeholder="请输入备注信息" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保 存</el-button>
      </div>
    </el-dialog>

    <!-- 代理详情对话框 -->
    <el-dialog title="代理详情" :visible.sync="detailVisible" width="500px" append-to-body>
      <el-descriptions :column="2" border size="small" v-if="detailRow">
        <el-descriptions-item label="代理编号">{{ detailRow.proxy_no }}</el-descriptions-item>
        <el-descriptions-item label="代理人">{{ detailRow.proxy_user_name }}</el-descriptions-item>
        <el-descriptions-item label="开始时间">{{ detailRow.start_time }}</el-descriptions-item>
        <el-descriptions-item label="结束时间">{{ detailRow.end_time }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ detailRow.status_label }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailRow.created_at }}</el-descriptions-item>
        <el-descriptions-item label="代理原因" :span="2">{{ detailRow.reason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detailRow.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
      <div slot="footer">
        <el-button size="small" @click="detailVisible = false">关 闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getProxyList, saveProxy, cancelProxy, getCurrentProxyStatus, getUserOptions } from '@/api/approval'
import { getToken } from '@/utils/auth'

const STATUS_TAG = { 0: 'warning', 1: 'success', 2: 'info', 3: 'info' }

export default {
  name: 'ApprovalProxy',
  data () {
    return {
      statusOptions: { 0: '待生效', 1: '生效中', 2: '已过期', 3: '已取消' },
      query: { proxy_user_name: '', status: '', dateRange: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      proxyStatus: { has_proxy: false, status: null }, statusLoading: false,
      dialogVisible: false, saving: false,
      form: { proxy_user_id: null, start_time: '', end_time: '', reason: '', remark: '' },
      formRules: {
        proxy_user_id: [{ required: true, message: '请选择代理人', trigger: 'change' }],
        start_time: [{ required: true, message: '请选择代理开始时间', trigger: 'change' }],
        end_time: [{ required: true, message: '请选择代理结束时间', trigger: 'change' }],
        reason: [{ required: true, message: '请填写代理原因', trigger: 'blur' }]
      },
      userOptions: [], searching: false,
      detailVisible: false, detailRow: null,
      myUid: null
    }
  },
  created () {
    this.myUid = this.resolveUid()
    this.loadAll()
    this.loadUsers('')
  },
  methods: {
    resolveUid () {
      try {
        const u = JSON.parse(localStorage.getItem('userInfo') || 'null')
        return u ? u.id : null
      } catch (e) { return null }
    },
    statusTag (s) { return STATUS_TAG[Number(s)] || 'info' },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.proxy_user_name) p.proxy_user_name = this.query.proxy_user_name
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getProxyList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async loadStatus () {
      this.statusLoading = true
      try {
        const r = await getCurrentProxyStatus()
        if (r.code === 0 && r.data) this.proxyStatus = r.data
      } catch (e) {} finally { this.statusLoading = false }
    },
    loadAll () { this.loadList(); this.loadStatus() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () { this.query = { proxy_user_name: '', status: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadList() },
    openAdd () {
      this.form = { proxy_user_id: null, start_time: '', end_time: '', reason: '', remark: '' }
      this.dialogVisible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    async loadUsers (kw) {
      this.searching = true
      try {
        const r = await getUserOptions({ page: 1, pageSize: 100, keyword: kw || undefined })
        if (r.code === 0) {
          this.userOptions = Array.isArray(r.data) ? r.data : (r.data.list || [])
        }
      } catch (e) {} finally { this.searching = false }
    },
    searchUsers (kw) { this.loadUsers(kw) },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) return
        if (this.form.proxy_user_id === this.myUid) { this.$message.error('不能选择自己作为代理人'); return }
        if (!this.form.start_time || !this.form.end_time) { this.$message.error('请选择代理起止时间'); return }
        if (new Date(this.form.start_time).getTime() < Date.now()) { this.$message.error('代理开始时间不能早于当前时间'); return }
        if (new Date(this.form.end_time).getTime() <= new Date(this.form.start_time).getTime()) { this.$message.error('代理结束时间不能早于开始时间'); return }
        if ((new Date(this.form.end_time).getTime() - new Date(this.form.start_time).getTime()) > 180 * 86400000) { this.$message.error('代理时间不能超过 180 天'); return }
        this.saving = true
        saveProxy(this.form).then(r => {
          if (r.code === 0) { this.$message.success('代理设置成功'); this.dialogVisible = false; this.loadAll() } else this.$message.error(r.msg || '设置失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleCancel (row) {
      this.$confirm('确认取消该代理设置吗？取消后您的审批任务将不再自动转交给代理人', '取消代理', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelProxy(row.id)
          if (r.code === 0) { this.$message.success('代理已取消'); this.loadAll() } else this.$message.error(r.msg || '取消失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCancelCurrent () {
      if (!this.proxyStatus.id) return
      this.$confirm('确认取消当前代理设置吗？取消后您的审批任务将不再自动转交给代理人', '取消代理', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelProxy(this.proxyStatus.id)
          if (r.code === 0) { this.$message.success('代理已取消'); this.loadAll() } else this.$message.error(r.msg || '取消失败')
        } catch (e) {}
      }).catch(() => {})
    },
    openDetail (row) { this.detailRow = row; this.detailVisible = true }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.proxy-status-card { margin-bottom: 14px; }
.card-header { font-weight: 600; }
.status-content { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 10px 0; }
.status-icon { font-size: 40px; }
.status-icon.success { color: #67C23A; }
.status-icon.info { color: #409EFF; }
.status-icon.warning { color: #E6A23C; }
.status-title { font-size: 17px; font-weight: 600; color: #303133; }
.status-desc { color: #909399; font-size: 13px; }
.proxy-desc { width: 100%; margin: 6px 0 10px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
