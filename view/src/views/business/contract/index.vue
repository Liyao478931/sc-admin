<!--
  文件：admin/src/views/business/contract/index.vue
  功能：经营管理 → 订单中心 → 合同管理
    - 统计卡片（总数/生效中/本月新增/本月金额/即将到期/已过期）
    - 八维筛选
    - 表格 + 操作（详情/编辑/提交审批/审批/状态/终止/续签/复制/删除）
    - 弹窗：新增编辑/详情/审批
-->
<template>
  <div class="contract-page">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">合同总数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.active || 0 }}</div><div class="stat-label">生效中</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.month_new || 0 }}</div><div class="stat-label">本月新增</div></el-card></el-col>
      <el-col :span="5"><el-card shadow="never" class="stat-card"><div class="stat-num red">¥{{ Number(stats.month_amount || 0).toLocaleString() }}</div><div class="stat-label">本月金额</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ stats.soon || 0 }}</div><div class="stat-label">即将到期</div></el-card></el-col>
      <el-col :span="3"><el-card shadow="never" class="stat-card"><div class="stat-num red">{{ stats.expired || 0 }}</div><div class="stat-label">已过期</div></el-card></el-col>
    </el-row>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="filter.keyword" placeholder="合同编号/名称" clearable style="width:160px" @keyup.enter.native="search" />
        </el-form-item>
        <el-form-item label="合同类型">
          <el-select v-model="filter.contract_type" placeholder="全部" clearable style="width:110px">
            <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="合同状态">
          <el-select v-model="filter.contract_status" placeholder="全部" clearable style="width:105px">
            <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="签署状态">
          <el-select v-model="filter.sign_status" placeholder="全部" clearable style="width:100px">
            <el-option v-for="opt in signStatusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="合同模板">
          <el-select v-model="filter.template_id" placeholder="全部" clearable style="width:120px">
            <el-option v-for="t in templateOptions" :key="t.id" :label="t.template_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="对方名称">
          <el-input v-model="filter.party" placeholder="客户/供应商" clearable style="width:130px" @keyup.enter.native="search" />
        </el-form-item>
        <el-form-item label="签订日期">
          <el-date-picker v-model="signRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:210px" />
        </el-form-item>
        <el-form-item label="到期日期">
          <el-date-picker v-model="expiryRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:210px" />
        </el-form-item>
        <el-form-item label="负责人">
          <el-select v-model="filter.responsible_person_id" placeholder="全部" clearable filterable style="width:120px">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="金额范围">
          <el-input-number v-model="filter.amount_min" :min="0" :precision="2" style="width:100px" placeholder="最低" />
          <span style="margin:0 4px">-</span>
          <el-input-number v-model="filter.amount_max" :min="0" :precision="2" style="width:100px" placeholder="最高" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <div class="toolbar">
      <el-button v-if="hasPerm('business:contract:add')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增合同</el-button>
      <el-button v-if="hasPerm('business:contract:export')" size="small" icon="el-icon-download" @click="handleExport">导出合同</el-button>
      <span class="flex-1"></span>
      <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
    </div>

    <el-table :data="list" v-loading="loading" size="small" stripe border>
      <el-table-column prop="contract_no" label="合同编号" width="155" show-overflow-tooltip />
      <el-table-column prop="contract_name" label="合同名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="合同类型" width="100" align="center">
        <template slot-scope="s"><el-tag size="mini" :type="typeTag(s.row.contract_type)">{{ s.row.contract_type_text }}</el-tag></template>
      </el-table-column>
      <el-table-column label="合同模板" width="120">
        <template slot-scope="s">
          <el-tag v-if="s.row.template_name" size="mini" type="info">{{ s.row.template_name }}</el-tag>
          <span v-else style="color:#c0c4cc">未使用模板</span>
        </template>
      </el-table-column>
      <el-table-column prop="party_name" label="客户/供应商" min-width="130" show-overflow-tooltip />
      <el-table-column label="合同金额" width="110">
        <template slot-scope="s">¥{{ Number(s.row.contract_amount || 0).toLocaleString() }}</template>
      </el-table-column>
      <el-table-column prop="sign_date" label="签订日期" width="100" />
      <el-table-column prop="effective_date" label="生效日期" width="100" />
      <el-table-column prop="expiry_date" label="到期日期" width="100" />
      <el-table-column label="状态" width="85" align="center">
        <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.contract_status)">{{ s.row.contract_status_text }}</el-tag></template>
      </el-table-column>
      <el-table-column label="签署状态" width="90" align="center">
        <template slot-scope="s"><el-tag size="mini" :type="signStatusTag(s.row.sign_status)">{{ s.row.sign_status_text || '待签署' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="合同摘要" min-width="180">
        <template slot-scope="s">
          <el-popover placement="top-start" title="合同摘要" width="400" trigger="hover" :content="s.row.content_summary || '暂无内容'">
            <span slot="reference" class="summary-text">{{ s.row.content_summary || '暂无内容' }}</span>
          </el-popover>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="360" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
          <el-button v-if="hasPerm('business:contract:edit')" type="text" size="mini" @click="openOrderDialog(s.row)">订单</el-button>
          <el-button v-if="hasPerm('business:contract:sign') && s.row.contract_status === 'approved' && ['pending','expired'].includes(s.row.sign_status)" type="text" size="mini" class="orange" @click="handleInitiateSign(s.row)">发起签署</el-button>
          <el-button v-if="hasPerm('business:contract:sign') && s.row.contract_status === 'approved' && s.row.sign_status === 'signing'" type="text" size="mini" @click="handleSignStatus(s.row)">签署进度</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && ['draft','pending'].includes(s.row.contract_status)" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && s.row.contract_status === 'draft'" type="text" size="mini" @click="handleSubmit(s.row)">提交审批</el-button>
          <el-button v-if="hasPerm('business:contract:approve') && s.row.contract_status === 'pending'" type="text" size="mini" class="orange" @click="openApproval(s.row.id)">审批</el-button>
          <el-dropdown v-if="hasPerm('business:contract:edit') && ['approved','executing'].includes(s.row.contract_status)" size="mini" style="margin:0 4px" trigger="click" @command="c => changeStatus(s.row, c)">
            <el-button type="text" size="mini">状态<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.contract_status === 'approved'" command="executing">开始执行</el-dropdown-item>
              <el-dropdown-item v-if="s.row.contract_status === 'executing'" command="completed">完成执行</el-dropdown-item>
              <el-dropdown-item command="terminated">终止</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button v-if="hasPerm('business:contract:add') && ['approved','executing'].includes(s.row.contract_status)" type="text" size="mini" @click="handleRenew(s.row)">续签</el-button>
          <el-button v-if="hasPerm('business:contract:add')" type="text" size="mini" @click="handleCopy(s.row)">复制</el-button>
          <el-button v-if="hasPerm('business:contract:delete') && ['draft','voided'].includes(s.row.contract_status)" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown v-if="hasPerm('business:contract:template:export') || hasPerm('business:contract:add')" size="mini" style="margin:0 4px" trigger="click" @command="c => handleContractAction(c, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="preview">预览合同</el-dropdown-item>
              <el-dropdown-item command="regenerate" :disabled="s.row.contract_status !== 'draft'">重新生成</el-dropdown-item>
              <el-dropdown-item command="export_pdf">导出PDF</el-dropdown-item>
              <el-dropdown-item command="export_word">导出Word</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>
    <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />

    <!-- ===== 弹窗 ===== -->
    <ContractFormDialog :visible="formVisible" :row="currentRow" @update:visible="v => (formVisible = v)" @success="onFormSuccess" />
    <ContractDetailDialog :visible="detailVisible" :contract-id="detailId" @update:visible="v => (detailVisible = v)" @refresh="onDetailRefresh" @edit="openForm" @approve="row => openApproval(row.id)" @change="openChange" />

    <!-- 关联订单弹窗（多订单可关联同一合同） -->
    <el-dialog title="关联订单" :visible="orderDialogVisible" width="720px" :close-on-click-modal="false" @close="orderDialogVisible = false">
      <div class="tip-bar">合同 [{{ orderDialogRow ? orderDialogRow.contract_no : '' }}] 已关联 {{ orderList.length }} 个订单</div>
      <div style="display:flex;gap:8px;margin:10px 0">
        <el-select v-model="orderPick" filterable remote :remote-method="searchOrders" :loading="orderSearching" placeholder="搜索并选择订单（生产/维修）" style="flex:1" @focus="!orderOptions.length && searchOrders('')">
          <el-option v-for="o in orderOptions" :key="o.id" :label="o.order_no + ' / ' + (o.customer_name || '') + ' / ' + o.order_category_text" :value="o.id" />
        </el-select>
        <el-button type="primary" size="small" @click="bindOrder(orderPick)">添加关联</el-button>
      </div>
      <el-table :data="orderList" size="small" border max-height="300" v-loading="orderLoading">
        <el-table-column prop="order_no" label="订单编号" width="150" show-overflow-tooltip />
        <el-table-column prop="order_category_text" label="订单类别" width="90" align="center" />
        <el-table-column prop="customer_name" label="客户" min-width="120" show-overflow-tooltip />
        <el-table-column label="订单金额" width="110" align="right"><template slot-scope="s">¥ {{ Number(s.row.order_amount || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column prop="order_status_text" label="状态" width="90" align="center" />
        <el-table-column label="操作" width="80" align="center"><template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="unbindOrder(s.row.id)">解除</el-button></template></el-table-column>
      </el-table>
      <el-empty v-if="!orderList.length && !orderLoading" description="尚未关联订单" :image-size="60" />
    </el-dialog>
    <ContractApprovalDialog :visible="approvalVisible" :contract-id="approvalId" @update:visible="v => (approvalVisible = v)" @success="onApprovalSuccess" />

    <!-- 合同预览弹窗 -->
    <el-dialog :visible.sync="previewVisible" title="合同预览" width="900px" top="5vh" :close-on-click-modal="false">
      <div v-loading="previewLoading" class="contract-preview" v-html="previewHtml"></div>
      <span slot="footer" class="dialog-footer">
        <el-button size="small" @click="previewVisible = false">关闭</el-button>
        <el-button size="small" type="primary" @click="exportPdf(previewRow)">导出PDF</el-button>
        <el-button size="small" type="success" @click="exportWord(previewRow)">导出Word</el-button>
      </span>
    </el-dialog>

    <!-- 合同变更弹窗 -->
    <el-dialog title="合同变更" :visible.sync="changeVisible" width="520px" :close-on-click-modal="false">
      <el-form :model="changeForm" label-width="100px" size="small">
        <el-form-item label="合同编号">{{ changeRow ? changeRow.contract_no : '' }}</el-form-item>
        <el-form-item label="变更类型">
          <el-select v-model="changeForm.change_type" style="width:100%">
            <el-option label="金额变更" value="amount" />
            <el-option label="日期变更" value="date" />
            <el-option label="内容变更" value="content" />
            <el-option label="状态变更" value="status" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="changeForm.change_type === 'amount'" label="变更后金额">
          <el-input-number v-model="changeForm.new_value" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item v-else-if="changeForm.change_type === 'date'" label="生效/到期日期">
          <el-date-picker v-model="changeForm.date_effective" type="date" value-format="yyyy-MM-dd" placeholder="生效日期" style="width:100%;margin-bottom:6px" />
          <el-date-picker v-model="changeForm.date_expiry" type="date" value-format="yyyy-MM-dd" placeholder="到期日期" style="width:100%" />
        </el-form-item>
        <el-form-item v-else-if="changeForm.change_type === 'content'" label="变更后内容">
          <el-input v-model="changeForm.new_value" type="textarea" :rows="4" />
          <div class="tpl-tip">已预填当前合同内容，请在其基础上修改</div>
        </el-form-item>
        <el-form-item v-else label="变更后状态">
          <el-select v-model="changeForm.new_value" style="width:100%">
            <el-option v-for="opt in allowedStatusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <div class="tpl-tip">仅显示当前状态允许流转的目标状态</div>
        </el-form-item>
        <el-form-item label="变更原因">
          <el-input v-model="changeForm.change_reason" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button size="small" @click="changeVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="changeSaving" @click="submitChange">确认变更</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import ContractFormDialog from './components/ContractFormDialog.vue'
import ContractDetailDialog from './components/ContractDetailDialog.vue'
import ContractApprovalDialog from './components/ContractApprovalDialog.vue'
import {
  getContractList, getContractStatistics, deleteContract, submitContract,
  renewContract, copyContract, changeContractStatus, changeContract, exportContract,
  initiateContractSign, getContractSignStatus,
  previewContractByTemplate, generateContractByTemplate, exportContractWord, exportContractPdf,
  getContractOrderList, bindContractOrder
} from '../../../api/businessContract'
import { getOrderList } from '../../../api/businessOrder'
import { getDictByCode } from '../../../api/dictionary'
import { getTemplateOptions } from '../../../api/contractTemplate'
import { isCarouselMode } from '@/utils/kioskMode'

export default {
  name: 'BusinessContract',
  components: { ContractFormDialog, ContractDetailDialog, ContractApprovalDialog },
  data() {
    return {
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      stats: {},
      filter: { keyword: '', contract_type: '', contract_status: '', sign_status: '', template_id: null, party: '', responsible_person_id: null, amount_min: 0, amount_max: 0 },
      signRange: [], expiryRange: [],
      typeOptions: [], statusOptions: [], signStatusOptions: [], templateOptions: [], userOptions: [],
      formVisible: false, currentRow: null,
      detailVisible: false, detailId: 0,
      approvalVisible: false, approvalId: 0,
      previewVisible: false, previewLoading: false, previewHtml: '', previewRow: null,
      changeVisible: false, changeRow: null, changeSaving: false,
      changeForm: { change_type: 'amount', old_value: '', new_value: '', change_reason: '', date_effective: '', date_expiry: '' },
      // 关联订单（多订单可关联同一合同）
      orderDialogVisible: false, orderDialogRow: null, orderList: [], orderLoading: false,
      orderOptions: [], orderPick: null, orderSearching: false
  }
},
computed: {
  allowedStatusOptions() {
    const flow = { draft: ['pending', 'voided'], pending: ['approved', 'draft', 'voided'], approved: ['executing', 'terminated'], executing: ['completed', 'terminated'], completed: [], terminated: [], voided: [] }
    const allow = flow[(this.changeRow && this.changeRow.contract_status)] || []
    return this.statusOptions.filter(o => allow.includes(o.value))
  }
},
watch: {
  'changeForm.change_type'(v) {
      this.changeForm.new_value = ''
      if (v === 'content') {
        // 预填当前合同内容（去 HTML 标签）
        const raw = (this.changeRow && (this.changeRow.content || this.changeRow.contract_html)) || ''
        this.changeForm.new_value = raw.replace(/<[^>]+>/g, '').trim()
      }
      if (v === 'date') {
        this.changeForm.date_effective = (this.changeRow && this.changeRow.effective_date) || ''
        this.changeForm.date_expiry = (this.changeRow && this.changeRow.expiry_date) || ''
      }
    }
  },
    created() {
      this.loadStats()
      this.loadList()
      this.loadDicts()
      this.loadTemplates()
      this.loadUsers()
    // 大屏轮播/展示模式下禁止自动打开新增合同写弹窗
    if (this.$route.path === '/business/contract/add' && !isCarouselMode()) {
      this.$nextTick(() => { this.formVisible = true })
    }
    // 从到期提醒页跳转打开详情
    if (this.$route.query && this.$route.query.detail) {
      const id = Number(this.$route.query.detail)
      if (id > 0) this.$nextTick(() => { this.detailId = id; this.detailVisible = true })
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    typeTag(t) { return { sales: 'primary', purchase: 'success', repair_service: 'warning' }[t] || 'info' },
    statusTag(s) { return { draft: 'info', pending: 'warning', approved: 'success', executing: 'primary', completed: 'info', terminated: 'danger', voided: 'info' }[s] || 'info' },
    signStatusTag(s) { return { pending: 'warning', signing: 'primary', signed: 'success', expired: 'danger' }[s] || 'info' },
    async loadDicts() {
      try { const r = await getDictByCode('contract_type'); this.typeOptions = r.data || [] } catch (e) { this.typeOptions = [] }
      try { const r = await getDictByCode('contract_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
      try { const r = await getDictByCode('sign_status'); this.signStatusOptions = r.data || [] } catch (e) { this.signStatusOptions = [] }
    },
    async loadTemplates() {
      try { const r = await getTemplateOptions(); this.templateOptions = (r.data && r.data.list) || [] } catch (e) { this.templateOptions = [] }
    },
    async loadUsers() {
      try {
        const { getUserList } = await import('../../../api/user')
        const r = await getUserList({ limit: 500 })
        this.userOptions = (r.data && r.data.list) || []
      } catch (e) { this.userOptions = [] }
    },
    search() { this.page = 1; this.loadList() },
    reset() {
      this.filter = { keyword: '', contract_type: '', contract_status: '', sign_status: '', template_id: null, party: '', responsible_person_id: null, amount_min: 0, amount_max: 0 }
      this.signRange = []; this.expiryRange = []
      this.page = 1
      this.loadList()
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getContractList({
          ...this.filter,
          page: this.page, limit: this.pageSize,
          sign_start: this.signRange && this.signRange[0] || '',
          sign_end: this.signRange && this.signRange[1] || '',
          expiry_start: this.expiryRange && this.expiryRange[0] || '',
          expiry_end: this.expiryRange && this.expiryRange[1] || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getContractStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    openForm(row) { this.currentRow = row || null; this.formVisible = true },
    onFormSuccess() { this.formVisible = false; this.loadList(); this.loadStats() },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    onDetailRefresh() { this.loadList(); this.loadStats(); this.detailVisible = false },
    // ===== 合同关联订单（多订单可关联同一合同）=====
    async openOrderDialog(row) {
      this.orderDialogRow = row
      this.orderPick = null
      this.orderDialogVisible = true
      this.loadContractOrders(row.id)
    },
    async loadContractOrders(contractId) {
      this.orderLoading = true
      try {
        const r = await getContractOrderList(contractId)
        this.orderList = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.orderList = [] }
      this.orderLoading = false
    },
    async searchOrders(keyword) {
      this.orderSearching = true
      try {
        const r = await getOrderList({ keyword: keyword || '', page: 1, pageSize: 20 })
        this.orderOptions = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.orderOptions = [] }
      this.orderSearching = false
    },
    async bindOrder(orderId) {
      if (!orderId) { this.$message.warning('请先选择订单'); return }
      try {
        const r = await bindContractOrder(this.orderDialogRow.id, orderId, 'bind')
        if (r.code === 0) {
          this.$message.success(r.msg)
          this.orderPick = null
          this.loadContractOrders(this.orderDialogRow.id)
          this.loadList()
        }
      } catch (e) {}
    },
    async unbindOrder(orderId) {
      this.$confirm('确认解除该订单的合同关联吗？', '解除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await bindContractOrder(this.orderDialogRow.id, orderId, 'unbind')
          if (r.code === 0) { this.$message.success(r.msg); this.loadContractOrders(this.orderDialogRow.id); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    openApproval(id) { this.approvalId = id; this.approvalVisible = true },
    onApprovalSuccess() { this.approvalVisible = false; this.loadList(); this.loadStats() },
    handleSubmit(row) {
      this.$confirm(`确认提交合同「${row.contract_no}」进行审批？`, '提交审批', { type: 'warning' }).then(async () => {
        try { const r = await submitContract(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确定删除合同「${row.contract_no}」？仅草稿/已作废可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteContract(row.id); if (r.code === 0) { this.$message.success('合同已删除'); this.loadList(); this.loadStats() } } catch (e) {}
      }).catch(() => {})
    },
    handleRenew(row) {
      this.$confirm(`确认续签合同「${row.contract_no}」，生成新合同？`, '续签合同', { type: 'warning' }).then(async () => {
        try { const r = await renewContract(row.id, {}); if (r.code === 0) { this.$message.success(r.msg); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    handleCopy(row) {
      this.$confirm(`复制合同「${row.contract_no}」生成新合同？`, '复制合同', { type: 'warning' }).then(async () => {
        try { const r = await copyContract(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    handleInitiateSign(row) {
      this.$confirm(`确认对合同「${row.contract_no}」发起电子签署？将调用腾讯电子签创建签署流程。`, '发起签署', { type: 'warning' }).then(async () => {
        try {
          const r = await initiateContractSign(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '签署流程已发起'); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleSignStatus(row) {
      try {
        const r = await getContractSignStatus(row.id)
        if (r.code === 0) {
          const d = r.data || {}
          const extra = d.sign_time ? `，完成时间：${d.sign_time}` : ''
          this.$message({ type: 'info', message: `签署状态：${d.sign_status_text || '-'}${extra}${d.sync_message ? '（' + d.sync_message + '）' : ''}` })
          this.loadList()
        }
      } catch (e) {}
    },
    async handleContractAction(cmd, row) {
      if (cmd === 'preview') { this.openPreview(row); return }
      if (cmd === 'regenerate') { this.regenerateContract(row); return }
      if (cmd === 'export_pdf') { this.exportPdf(row); return }
      if (cmd === 'export_word') { this.exportWord(row); return }
    },
    async openPreview(row) {
      this.previewRow = row
      this.previewHtml = row.contract_html || row.content || ''
      this.previewVisible = true
      if (!this.previewHtml) {
        this.previewLoading = true
        try {
          const { getContractDetail } = await import('../../../api/businessContract')
          const r = await getContractDetail(row.id)
          if (r.code === 0) this.previewHtml = r.data.contract_html || r.data.content || ''
        } catch (e) {}
        this.previewLoading = false
      }
    },
    regenerateContract(row) {
      if (row.contract_status !== 'draft') { this.$message.warning('仅草稿合同可重新生成'); return }
      this.$confirm(`确认按模板重新生成合同「${row.contract_no}」？将覆盖当前合同内容。`, '重新生成', { type: 'warning' }).then(async () => {
        try {
          const r = await generateContractByTemplate({ contract_id: row.id, template_id: row.template_id || 0 })
          if (r.code === 0) { this.$message.success(r.msg || '已重新生成'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    async exportPdf(row) {
      try {
        const res = await exportContractPdf(row.id)
        if (res.data && res.data.slice) this.downloadBlob(res.data, 'contract_' + (row.contract_no || row.id) + '.pdf', 'application/pdf')
        else if (typeof res.data === 'string' && res.data.indexOf('<!') === 0) this.openPrintHtml(res.data)
      } catch (e) {}
    },
    async exportWord(row) {
      try {
        const res = await exportContractWord(row.id)
        this.downloadBlob(res.data, 'contract_' + (row.contract_no || row.id) + '.doc', 'application/msword')
      } catch (e) {}
    },
    downloadBlob(blob, filename, type) {
      const url = URL.createObjectURL(new Blob([blob], { type }))
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    },
    openPrintHtml(html) {
      const w = window.open('', '_blank')
      if (w) { w.document.write(html); w.document.close(); w.print() }
    },
    openChange(row) {
      this.changeRow = row
      this.changeForm = { change_type: 'amount', old_value: '', new_value: row.contract_amount || 0, change_reason: '', date_effective: row.effective_date || '', date_expiry: row.expiry_date || '' }
      this.changeVisible = true
    },
    async submitChange() {
      if (this.changeForm.change_type === 'amount' && (this.changeForm.new_value === '' || this.changeForm.new_value === null)) { this.$message.warning('请填写变更后金额'); return }
      if (this.changeForm.change_type === 'date') {
        if (!this.changeForm.date_effective && !this.changeForm.date_expiry) { this.$message.warning('请选择变更日期'); return }
        this.changeForm.new_value = (this.changeForm.date_effective || '') + ':' + (this.changeForm.date_expiry || '')
      }
      if (this.changeForm.change_type !== 'amount' && this.changeForm.change_type !== 'date' && !this.changeForm.new_value) { this.$message.warning('请填写/选择变更后值'); return }
      if (!this.changeForm.change_reason) { this.$message.warning('请填写变更原因'); return }
      this.changeSaving = true
      try {
        const r = await changeContract(this.changeRow.id, {
          change_type: this.changeForm.change_type,
          old_value: String(this.changeForm.old_value),
          new_value: this.changeForm.change_type === 'amount' ? String(this.changeForm.new_value) : this.changeForm.new_value,
          change_reason: this.changeForm.change_reason
        })
        if (r.code === 0) { this.$message.success(r.msg || '变更已记录'); this.changeVisible = false; this.loadList() } else { this.$message.error(r.msg || '变更失败') }
      } catch (e) {}
      this.changeSaving = false
    },
    async changeStatus(row, status) {
      try {
        const r = await changeContractStatus(row.id, { contract_status: status, remark: '' })
        if (r.code === 0) { this.$message.success(r.msg); this.loadList(); this.loadStats() }
      } catch (e) {}
    },
    async handleExport() {
      try {
        const res = await exportContract({ ...this.filter })
        const blob = res.data
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'contracts_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.contract-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 22px; font-weight: 700; color: #303133; }
.stat-num.blue { color: #409eff; }
.stat-num.green { color: #67c23a; }
.stat-num.red { color: #f56c6c; font-size: 17px; }
.stat-num.orange { color: #e6a23c; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin: 12px 0; }
.flex-1 { flex: 1; }
.pager { margin-top: 12px; text-align: right; }
.danger { color: #f56c6c; }
.orange { color: #e6a23c; }
.summary-text { color: #606266; cursor: pointer; display: inline-block; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.contract-preview { max-height: 62vh; overflow-y: auto; padding: 16px; background: #fff; border: 1px solid #e8ecf1; font-family: 'SimSun', '宋体', serif; font-size: 14px; line-height: 1.8; }
.contract-preview table { width: 100%; border-collapse: collapse; margin: 15px 0; }
.contract-preview th, .contract-preview td { border: 1px solid #333; padding: 6px 10px; text-align: center; }
.contract-preview .contract-title { text-align: center; font-size: 22px; font-weight: bold; padding: 20px 0; }
.contract-preview .sign-area { margin-top: 30px; }
.contract-preview .sign-area table { border: none; }
.contract-preview .sign-area td { border: none; vertical-align: top; padding: 10px 20px; width: 50%; }
.dialog-footer { text-align: right; }
</style>
