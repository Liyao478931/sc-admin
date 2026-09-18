<!--
  文件：admin/src/views/approval/MyTasks.vue
  功能：我的待办（统一审批管理）— 统计卡片 / 搜索筛选 / 列表 / 审批 / 转办 / 催办 / 批量 / 通知设置 / 审批详情
  权限：approval:task:view / approve / transfer / urge / batch
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>我的待办</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="'stat-' + card.key" @click="handleCardFilter(card.key)">
          <div class="stat-icon"><i :class="card.icon"></i></div>
          <div class="stat-body">
            <div class="stat-num" :class="'num-' + card.key">{{ stats[card.key] || 0 }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="业务类型">
          <el-select v-model="query.biz_type" clearable placeholder="全部类型" style="width:140px">
            <el-option v-for="b in bizTypes" :key="b.code" :label="b.name" :value="b.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="业务编号"><el-input v-model="query.business_no" placeholder="请输入业务编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="业务标题"><el-input v-model="query.business_title" placeholder="请输入业务标题" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="申请人"><el-input v-model="query.applicant_name" placeholder="请输入申请人姓名" clearable style="width:130px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="申请日期">
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
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
        <el-button v-permission="'approval:task:batch'" size="small" type="primary" icon="el-icon-check"
          :disabled="!batchEnabled" @click="openBatch">批量通过</el-button>
        <el-button v-permission="'approval:task:view'" size="small" icon="el-icon-bell" @click="openNotify">通知设置</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条待审批</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无待审批任务"
      @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="业务类型" width="130" align="center">
        <template slot-scope="s"><el-tag :type="bizTag(s.row.biz_type)" size="mini">{{ s.row.business_name }}</el-tag></template>
      </el-table-column>
      <el-table-column label="业务编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="jumpBiz(s.row)">{{ s.row.business_no }}</span></template>
      </el-table-column>
      <el-table-column prop="business_title" label="业务标题" min-width="160" show-overflow-tooltip />
      <el-table-column prop="applicant_name" label="申请人" width="90" />
      <el-table-column prop="current_node_name" label="当前节点" width="130" />
      <el-table-column label="代理" width="100" align="center">
        <template slot-scope="s">
          <el-tag v-if="s.row.is_proxy === 1" type="warning" size="mini">代理审批</el-tag>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="审批模式" width="100" align="center">
        <template slot-scope="s"><el-tag :type="modeTag(s.row.approval_mode)" size="mini">{{ s.row.approval_mode_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="submit_time" label="申请时间" width="160" align="center" />
      <el-table-column label="超时状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.timeout_status_tag" size="mini">{{ s.row.timeout_status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'approval:task:approve'" type="primary" size="mini" @click="openApprove(s.row)">审批</el-button>
          <el-button v-permission="'approval:task:transfer'" type="text" size="mini" @click="openTransfer(s.row)">转办</el-button>
          <el-button v-permission="'approval:task:urge'" type="text" size="mini" :disabled="urgeLocked[s.row.id]" @click="handleUrge(s.row)">催办</el-button>
          <el-button type="text" size="mini" @click="openDetail(s.row.id)">查看详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 审批对话框 -->
    <el-dialog :title="'审批 - ' + (approveRow && approveRow.business_name || '')" :visible.sync="approveVisible" width="650px" append-to-body>
      <el-descriptions :column="2" border size="small" v-if="approveRow">
        <el-descriptions-item label="业务类型">{{ approveRow.business_name }}</el-descriptions-item>
        <el-descriptions-item label="业务编号">{{ approveRow.business_no }}</el-descriptions-item>
        <el-descriptions-item label="业务标题" :span="2">{{ approveRow.business_title }}</el-descriptions-item>
        <el-descriptions-item label="申请人">{{ approveRow.applicant_name }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ approveRow.submit_time }}</el-descriptions-item>
        <el-descriptions-item label="当前节点">{{ approveRow.current_node_name }}</el-descriptions-item>
        <el-descriptions-item label="审批模式">{{ approveRow.approval_mode_label }}</el-descriptions-item>
        <el-descriptions-item label="紧急程度"><el-tag :type="urgentTag(approveRow.urgent)" size="mini">{{ approveRow.urgent_label }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="业务摘要" :span="2">{{ approveSummary }}</el-descriptions-item>
      </el-descriptions>
      <!-- 审批时查看业务详情与作业照片 -->
      <template v-if="approveDetail">
        <el-descriptions v-if="approveDetail.bizSummary && approveDetail.bizSummary.length" :column="2" border size="small" style="margin-top:12px">
          <el-descriptions-item v-for="(it, i) in approveDetail.bizSummary" :key="i" :label="it.label">{{ it.value }}</el-descriptions-item>
        </el-descriptions>
        <div v-if="approveDetail.bizPhotos && approveDetail.bizPhotos.length" class="approve-photos">
          <div class="photo-label">作业照片（{{ approveDetail.bizPhotos.length }} 张）：</div>
          <el-image
            v-for="(u, i) in approveDetail.bizPhotos"
            :key="i"
            :src="imgUrl(u)"
            fit="cover"
            class="photo-img"
            :preview-src-list="approveDetail.bizPhotos.map(imgUrl)"
            :initial-index="i"
          />
        </div>
      </template>
      <div class="approve-op" v-if="approveRow">
        <el-button type="success" size="small" icon="el-icon-check" :loading="approveSubmitting" @click="handleApprovePass">通过</el-button>
        <el-button type="danger" size="small" icon="el-icon-close" :loading="approveSubmitting" @click="handleApproveReject">驳回</el-button>
        <span v-if="approveRow.approval_mode === 2" class="countersign-tip">会签：{{ countersignText }}</span>
      </div>
      <el-input v-model="approveComment" type="textarea" :rows="4" maxlength="500" placeholder="请输入审批意见（驳回时必填）" />
      <div class="phrase-bar">
        <span class="phrase-label">常用语：</span>
        <el-dropdown trigger="click" @command="handlePhraseSelect">
          <el-button size="mini" icon="el-icon-edit-outline" plain>常用语<i class="el-icon-arrow-down el-icon--right" /></el-button>
          <el-dropdown-menu slot="dropdown">
            <el-dropdown-item v-for="p in phrases" :key="p.id" :command="p">{{ p.phrase_content || p.content }}{{ p.use_count ? '（使用' + p.use_count + '次）' : '' }}</el-dropdown-item>
            <el-dropdown-item v-if="!phrases.length" disabled>暂无常用语，请到常用语管理页面添加</el-dropdown-item>
          </el-dropdown-menu>
        </el-dropdown>
      </div>
      <div slot="footer">
        <el-button size="small" @click="approveVisible = false">取 消</el-button>
      </div>
    </el-dialog>

    <!-- 转办对话框 -->
    <el-dialog title="转办审批任务" :visible.sync="transferVisible" width="500px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="当前审批人">
          <el-input :value="transferInfo.currentApprover" disabled />
        </el-form-item>
        <el-form-item label="选择转办人" required>
          <el-select v-model="transferInfo.targetUserId" filterable placeholder="请选择转办人" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="转办原因">
          <el-input v-model="transferInfo.reason" type="textarea" :rows="3" maxlength="200" placeholder="选填" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="transferVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="transferSubmitting" @click="handleTransfer">确认转办</el-button>
      </div>
    </el-dialog>

    <!-- 批量审批对话框 -->
    <el-dialog title="批量审批" :visible.sync="batchVisible" width="550px" append-to-body>
      <el-table :data="selection" size="mini" border max-height="240">
        <el-table-column prop="business_no" label="业务编号" width="150" />
        <el-table-column prop="business_title" label="业务标题" min-width="160" show-overflow-tooltip />
        <el-table-column prop="applicant_name" label="申请人" width="80" />
      </el-table>
      <el-input v-model="batchComment" type="textarea" :rows="3" maxlength="500" placeholder="审批意见（选填）" style="margin-top:10px" />
      <div class="batch-stat">共选中 {{ selection.length }} 个审批任务</div>
      <div slot="footer">
        <el-button size="small" @click="batchVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="batchSubmitting" @click="handleBatchApprove">确认批量通过</el-button>
      </div>
    </el-dialog>

    <!-- 通知设置对话框 -->
    <el-dialog title="审批通知设置" :visible.sync="notifyVisible" width="600px" :close-on-click-modal="false" append-to-body>
      <el-form label-width="140px" size="small">
        <div class="notify-section">通知方式</div>
        <el-form-item label="站内信通知">
          <el-switch v-model="notifyForm.enable_site" :active-value="1" :inactive-value="0" disabled />
          <span class="tip-text">系统基础通知能力，不可关闭</span>
        </el-form-item>
        <el-form-item label="邮件通知">
          <el-switch v-model="notifyForm.enable_email" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item v-if="notifyForm.enable_email" label="邮箱地址" required>
          <el-input v-model="notifyForm.email_address" clearable placeholder="请输入接收通知的邮箱地址" />
        </el-form-item>
        <el-form-item label="短信通知">
          <el-switch v-model="notifyForm.enable_sms" :active-value="1" :inactive-value="0" :disabled="!notifyForm.sms_available" />
          <span v-if="!notifyForm.sms_available" class="tip-text">短信服务未配置，请联系管理员</span>
        </el-form-item>
        <el-form-item v-if="notifyForm.enable_sms" label="手机号码" required>
          <el-input v-model="notifyForm.mobile" clearable placeholder="请输入接收通知的手机号码" />
        </el-form-item>
        <div class="notify-section">通知场景</div>
        <el-form-item label="通知场景">
          <el-checkbox v-model="notifyForm.scene_todo" :true-label="1" :false-label="0">待办提醒</el-checkbox>
          <el-checkbox v-model="notifyForm.scene_urge" :true-label="1" :false-label="0">催办提醒</el-checkbox>
          <el-checkbox v-model="notifyForm.scene_approve" :true-label="1" :false-label="0">通过通知</el-checkbox>
          <el-checkbox v-model="notifyForm.scene_reject" :true-label="1" :false-label="0">驳回通知</el-checkbox>
          <el-checkbox v-model="notifyForm.scene_transfer" :true-label="1" :false-label="0">转办通知</el-checkbox>
          <el-checkbox v-model="notifyForm.scene_overdue" :true-label="1" :false-label="0">超时提醒</el-checkbox>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="notifyVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="notifySubmitting" @click="handleNotifySave">保 存</el-button>
      </div>
    </el-dialog>

    <!-- 审批详情抽屉 -->
    <el-drawer title="审批详情" :visible.sync="detailVisible" size="750px" append-to-body>
      <div v-loading="detailLoading" class="drawer-body">
        <template v-if="detailData">
          <div class="section-title">审批信息</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="实例编号">{{ detailData.instance.instance_no }}</el-descriptions-item>
            <el-descriptions-item label="业务类型">{{ detailData.instance.business_name }}</el-descriptions-item>
            <el-descriptions-item label="业务编号">{{ detailData.instance.business_no }}</el-descriptions-item>
            <el-descriptions-item label="业务标题">{{ detailData.instance.business_title }}</el-descriptions-item>
            <el-descriptions-item label="申请人">{{ detailData.instance.applicant_name }}</el-descriptions-item>
            <el-descriptions-item label="申请时间">{{ detailData.instance.submit_time }}</el-descriptions-item>
            <el-descriptions-item label="审批状态">{{ detailData.instance.status_label }}</el-descriptions-item>
            <el-descriptions-item label="当前节点">{{ detailData.instance.current_node_name }}</el-descriptions-item>
            <el-descriptions-item label="审批模式">{{ detailData.instance.approval_mode_label }}</el-descriptions-item>
            <el-descriptions-item label="紧急程度">{{ detailData.instance.urgent_label }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">业务摘要</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item v-for="(it, i) in detailData.bizSummary" :key="i" :label="it.label">{{ it.value }}</el-descriptions-item>
          </el-descriptions>

          <div v-if="detailData.bizPhotos && detailData.bizPhotos.length" class="section-title">作业照片<span class="flow-progress">共 {{ detailData.bizPhotos.length }} 张</span></div>
          <div v-if="detailData.bizPhotos && detailData.bizPhotos.length" class="photo-grid">
            <el-image
              v-for="(u, i) in detailData.bizPhotos"
              :key="i"
              :src="imgUrl(u)"
              fit="cover"
              class="photo-img"
              :preview-src-list="detailData.bizPhotos.map(imgUrl)"
              :initial-index="i"
            />
          </div>

          <div class="section-title">审批流程图<span class="flow-progress">当前进度：{{ flowDone }}/{{ flowTotal }} 节点</span></div>
          <el-steps :active="flowDone" align-center class="flow-steps" finish-status="success">
            <el-step v-for="n in detailData.nodes" :key="n.id" :title="n.node_name" :description="n.approver_name || ''" />
          </el-steps>

          <div class="section-title">审批时间轴</div>
          <el-timeline>
            <el-timeline-item v-for="h in detailData.histories" :key="h.id" :timestamp="h.created_at" placement="top">
              <div class="tl-card">
                <div class="tl-head">
                  <el-tag :type="historyTag(h)" size="mini">{{ h.action_label }}</el-tag>
                  <span class="tl-operator">{{ h.operator_name }}</span>
                  <span class="tl-result">{{ historyResult(h) }}</span>
                  <span class="tl-notify">{{ h.notify_status === 1 ? '通知已发送' : '未发送通知' }}</span>
                </div>
                <div v-if="h.comment" class="tl-comment">{{ h.comment }}</div>
              </div>
            </el-timeline-item>
          </el-timeline>
        </template>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import {
  getMyTasks, getApprovalDetail, approveTask, rejectTask, transferTask,
  urgeTask, urgeCheckTask, batchApproveTasks, getNotifyConfig, saveNotifyConfig,
  getCommonPhrases, getUserOptions, incrementPhraseUsage
} from '@/api/approval'

const BIZ_TAG = {
  purchase_request: 'primary',
  report: 'warning',
  leave: 'success',
  hazard: 'danger',
  purchase_order: '',
  contract: 'info'
}
const MODE_TAG = { 1: 'info', 2: 'warning', 3: 'primary', 4: 'warning' }
const URGENT_TAG = { 0: 'info', 1: 'warning', 2: 'danger' }

export default {
  name: 'ApprovalMyTasks',
  data () {
    return {
      statCards: [
        { key: 'pending', label: '待审批', icon: 'el-icon-time' },
        { key: 'today', label: '今日待审', icon: 'el-icon-today' },
        { key: 'timeout', label: '已超时', icon: 'el-icon-warning' },
        { key: 'mine', label: '我发起的', icon: 'el-icon-document' }
      ],
      stats: { pending: 0, today: 0, timeout: 0, mine: 0 },
      cardStatus: '',
      query: { biz_type: '', business_no: '', business_title: '', applicant_name: '', dateRange: [] },
      bizTypes: [],
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      selection: [],
      urgeLocked: {},
      // 审批
      approveVisible: false, approveRow: null, approveComment: '', approveSubmitting: false,
      approveDetail: null, phrases: [], selectedPhraseId: null,
      // 转办
      transferVisible: false, transferInfo: { row: null, currentApprover: '', targetUserId: null, reason: '' },
      transferSubmitting: false, userOptions: [],
      // 批量
      batchVisible: false, batchComment: '', batchSubmitting: false,
      // 通知设置
      notifyVisible: false, notifyForm: { enable_site: 1, enable_email: 0, enable_sms: 0, email_address: '', mobile: '', sms_available: true, scene_todo: 1, scene_urge: 1, scene_approve: 1, scene_reject: 1, scene_transfer: 1, scene_overdue: 1 },
      notifySubmitting: false,
      // 详情
      detailVisible: false, detailLoading: false, detailData: null
    }
  },
  computed: {
    batchEnabled () {
      if (!this.selection.length) return false
      return this.selection.every(s => Number(s.approval_mode) === 1)
    },
    approveSummary () {
      return this.approveRow ? (this.approveRow.business_title || '') : ''
    },
    countersignText () {
      if (!this.approveDetail || !this.approveRow) return '0/0'
      const cur = (this.approveDetail.nodes || []).filter(n => n.node_index === this.approveRow.current_node_index)
      const pass = cur.filter(n => n.status === 1).length
      return `${pass}/${cur.length}`
    },
    flowDone () {
      return this.detailData ? (this.detailData.nodes || []).filter(n => n.status === 1).length : 0
    },
    flowTotal () {
      return this.detailData ? (this.detailData.nodes || []).length : 0
    }
  },
  created () { this.loadData() },
  methods: {
    bizTag (t) { return BIZ_TAG[t] || 'info' },
    imgUrl (v) {
      if (!v) return ''
      if (/^https?:\/\//.test(v) || v.startsWith('data:')) return v
      if (v.startsWith('/')) return window.location.origin + v
      return v
    },
    modeTag (m) { return MODE_TAG[m] || 'info' },
    urgentTag (u) { return URGENT_TAG[u] || 'info' },
    historyTag (h) {
      if (h.result === 'pass') return 'success'
      if (h.result === 'reject') return 'danger'
      return 'info'
    },
    historyResult (h) {
      const map = { pass: '通过', reject: '驳回', transfer: '转办', urge: '催办' }
      return map[h.result] || h.result || ''
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.biz_type) p.biz_type = this.query.biz_type
      if (this.query.business_no) p.business_no = this.query.business_no
      if (this.query.business_title) p.business_title = this.query.business_title
      if (this.query.applicant_name) p.applicant_name = this.query.applicant_name
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      if (this.cardStatus) p.status = this.cardStatus
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getMyTasks(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || { pending: 0, today: 0, timeout: 0, mine: 0 }
          if (r.data.bizTypes) this.bizTypes = r.data.bizTypes
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.cardStatus = ''; this.page = 1; this.loadData() },
    handleReset () {
      this.query = { biz_type: '', business_no: '', business_title: '', applicant_name: '', dateRange: [] }
      this.cardStatus = ''
      this.page = 1
      this.loadData()
    },
    handleCardFilter (key) {
      this.cardStatus = this.cardStatus === key ? '' : key
      this.page = 1
      this.loadData()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleSelectionChange (rows) { this.selection = rows },
    // ---- 业务编号跳转 ----
    jumpBiz (row) {
      if (Number(row.biz_id) > 0) {
        this.$message.info('业务单据详情跳转地址按实际模块路由配置')
      } else {
        this.$message.info('示例数据暂未关联业务单据')
      }
    },
    // ---- 审批 ----
    openApprove (row) {
      this.approveRow = row
      this.approveComment = ''
      this.approveDetail = null
      this.selectedPhraseId = null
      this.approveVisible = true
      this.loadPhrases()
      // 加载业务摘要与作业照片（审批时查看）
      getApprovalDetail(row.id).then(r => {
        if (r.code === 0) this.approveDetail = r.data
      }).catch(() => {})
    },
    handlePhraseSelect (p) {
      this.approveComment = p.phrase_content || p.content
      this.selectedPhraseId = p.id
    },
    afterApproveSuccess () {
      if (this.selectedPhraseId) {
        incrementPhraseUsage(this.selectedPhraseId).catch(() => {})
        this.selectedPhraseId = null
      }
    },
    async loadPhrases () {
      try {
        const r = await getCommonPhrases()
        if (r.code === 0) this.phrases = (r.data && r.data.list) || []
      } catch (e) {}
    },
    handleApprovePass () {
      const row = this.approveRow
      this.$confirm(`确认通过该审批任务（${row.business_no}）？`, '审批通过', { type: 'success' }).then(async () => {
        this.approveSubmitting = true
        try {
          const r = await approveTask(row.id, { comment: this.approveComment })
          if (r.code === 0) { this.$message.success((r.data && r.data.msg) || '审批已通过'); this.afterApproveSuccess(); this.approveVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.approveSubmitting = false }
      }).catch(() => {})
    },
    handleApproveReject () {
      const row = this.approveRow
      if (!this.approveComment.trim()) { this.$message.error('驳回时必须填写审批意见'); return }
      this.$confirm(`确认驳回该审批任务（${row.business_no}）？`, '审批驳回', { type: 'warning' }).then(async () => {
        this.approveSubmitting = true
        try {
          const r = await rejectTask(row.id, { comment: this.approveComment })
          if (r.code === 0) { this.$message.success('已驳回'); this.afterApproveSuccess(); this.approveVisible = false; this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.approveSubmitting = false }
      }).catch(() => {})
    },
    // ---- 转办 ----
    openTransfer (row) {
      this.transferInfo = { row, currentApprover: '', targetUserId: null, reason: '' }
      this.transferVisible = true
      if (!this.userOptions.length) this.loadUsers()
      getApprovalDetail(row.id).then(r => {
        if (r.code === 0) {
          const nodes = (r.data.nodes || []).filter(n => n.node_index === row.current_node_index && n.status === 0)
          this.transferInfo.currentApprover = nodes.length ? (nodes[0].approver_name || '') : ''
        }
      }).catch(() => {})
    },
    async loadUsers () {
      try {
        const r = await getUserOptions({ page: 1, pageSize: 100 })
        if (r.code === 0) {
          this.userOptions = Array.isArray(r.data) ? r.data : (r.data.list || [])
        }
      } catch (e) {}
    },
    handleTransfer () {
      const { row, targetUserId, reason } = this.transferInfo
      if (!targetUserId) { this.$message.error('请选择转办人'); return }
      this.transferSubmitting = true
      transferTask(row.id, { target_user_id: targetUserId, reason }).then(r => {
        if (r.code === 0) { this.$message.success('转办成功'); this.transferVisible = false; this.loadData() } else this.$message.error(r.msg || '转办失败')
      }).catch(() => {}).finally(() => { this.transferSubmitting = false })
    },
    // ---- 催办 ----
    handleUrge (row) {
      urgeCheckTask(row.id).then(async r => {
        if (r.code !== 0) return
        if (r.data && r.data.can_urge === false) {
          this.$message.error('该任务 24 小时内已催办过，请稍后再试')
          return
        }
        try {
          const res = await urgeTask(row.id)
          if (res.code === 0) {
            this.$message.success('催办通知已发送')
            this.$set(this.urgeLocked, row.id, true)
            setTimeout(() => this.$set(this.urgeLocked, row.id, false), 24 * 3600 * 1000)
          } else this.$message.error(res.msg || '催办失败')
        } catch (e) {}
      }).catch(() => {})
    },
    // ---- 批量审批 ----
    openBatch () { this.batchComment = ''; this.batchVisible = true },
    handleBatchApprove () {
      if (!this.selection.length) return
      const ids = this.selection.map(s => s.id)
      this.batchSubmitting = true
      batchApproveTasks({ ids, comment: this.batchComment }).then(r => {
        if (r.code === 0) {
          this.$message.success((r.data && r.data.msg) || '批量审批完成')
          this.batchVisible = false
          this.loadData()
        } else this.$message.error(r.msg || '批量审批失败')
      }).catch(() => {}).finally(() => { this.batchSubmitting = false })
    },
    // ---- 通知设置 ----
    openNotify () {
      this.notifyVisible = true
      getNotifyConfig().then(r => {
        if (r.code === 0 && r.data) {
          this.notifyForm = {
            enable_site: r.data.enable_site !== undefined ? r.data.enable_site : 1,
            enable_email: r.data.enable_email || 0,
            enable_sms: r.data.enable_sms || 0,
            email_address: r.data.email_address || '',
            mobile: r.data.mobile || '',
            sms_available: r.data.sms_available !== false,
            scene_todo: r.data.scene_todo !== undefined ? r.data.scene_todo : 1,
            scene_urge: r.data.scene_urge !== undefined ? r.data.scene_urge : 1,
            scene_approve: r.data.scene_approve !== undefined ? r.data.scene_approve : 1,
            scene_reject: r.data.scene_reject !== undefined ? r.data.scene_reject : 1,
            scene_transfer: r.data.scene_transfer !== undefined ? r.data.scene_transfer : 1,
            scene_overdue: r.data.scene_overdue !== undefined ? r.data.scene_overdue : 1
          }
        }
      }).catch(() => {})
    },
    handleNotifySave () {
      const f = this.notifyForm
      if (f.enable_email && !f.email_address.trim()) { this.$message.error('开启邮件通知后请填写邮箱地址'); return }
      if (f.enable_email && f.email_address && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(f.email_address)) { this.$message.error('邮箱地址格式不正确'); return }
      if (f.enable_sms && !f.mobile.trim()) { this.$message.error('开启短信通知后请填写手机号码'); return }
      if (f.enable_sms && f.mobile && !/^1[3-9]\d{9}$/.test(f.mobile)) { this.$message.error('手机号码格式不正确'); return }
      if (![f.scene_todo, f.scene_urge, f.scene_approve, f.scene_reject, f.scene_transfer, f.scene_overdue].some(v => Number(v) === 1)) { this.$message.error('至少开启一个通知场景'); return }
      this.notifySubmitting = true
      saveNotifyConfig({
        enable_email: f.enable_email, enable_sms: f.enable_sms,
        email_address: f.email_address, mobile: f.mobile,
        scene_todo: f.scene_todo, scene_urge: f.scene_urge, scene_approve: f.scene_approve,
        scene_reject: f.scene_reject, scene_transfer: f.scene_transfer, scene_overdue: f.scene_overdue
      }).then(r => {
        if (r.code === 0) { this.$message.success('通知设置已保存'); this.notifyVisible = false } else this.$message.error(r.msg || '保存失败')
      }).catch(() => {}).finally(() => { this.notifySubmitting = false })
    },
    // ---- 详情 ----
    openDetail (id) {
      this.detailVisible = true
      this.detailLoading = true
      this.detailData = null
      getApprovalDetail(id).then(r => {
        if (r.code === 0) this.detailData = r.data
      }).catch(() => {}).finally(() => { this.detailLoading = false })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.stat-row { margin-bottom: 14px; }
.stat-card {
  display: flex; align-items: center; border-radius: 10px; padding: 18px 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06); cursor: pointer; transition: all 0.25s ease;
}
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12); }
.stat-pending { background: linear-gradient(135deg, #fff7e6, #ffe7ba); }
.stat-today { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-timeout { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-mine { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-icon { font-size: 34px; color: #909399; margin-right: 14px; }
.stat-pending .stat-icon { color: #E6A23C; }
.stat-today .stat-icon { color: #409EFF; }
.stat-timeout .stat-icon { color: #F56C6C; }
.stat-mine .stat-icon { color: #67C23A; }
.stat-num { font-size: 26px; font-weight: 700; line-height: 1.1; }
.num-pending { color: #E6A23C; }
.num-today { color: #409EFF; }
.num-timeout { color: #F56C6C; }
.num-mine { color: #67C23A; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.approve-op { margin: 14px 0 10px; display: flex; align-items: center; gap: 12px; }
.countersign-tip { color: #E6A23C; font-size: 13px; }
.phrase-bar { margin-top: 10px; display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }
.phrase-label { color: #909399; font-size: 13px; }
.batch-stat { margin-top: 10px; color: #909399; font-size: 13px; }
.tip-text { color: #c0c4cc; font-size: 12px; margin-left: 6px; }
.notify-section { font-size: 13px; font-weight: 600; color: #606266; border-bottom: 1px dashed #ebeef5; padding-bottom: 6px; margin: 4px 0 10px; }
.drawer-body { padding: 8px 20px 30px; }
.section-title { font-size: 15px; font-weight: 600; margin: 20px 0 12px; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; }
.flow-progress { font-size: 12px; color: #909399; font-weight: 400; margin-left: 10px; }
.flow-steps { margin-top: 10px; }
.flow-steps /deep/ .el-step__head.is-process { color: #E6A23C; border-color: #E6A23C; }
.flow-steps /deep/ .el-step__title.is-process { color: #E6A23C; }
.tl-card { border: 1px solid #ebeef5; border-radius: 6px; padding: 8px 12px; background: #fff; }
.tl-head { display: flex; align-items: center; gap: 10px; }
.tl-operator { font-weight: 600; color: #303133; }
.tl-result { color: #606266; }
.tl-notify { color: #c0c4cc; font-size: 12px; }
.tl-comment { margin-top: 6px; color: #606266; font-size: 13px; }
.photo-grid { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 4px; }
.photo-img { width: 90px; height: 90px; border-radius: 6px; border: 1px solid #ebeef5; cursor: pointer; }
.approve-photos { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; align-items: center; }
.photo-label { font-size: 13px; color: #606266; width: 100%; }
</style>
