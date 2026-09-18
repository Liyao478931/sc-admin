<!--
  文件：admin/src/views/business/contract/components/ContractDetailDialog.vue
  功能：合同详情弹窗（850px）
    - 基本信息 + 类型/状态标签
    - 合同条款 / 附件 / 审批记录 / 变更记录 / 续签关联
    - 按状态动态显示操作按钮
-->
<template>
  <el-dialog
    :title="detail ? detail.contract_no : '合同详情'"
    :visible="visible"
    width="850px"
    :close-on-click-modal="false"
    @close="$emit('update:visible', false)"
  >
    <div v-loading="loading" class="detail-wrap">
      <template v-if="detail">
        <el-descriptions :column="3" size="small" border>
          <el-descriptions-item label="合同编号">{{ detail.contract_no }}</el-descriptions-item>
          <el-descriptions-item label="合同类型">
            <el-tag size="mini" :type="typeTag(detail.contract_type)">{{ detail.contract_type_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="合同状态">
            <el-tag size="mini" :type="statusTag(detail.contract_status)">{{ detail.contract_status_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="签署状态">
            <el-tag size="mini" :type="signStatusTag(detail.sign_status)">{{ detail.sign_status_text || '待签署' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="合同名称" :span="2">{{ detail.contract_name }}</el-descriptions-item>
          <el-descriptions-item label="合同金额"><b style="color:#f56c6c">¥{{ Number(detail.contract_amount || 0).toLocaleString() }}</b></el-descriptions-item>
          <el-descriptions-item label="对方名称">{{ detail.party_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="签订日期">{{ detail.sign_date }}</el-descriptions-item>
          <el-descriptions-item label="生效日期">{{ detail.effective_date || '--' }}</el-descriptions-item>
          <el-descriptions-item label="到期日期">{{ detail.expiry_date || '--' }}</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ detail.responsible_person_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系人">{{ detail.contact_person || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ detail.contact_phone || '--' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="内容版本">{{ detail.content_version || 1 }}</el-descriptions-item>
        </el-descriptions>
        <!-- 签署信息 -->
        <div v-if="['approved','executing'].includes(detail.contract_status)" class="sign-block">
          <div class="block-label">签署信息</div>
          <div v-if="detail.sign_status === 'signing'" style="margin-bottom:8px;">
            <el-progress :percentage="50" :stroke-width="10" text-inside status="active" style="max-width:420px;" />
            <div class="sign-tip">双方签署中，完成签署后自动下载归档签署文件</div>
          </div>
          <div v-if="detail.sign_url" class="sign-url">
            签署链接：<a :href="detail.sign_url" target="_blank" class="sign-link">{{ detail.sign_url }}</a>
            <el-button size="mini" type="text" @click="copyText(detail.sign_url)">复制</el-button>
          </div>
          <div v-if="detail.sign_flow_id" class="sign-tip">签署流程ID：{{ detail.sign_flow_id }}</div>
          <div v-if="detail.sign_time" class="sign-tip">签署完成时间：{{ detail.sign_time }}</div>
        </div>

        <div v-if="detail.contract_html || detail.content" class="content-block">
          <div class="block-label">合同内容
            <span class="content-actions">
              <el-button size="mini" type="text" @click="exportPdf">导出PDF</el-button>
              <el-button size="mini" type="text" @click="exportWord">导出Word</el-button>
              <el-button size="mini" type="text" @click="printContract">打印</el-button>
            </span>
          </div>
          <div v-if="isHtmlContent" class="contract-html" v-html="detail.contract_html || detail.content"></div>
          <div v-else class="content-text">{{ detail.content }}</div>
        </div>
        <div v-if="detail.remark" class="remark">备注：{{ detail.remark }}</div>

        <!-- 条款 -->
        <el-divider content-position="left">合同条款</el-divider>
        <div v-if="detail.clauses && detail.clauses.length">
          <div v-for="(c, i) in detail.clauses" :key="i" class="clause-item">
            <b>{{ c.clause_title }}</b><div class="clause-content">{{ c.clause_content }}</div>
          </div>
        </div>
        <div v-else class="no-data">暂无条款</div>

        <!-- 附件 -->
        <el-divider content-position="left">附件</el-divider>
        <div v-if="detail.attachments && detail.attachments.length">
          <a v-for="(u, i) in detail.attachments" :key="i" class="attach-link" :href="attachUrl(u)" target="_blank"><i class="el-icon-paperclip"></i> {{ attachName(u) }}</a>
        </div>
        <div v-else class="no-data">暂无附件</div>

        <!-- 审批记录 -->
        <el-divider content-position="left">审批记录</el-divider>
        <el-table v-if="detail.approvals && detail.approvals.length" :data="detail.approvals" size="mini" border>
          <el-table-column prop="approver_name" label="审批人" width="100" />
          <el-table-column label="结果" width="80"><template slot-scope="s"><el-tag size="mini" :type="s.row.approval_result === 'pass' ? 'success' : 'danger'">{{ s.row.approval_result_text }}</el-tag></template></el-table-column>
          <el-table-column prop="approval_comment" label="意见" min-width="200" />
          <el-table-column prop="approval_time" label="审批时间" width="160" />
        </el-table>
        <div v-else class="no-data">暂无审批记录</div>

        <!-- 变更记录 -->
        <el-divider content-position="left">变更记录</el-divider>
        <el-table v-if="detail.changes && detail.changes.length" :data="detail.changes" size="mini" border>
          <el-table-column prop="change_type_text" label="变更类型" width="100" />
          <el-table-column prop="old_value" label="变更前" min-width="120" show-overflow-tooltip />
          <el-table-column prop="new_value" label="变更后" min-width="120" show-overflow-tooltip />
          <el-table-column prop="change_reason" label="原因" min-width="120" show-overflow-tooltip />
          <el-table-column prop="operator_name" label="操作人" width="90" />
          <el-table-column prop="create_time" label="时间" width="160" />
        </el-table>
        <div v-else class="no-data">暂无变更记录</div>

        <!-- 续签关联 -->
        <div v-if="detail.renew_contracts && detail.renew_contracts.length" class="renew-block">
          <span class="block-label">续签合同：</span>
          <el-tag v-for="rc in detail.renew_contracts" :key="rc.id" size="small" class="renew-tag">{{ rc.contract_no }}（{{ rc.contract_name }}）</el-tag>
        </div>

        <!-- 操作按钮 -->
        <div class="op-btns">
          <el-button v-if="hasPerm('business:contract:sign') && detail.contract_status === 'approved' && ['pending','expired'].includes(detail.sign_status)" type="warning" size="small" @click="act('sign')">发起签署</el-button>
          <el-button v-if="hasPerm('business:contract:sign') && detail.contract_status === 'approved' && detail.sign_status === 'signing'" size="small" @click="act('resend')">重发通知</el-button>
          <el-button v-if="hasPerm('business:contract:sign') && detail.contract_status === 'approved' && detail.sign_status === 'signing'" type="primary" plain size="small" @click="act('signStatus')">签署状态</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && detail.contract_status === 'draft'" type="primary" size="small" @click="act('submit')">提交审批</el-button>
          <el-button v-if="hasPerm('business:contract:approve') && detail.contract_status === 'pending'" type="success" size="small" @click="$emit('approve', detail)">审批</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && ['pending','approved'].includes(detail.contract_status)" type="primary" size="small" @click="act('effect')">生效</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && ['approved','executing'].includes(detail.contract_status)" type="danger" size="small" @click="act('terminate')">终止</el-button>
          <el-button v-if="hasPerm('business:contract:add') && ['approved','executing'].includes(detail.contract_status)" size="small" @click="act('renew')">续签</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && ['draft','pending'].includes(detail.contract_status)" size="small" @click="act('void')">作废</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && ['draft','pending'].includes(detail.contract_status)" size="small" @click="$emit('edit', detail)">编辑</el-button>
          <el-button v-if="hasPerm('business:contract:edit') && ['approved','executing'].includes(detail.contract_status)" size="small" @click="$emit('change', detail)">变更</el-button>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getContractDetail, submitContract, effectContract, terminateContract, renewContract, voidContract, initiateContractSign, resendContractSign, getContractSignStatus, exportContractWord, exportContractPdf } from '../../../../api/businessContract'

export default {
  name: 'ContractDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    contractId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, detail: null }
  },
  computed: {
    isHtmlContent() {
      const c = this.detail && (this.detail.contract_html || this.detail.content)
      return !!c && /<\/?[a-z][\s\S]*>/i.test(c)
    }
  },
  watch: {
    visible(val) { if (val && this.contractId) this.open() }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    typeTag(t) { return { sales: 'primary', purchase: 'success', repair_service: 'warning' }[t] || 'info' },
    statusTag(s) { return { draft: 'info', pending: 'warning', approved: 'success', executing: 'primary', completed: 'info', terminated: 'danger', voided: 'info' }[s] || 'info' },
    signStatusTag(s) { return { pending: 'warning', signing: 'primary', signed: 'success', expired: 'danger' }[s] || 'info' },
    async open() {
      this.loading = true
      this.detail = null
      try {
        const r = await getContractDetail(this.contractId)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
    async act(action) {
      // 签署状态查看无需确认
      if (action === 'signStatus') { this.viewSignStatus(); return }
      const msgs = { submit: '确认提交审批？', terminate: '确认终止该合同？', renew: '确认续签该合同（生成新合同）？', void: '确认作废该合同？', sign: '确认对该合同发起电子签署？将调用腾讯电子签创建签署流程。', resend: '确认重发签署通知？' }
      this.$confirm(msgs[action] || '确认执行？', '操作确认', { type: 'warning' }).then(async () => {
        try {
          let r
          if (action === 'submit') r = await submitContract(this.contractId)
          else if (action === 'effect') r = await effectContract(this.contractId)
          else if (action === 'terminate') r = await terminateContract(this.contractId, { terminate_reason: '详情页终止' })
          else if (action === 'renew') r = await renewContract(this.contractId, {})
          else if (action === 'void') r = await voidContract(this.contractId)
          else if (action === 'sign') r = await initiateContractSign(this.contractId)
          else if (action === 'resend') r = await resendContractSign(this.contractId)
          if (r.code === 0) { this.$message.success(r.msg); this.$emit('refresh') }
        } catch (e) {}
      }).catch(() => {})
    },
    async viewSignStatus() {
      try {
        const r = await getContractSignStatus(this.contractId)
        if (r.code === 0) {
          const d = r.data || {}
          const extra = d.sign_time ? `，完成时间：${d.sign_time}` : ''
          this.$message({ type: 'info', message: `签署状态：${d.sign_status_text || '-'}${extra}${d.sync_message ? '（' + d.sync_message + '）' : ''}` })
          this.open()
        }
      } catch (e) {}
    },
    async exportPdf() {
      try {
        const res = await exportContractPdf(this.contractId)
        if (res.data && res.data.slice) this.downloadBlob(res.data, 'contract_' + this.contractId + '.pdf', 'application/pdf')
        else if (typeof res.data === 'string' && res.data.indexOf('<!') === 0) this.openPrintHtml(res.data)
      } catch (e) {}
    },
    async exportWord() {
      try {
        const res = await exportContractWord(this.contractId)
        this.downloadBlob(res.data, 'contract_' + this.contractId + '.doc', 'application/msword')
      } catch (e) {}
    },
    printContract() {
      const html = (this.detail && (this.detail.contract_html || this.detail.content)) || ''
      if (!html) { this.$message.warning('合同内容为空'); return }
      this.openPrintHtml(html)
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
    attachUrl(u) { return typeof u === 'string' ? u : ((u && u.url) || '') },
    attachName(u) { if (typeof u === 'object' && u && u.name) return u.name; const url = this.attachUrl(u); return url.split('/').pop() || url },
    copyText(text) {
      if (!text) { this.$message.warning('暂无可复制内容'); return }
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => this.$message.success('已复制')).catch(() => this.fallbackCopy(text))
      } else {
        this.fallbackCopy(text)
      }
    },
    fallbackCopy(text) {
      const ta = document.createElement('textarea')
      ta.value = text
      document.body.appendChild(ta)
      ta.select()
      try { document.execCommand('copy'); this.$message.success('已复制') } catch (e) { this.$message.warning('复制失败，请手动复制') }
      document.body.removeChild(ta)
    }
  }
}
</script>

<style scoped>
.remark { margin-top: 10px; font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
.content-block { margin-top: 10px; }
.block-label { font-size: 13px; font-weight: 600; color: #303133; margin-bottom: 6px; display: flex; align-items: center; justify-content: space-between; }
.content-actions { font-weight: normal; }
.contract-html { font-family: 'SimSun', '宋体', serif; font-size: 14px; line-height: 1.8; padding: 12px; background: #f8f9fb; border-radius: 4px; max-height: 400px; overflow-y: auto; }
.contract-html table { width: 100%; border-collapse: collapse; margin: 12px 0; }
.contract-html th, .contract-html td { border: 1px solid #333; padding: 6px 10px; text-align: center; }
.contract-html .contract-title { text-align: center; font-size: 22px; font-weight: bold; padding: 16px 0; }
.contract-html .sign-area { margin-top: 24px; }
.contract-html .sign-area table { border: none; }
.contract-html .sign-area td { border: none; vertical-align: top; padding: 10px 20px; width: 50%; }
.content-text { font-size: 13px; color: #606266; background: #f8f9fb; padding: 10px 12px; border-radius: 4px; }
.clause-item { padding: 8px 0; border-bottom: 1px dashed #ebeef5; font-size: 13px; }
.clause-content { color: #606266; margin-top: 4px; }
.no-data { color: #909399; font-size: 12px; padding: 10px 0; }
.attach-link { display: inline-block; margin: 0 12px 6px 0; color: #409eff; font-size: 13px; }
.renew-block { margin-top: 12px; }
.renew-tag { margin-right: 6px; }
.sign-block { margin-top: 10px; }
.sign-url { font-size: 13px; color: #606266; margin: 4px 0; word-break: break-all; }
.sign-link { color: #409eff; }
.sign-tip { font-size: 12px; color: #909399; margin-top: 4px; }
.op-btns { margin-top: 16px; text-align: right; }
</style>
