<template>
  <el-dialog :title="dialogTitle" :visible="visible" width="950px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <!-- 事故基本信息（只读） -->
      <el-descriptions v-if="accident" :column="3" size="small" border style="margin-bottom:14px;">
        <el-descriptions-item label="事故编号">{{ accident.accident_code }}</el-descriptions-item>
        <el-descriptions-item label="事故名称">{{ accident.accident_name }}</el-descriptions-item>
        <el-descriptions-item label="类型/等级">{{ accident.type_text }} / {{ accident.level_text }}</el-descriptions-item>
        <el-descriptions-item label="发生时间">{{ accident.happen_time }}</el-descriptions-item>
        <el-descriptions-item label="发生地点">{{ accident.happen_location }}</el-descriptions-item>
        <el-descriptions-item label="发生部门">{{ accident.happen_department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="事故经过" :span="3">{{ accident.accident_process }}</el-descriptions-item>
      </el-descriptions>

      <template v-if="!readonly">
        <!-- 原因分析 -->
        <el-divider content-position="left">事故原因分析</el-divider>
        <el-form label-width="100px" size="small">
          <el-form-item label="直接原因" required><el-input v-model="form.direct_cause" type="textarea" :rows="2" /></el-form-item>
          <el-form-item label="间接原因" required><el-input v-model="form.indirect_cause" type="textarea" :rows="2" /></el-form-item>
          <el-form-item label="根本原因" required><el-input v-model="form.root_cause" type="textarea" :rows="2" /></el-form-item>
        </el-form>

        <!-- 责任认定 -->
        <el-divider content-position="left">事故责任认定</el-divider>
        <el-form label-width="100px" size="small">
          <el-form-item label="责任人"><el-input v-model="form.responsible_person" style="width:220px" maxlength="50" /></el-form-item>
          <el-form-item label="责任部门"><el-input v-model="form.responsible_department" style="width:280px" maxlength="100" /></el-form-item>
          <el-form-item label="责任认定" required><el-input v-model="form.responsibility_opinion" type="textarea" :rows="2" /></el-form-item>
          <el-form-item label="处理建议" required><el-input v-model="form.handle_suggestion" type="textarea" :rows="2" /></el-form-item>
        </el-form>

        <!-- 整改措施 -->
        <el-divider content-position="left">整改措施</el-divider>
        <div v-for="(m, i) in form.corrective_measures" :key="i" style="display:flex;gap:8px;margin-bottom:8px;align-items:center;">
          <el-input v-model="m.measure" placeholder="措施内容" style="flex:2;" />
          <el-input v-model="m.responsible_person" placeholder="责任人" style="flex:1;" />
          <el-date-picker v-model="m.deadline" type="date" value-format="yyyy-MM-dd" placeholder="完成期限" style="width:140px;" />
          <el-select v-model="m.status" style="width:100px;">
            <el-option label="进行中" value="doing" /><el-option label="已完成" value="done" />
          </el-select>
          <el-button type="text" style="color:#F56C6C" @click="form.corrective_measures.splice(i,1)">删除</el-button>
        </div>
        <el-button size="small" type="text" icon="el-icon-plus" @click="form.corrective_measures.push({ measure: '', responsible_person: '', deadline: '', status: 'doing' })">添加措施</el-button>

        <!-- 调查结论 -->
        <el-divider content-position="left">调查结论</el-divider>
        <el-form label-width="100px" size="small">
          <el-form-item label="调查结论" required><el-input v-model="form.conclusion" type="textarea" :rows="3" /></el-form-item>
          <el-form-item label="报告附件">
            <el-upload action="/api/safety/accident/investigate/upload-attachment" :headers="uploadHeaders" :limit="5" :file-list="fileList"
              :on-success="onUploadSuccess" :on-remove="onUploadRemove">
              <el-button size="small" icon="el-icon-upload">上传附件（PDF/Word/图片）</el-button>
            </el-upload>
        <div style="margin-top:6px">
          <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
        </div>
        <drive-file-picker :visible="driveVisible" mode="file" :multiple="true" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
          </el-form-item>
        </el-form>
      </template>

      <!-- 只读报告（已结案查看） -->
      <template v-else>
        <el-card shadow="never" style="margin-bottom:12px;">
          <div class="sec-title">原因分析</div>
          <div class="sec-text">直接原因：{{ inv.direct_cause || '-' }}</div>
          <div class="sec-text">间接原因：{{ inv.indirect_cause || '-' }}</div>
          <div class="sec-text">根本原因：{{ inv.root_cause || '-' }}</div>
        </el-card>
        <el-card shadow="never" style="margin-bottom:12px;">
          <div class="sec-title">责任认定</div>
          <div class="sec-text">责任人：{{ inv.responsible_person || '-' }}　责任部门：{{ inv.responsible_department || '-' }}</div>
          <div class="sec-text">责任认定：{{ inv.responsibility_opinion || '-' }}</div>
          <div class="sec-text">处理建议：{{ inv.handle_suggestion || '-' }}</div>
        </el-card>
        <el-card shadow="never" style="margin-bottom:12px;">
          <div class="sec-title">整改措施</div>
          <div v-for="(m, i) in (inv.corrective_measures || [])" :key="i" class="sec-text">{{ i + 1 }}. {{ m.measure }}（责任人：{{ m.responsible_person }}，期限：{{ m.deadline }}，{{ m.status === 'done' ? '已完成' : '进行中' }}）</div>
          <div v-if="!(inv.corrective_measures || []).length" class="sec-text">无</div>
        </el-card>
        <el-card shadow="never" style="margin-bottom:12px;">
          <div class="sec-title">调查结论</div>
          <div class="sec-text">{{ inv.conclusion || '-' }}</div>
          <div v-if="inv.attachments && inv.attachments.length" style="margin-top:8px;">
            <a v-for="(a, i) in inv.attachments" :key="i" :href="a.url" target="_blank" style="margin-right:12px;font-size:13px;color:#409EFF;">附件{{ i + 1 }}</a>
          </div>
        </el-card>
        <el-card shadow="never">
          <div class="sec-title">审批信息</div>
          <div class="sec-text">审批状态：{{ submitText }}　审批人：{{ inv.approver_name || '-' }}　审批时间：{{ inv.approved_at || '-' }}</div>
          <div v-if="inv.reject_reason" class="sec-text" style="color:#F56C6C;">驳回原因：{{ inv.reject_reason }}</div>
        </el-card>
      </template>

      <!-- 时间线 -->
      <el-card shadow="never" style="margin-top:12px;">
        <div class="sec-title">调查时间线</div>
        <el-timeline v-if="timeline.length">
          <el-timeline-item v-for="(t, i) in timeline" :key="i" :timestamp="t.create_time">
            {{ t.description }}（{{ t.operator_name }}）
          </el-timeline-item>
        </el-timeline>
        <div v-else class="sec-text">暂无记录</div>
      </el-card>
    </div>

    <div slot="footer">
      <el-button v-if="inv && inv.submit_status === 'rejected' && inv.reject_reason" size="small" style="float:left;" type="danger" plain>{{ '驳回原因：' + inv.reject_reason }}</el-button>
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
      <el-button v-if="canExport" size="small" icon="el-icon-download" @click="doExport">导出报告</el-button>
      <template v-if="!readonly && editable">
        <el-button size="small" type="primary" plain :loading="saving" @click="saveDraft">保存草稿</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="doSubmit">提交审批</el-button>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getInvestigateDetail, saveInvestigateDraft, submitInvestigate, exportInvestigate } from '@/api/safetyAccident'
import { getToken } from '@/utils/auth'

export default {
  name: 'InvestigateReportDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { loading: false, accident: null, inv: null, timeline: [], saving: false, submitting: false, fileList: [], driveVisible: false }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + (getToken() || '') } },
    readonly() { return !!(this.accident && this.accident.status === 'closed') },
    editable() { return !!(this.inv && this.inv.submit_status !== 'pending') },
    canExport() { return !!this.inv },
    dialogTitle() {
      if (this.readonly) return '调查报告（已结案）'
      return this.inv && this.inv.submit_status === 'pending' ? '调查报告（待审批，只读）' : '调查报告'
    },
    submitText() { return { draft: '草稿', pending: '待审批', approved: '已通过', rejected: '已驳回' }[this.inv && this.inv.submit_status] || '' },
    form() {
      return this.inv || {}
    },
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.id) return
      this.loading = true
      try {
        const r = await getInvestigateDetail(this.row.id)
        if (r.code === 0) {
          this.accident = r.data.accident
          this.inv = r.data.investigation || {
            direct_cause: '', indirect_cause: '', root_cause: '',
            responsible_person: '', responsible_department: '', responsibility_opinion: '', handle_suggestion: '',
            corrective_measures: [], conclusion: '', attachments: [], submit_status: 'draft',
          }
          if (!this.inv.corrective_measures) this.inv.corrective_measures = []
          if (!this.inv.attachments) this.inv.attachments = []
          this.fileList = (this.inv.attachments || []).map(a => ({ name: a.name || '附件', url: a.url }))
          this.timeline = r.data.timeline || []
        }
      } catch (e) {}
      this.loading = false
    },
    onUploadSuccess(res, file) {
      if (res.code === 0 && res.data && res.data.url) {
        this.inv.attachments.push({ name: file.name, url: res.data.url })
      } else {
        this.$message.error(res.msg || '上传失败')
      }
    },
    onUploadRemove(file) {
      const url = file.url || (file.response && file.response.data && file.response.data.url)
      this.inv.attachments = this.inv.attachments.filter(a => a.url !== url)
    },
    onDrivePick(list) {
      list.forEach(f => {
        if (this.inv.attachments.length >= 5) return
        this.inv.attachments.push({ name: f.name, url: f.url })
        this.fileList.push({ name: f.name, url: f.url })
      })
    },
    validate() {
      const f = this.inv
      if (!(f.direct_cause || '').trim()) return '直接原因必填'
      if (!(f.indirect_cause || '').trim()) return '间接原因必填'
      if (!(f.root_cause || '').trim()) return '根本原因必填'
      if (!(f.responsibility_opinion || '').trim()) return '责任认定必填'
      if (!(f.handle_suggestion || '').trim()) return '处理建议必填'
      if (!(f.conclusion || '').trim()) return '调查结论必填'
      return ''
    },
    async saveDraft() {
      this.saving = true
      try {
        const r = await saveInvestigateDraft({ accident_id: this.row.id, ...this.inv })
        if (r.code === 0) { this.$message.success('草稿已保存'); this.$emit('saved') }
      } catch (e) {}
      this.saving = false
    },
    async doSubmit() {
      const msg = this.validate()
      if (msg) { this.$message.error(msg); return }
      this.$confirm('确认提交审批？提交后不可修改。', '提交审批', { type: 'warning' }).then(async () => {
        this.submitting = true
        try {
          // 先保存草稿（确保后端持有最新填写内容），再提交审批（后端提交校验读取的是库中数据）
          await saveInvestigateDraft({ accident_id: this.row.id, ...this.inv })
          const r = await submitInvestigate(this.row.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.handleVisibleChange(false); this.$emit('saved') }
        } catch (e) {}
        this.submitting = false
      }).catch(() => {})
    },
    async doExport() {
      try {
        const r = await exportInvestigate(this.row.id)
        if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
      } catch (e) {}
    },
  },
}
</script>

<style scoped>
.sec-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 8px; }
.sec-text { font-size: 13px; color: #606266; line-height: 1.8; }
</style>
