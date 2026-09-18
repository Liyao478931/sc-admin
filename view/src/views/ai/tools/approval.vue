<template>
  <div class="ai-tool-approval-page">
    <el-tabs v-model="activeTab" type="border-card">
      <!-- ==================== Tab1 待审批 ==================== -->
      <el-tab-pane label="待审批" name="pending">
        <!-- 统计卡片 -->
        <el-row :gutter="14" class="stat-row">
          <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num warning">{{ pendingStats.pending || 0 }}</div><div class="stat-label">待审批</div></el-card></el-col>
          <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num primary">{{ pendingStats.processing || 0 }}</div><div class="stat-label">审批中</div></el-card></el-col>
          <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ pendingStats.month_count || 0 }}</div><div class="stat-label">本月审批</div></el-card></el-col>
        </el-row>

        <div class="filter-bar">
          <el-input v-model="pendingFilter.keyword" placeholder="审批编号/工具/申请人搜索" size="small" clearable style="width: 200px;" @keyup.enter.native="p => { pendingPage = 1; loadPending() }" @clear="p => { pendingPage = 1; loadPending() }" />
          <el-select v-model="pendingFilter.action_type" placeholder="操作类型" clearable size="small" style="width: 120px; margin-left: 10px;" @change="p => { pendingPage = 1; loadPending() }">
            <el-option v-for="opt in actionOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <el-date-picker v-model="pendingDateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" size="small" style="margin-left: 10px;" @change="p => { pendingPage = 1; loadPending() }" />
          <span class="flex-1"></span>
          <el-button v-if="selectedRows.length" size="small" type="success" @click="batchProcess('approve')">批量通过</el-button>
          <el-button v-if="selectedRows.length" size="small" type="danger" @click="batchProcess('reject')">批量驳回</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadPending">刷新</el-button>
        </div>

        <el-table :data="pendingList" size="small" stripe v-loading="pendingLoading" @selection-change="s => selectedRows = s" :row-class-name="rowClass">
          <el-table-column type="selection" width="45" />
          <el-table-column prop="approval_id" label="审批编号" width="140" show-overflow-tooltip />
          <el-table-column prop="tool_name" label="工具名称" min-width="130" show-overflow-tooltip />
          <el-table-column label="操作类型" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="actionType(s.row.action_type)">{{ s.row.action_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="applicant_name" label="申请人" width="100" />
          <el-table-column prop="apply_time" label="申请时间" width="165" />
          <el-table-column label="状态" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="statusType(s.row.approval_status)">{{ s.row.status_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="160" align="center">
            <template slot-scope="s">
              <el-button v-if="s.row.approval_status === 'pending'" type="text" size="mini" @click="$refs.processDialog.open(s.row)">处理</el-button>
              <el-button type="text" size="mini" @click="$refs.detailDialog.open(s.row.id)">查看详情</el-button>
              <el-button v-if="s.row.approval_status === 'pending'" type="text" size="mini" class="danger" @click="cancelApproval(s.row)">取消</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="pendingTotal" :page-size="pendingPageSize" :current-page="pendingPage" @current-change="p => { pendingPage = p; loadPending() }" />
      </el-tab-pane>

      <!-- ==================== Tab2 全部审批 ==================== -->
      <el-tab-pane label="全部审批" name="all">
        <div class="filter-bar">
          <el-input v-model="allFilter.keyword" placeholder="审批编号/工具/申请人搜索" size="small" clearable style="width: 200px;" @keyup.enter.native="p => { allPage = 1; loadAll() }" @clear="p => { allPage = 1; loadAll() }" />
          <el-select v-model="allFilter.status" placeholder="审批状态" clearable size="small" style="width: 120px; margin-left: 10px;" @change="p => { allPage = 1; loadAll() }">
            <el-option v-for="(v, k) in statusMap" :key="k" :label="v" :value="k" />
          </el-select>
          <el-select v-model="allFilter.action_type" placeholder="操作类型" clearable size="small" style="width: 120px; margin-left: 10px;" @change="p => { allPage = 1; loadAll() }">
            <el-option v-for="opt in actionOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <el-date-picker v-model="allDateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" size="small" style="margin-left: 10px;" @change="p => { allPage = 1; loadAll() }" />
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>

        <el-table :data="allList" size="small" stripe v-loading="allLoading">
          <el-table-column prop="approval_id" label="审批编号" width="140" show-overflow-tooltip />
          <el-table-column prop="tool_name" label="工具名称" min-width="130" show-overflow-tooltip />
          <el-table-column label="操作类型" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="actionType(s.row.action_type)">{{ s.row.action_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="applicant_name" label="申请人" width="100" />
          <el-table-column prop="apply_time" label="申请时间" width="165" />
          <el-table-column label="状态" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="statusType(s.row.approval_status)">{{ s.row.status_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="approver_name" label="审批人" width="90">
            <template slot-scope="s">{{ s.row.approver_name || '--' }}</template>
          </el-table-column>
          <el-table-column prop="approval_time" label="审批时间" width="165">
            <template slot-scope="s">{{ s.row.approval_time || '--' }}</template>
          </el-table-column>
          <el-table-column label="操作" width="90" align="center">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="$refs.detailDialog.open(s.row.id)">查看详情</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="allTotal" :page-size="allPageSize" :current-page="allPage" @current-change="p => { allPage = p; loadAll() }" />
      </el-tab-pane>

      <!-- ==================== Tab3 审批配置 ==================== -->
      <el-tab-pane label="审批配置" name="config">
        <el-card shadow="never" class="config-card">
          <el-form :model="configForm" label-width="160px" size="small">
            <el-form-item label="启用工具审批">
              <el-switch v-model="configForm.approval_enabled" active-text="启用" inactive-text="停用" />
            </el-form-item>
            <el-form-item label="审批人">
              <el-select v-model="configForm.approver_ids" multiple filterable remote reserve-keyword placeholder="搜索并选择审批人" :remote-method="searchApprovers" :loading="userLoading" style="width: 100%;">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="免审批用户">
              <el-select v-model="configForm.exempt_user_ids" multiple filterable remote reserve-keyword placeholder="搜索并选择免审批用户" :remote-method="searchApprovers" :loading="userLoading" style="width: 100%;">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="免审批操作类型">
              <el-checkbox-group v-model="configForm.exempt_actions">
                <el-checkbox label="create">新增</el-checkbox>
                <el-checkbox label="update">修改</el-checkbox>
                <el-checkbox label="delete">删除</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="自动审批评分阈值">
              <el-input-number v-model="configForm.auto_approve_threshold" :min="0" :max="100" />
              <span class="unit">工具评分达到阈值自动通过</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="configSaving" @click="saveConfig">保存配置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 弹窗 -->
    <ProcessDialog ref="processDialog" @saved="reloadPending" />
    <ApprovalDetailDialog ref="detailDialog" />
  </div>
</template>

<script>
import {
  getToolApprovals, cancelToolApproval, getToolApprovalStatistics,
  batchProcessToolApproval, getApprovalConfig, saveApprovalConfig
} from '../../../api/aiToolApproval'
import { getUserList } from '../../../api/user'
import ProcessDialog from './components/ApprovalProcessDialog.vue'
import ApprovalDetailDialog from './components/ApprovalDetailDialog.vue'

export default {
  name: 'AiToolApproval',
  components: { ProcessDialog, ApprovalDetailDialog },
  data() {
    return {
      activeTab: 'pending',
      // 待审批
      pendingLoading: false, pendingList: [], pendingTotal: 0, pendingPage: 1, pendingPageSize: 20,
      pendingFilter: { keyword: '', action_type: '' }, pendingDateRange: [], selectedRows: [],
      pendingStats: {},
      // 全部
      allLoading: false, allList: [], allTotal: 0, allPage: 1, allPageSize: 20,
      allFilter: { keyword: '', status: '', action_type: '' }, allDateRange: [],
      // 配置
      configForm: { approval_enabled: true, approver_ids: [], exempt_user_ids: [], exempt_actions: ['create'], auto_approve_threshold: 80 },
      configSaving: false, userLoading: false, userOptions: [],
      actionOptions: [],
      statusMap: { pending: '待审批', processing: '审批中', approved: '已通过', rejected: '已驳回' }
    }
  },
  created() {
    this.loadPending()
    this.loadAll()
    this.loadConfig()
    this.loadDicts()
  },
  methods: {
    // 操作类型从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('tool_approval_action'); this.actionOptions = r.data || [] } catch (e) { this.actionOptions = [] }
    },
    // ===== 待审批 =====
    async loadPending() {
      this.pendingLoading = true
      try {
        const params = { page: this.pendingPage, limit: this.pendingPageSize }
        if (this.pendingFilter.keyword) params.keyword = this.pendingFilter.keyword
        if (this.pendingFilter.action_type) params.action_type = this.pendingFilter.action_type
        if (this.pendingDateRange && this.pendingDateRange.length === 2) {
          params.start_date = this.pendingDateRange[0]
          params.end_date = this.pendingDateRange[1]
        }
        const res = await getToolApprovals(params)
        this.pendingList = res.data.list || []
        this.pendingTotal = res.data.total || 0
      } catch (e) {}
      this.pendingLoading = false
    },
    async reloadPending() {
      this.loadPending()
      this.loadAll()
      this.loadStats()
    },
    async loadStats() {
      try { this.pendingStats = (await getToolApprovalStatistics()).data || {} } catch (e) {}
    },
    rowClass({ row }) {
      return row.approval_status === 'pending' ? 'pending-row' : ''
    },
    async batchProcess(action) {
      const label = action === 'approve' ? '通过' : '驳回'
      this.$prompt(`请输入${label}意见（可选）`, `批量${label}`, {
        confirmButtonText: '确定', cancelButtonText: '取消', inputType: 'textarea'
      }).then(async ({ value }) => {
        try {
          const res = await batchProcessToolApproval({
            ids: this.selectedRows.map(r => r.id), action, comment: value || ''
          })
          this.$message.success(res.msg || '处理完成')
          this.selectedRows = []
          this.reloadPending()
        } catch (e) {}
      }).catch(() => {})
    },
    cancelApproval(row) {
      this.$confirm(`确定取消审批单 ${row.approval_id}？`, '提示', { type: 'warning' }).then(async () => {
        try { await cancelToolApproval(row.id); this.$message.success('已取消'); this.reloadPending() } catch (e) {}
      }).catch(() => {})
    },
    // ===== 全部 =====
    async loadAll() {
      this.allLoading = true
      try {
        const params = { page: this.allPage, limit: this.allPageSize }
        if (this.allFilter.keyword) params.keyword = this.allFilter.keyword
        if (this.allFilter.status) params.status = this.allFilter.status
        if (this.allFilter.action_type) params.action_type = this.allFilter.action_type
        if (this.allDateRange && this.allDateRange.length === 2) {
          params.start_date = this.allDateRange[0]
          params.end_date = this.allDateRange[1]
        }
        const res = await getToolApprovals(params)
        this.allList = res.data.list || []
        this.allTotal = res.data.total || 0
      } catch (e) {}
      this.allLoading = false
    },
    // ===== 配置 =====
    async loadConfig() {
      try {
        const res = await getApprovalConfig()
        const d = res.data || {}
        this.configForm = {
          approval_enabled: d.approval_enabled !== false,
          approver_ids: (d.approver_ids || []).map(Number),
          exempt_user_ids: (d.exempt_user_ids || []).map(Number),
          exempt_actions: d.exempt_actions || ['create'],
          auto_approve_threshold: Number(d.auto_approve_threshold) || 80
        }
      } catch (e) {}
    },
    async saveConfig() {
      this.configSaving = true
      try {
        const res = await saveApprovalConfig(this.configForm)
        this.$message.success(res.msg || '配置已更新')
      } catch (e) {}
      this.configSaving = false
    },
    async searchApprovers(kw) {
      this.userLoading = true
      try {
        const res = await getUserList({ page: 1, limit: 50, keyword: kw || '' })
        this.userOptions = (res.data && res.data.list) || []
      } catch (e) {}
      this.userLoading = false
    },
    // ===== 辅助 =====
    actionType(t) { return { create: 'success', update: 'warning', delete: 'danger' }[t] || 'info' },
    statusType(st) { return { pending: 'warning', processing: 'primary', approved: 'success', rejected: 'danger' }[st] || 'info' }
  }
}
</script>

<style scoped>
.ai-tool-approval-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 26px; font-weight: 700; }
.stat-num.warning { color: #e6a23c; }
.stat-num.primary { color: #409eff; }
.stat-label { color: #909399; font-size: 12px; margin-top: 2px; }
.filter-bar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
.unit { color: #909399; margin-left: 8px; font-size: 12px; }
.config-card { max-width: 720px; }
</style>
