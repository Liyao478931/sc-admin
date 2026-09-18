<template>
  <el-dialog :title="isEdit ? '编辑风险' : '新增风险'" :visible="visible" width="850px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="120px" size="small">
      <el-divider content-position="left">基本信息</el-divider>
      <el-form-item label="风险名称" prop="risk_name">
        <el-input v-model="form.risk_name" placeholder="请输入风险名称" maxlength="200" />
      </el-form-item>
      <el-form-item label="风险类型" prop="risk_type">
        <el-select v-model="form.risk_type" placeholder="请选择风险类型" style="width:220px">
          <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="风险等级" prop="risk_level">
        <el-select v-model="form.risk_level" placeholder="请选择风险等级" style="width:220px">
          <el-option v-for="l in levelOptions" :key="l.value" :label="l.label" :value="l.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="所属区域" prop="area">
        <el-input v-model="form.area" placeholder="请输入所属区域" maxlength="200" />
      </el-form-item>
      <el-form-item label="所属部门" prop="department_id">
        <el-select v-model="form.department_id" placeholder="请选择所属部门" style="width:260px">
          <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="责任人" prop="responsible_person_id">
        <el-select v-model="form.responsible_person_id" filterable remote :remote-method="searchPersons" :loading="respLoading" placeholder="输入姓名从员工档案选择" style="width:280px">
          <el-option v-for="p in personOptions" :key="p.user_id || p.id" :label="`${p.name || '员工'}（${deptName(p)} ${posName(p)}）`" :value="p.user_id || p.id" />
        </el-select>
      </el-form-item>

      <el-divider content-position="left">危险源信息</el-divider>
      <el-form-item label="危险源描述" prop="hazard_source">
        <el-input v-model="form.hazard_source" type="textarea" :rows="3" placeholder="请详细描述危险源（至少20字）" maxlength="2000" show-word-limit />
      </el-form-item>
      <el-form-item label="可能导致的后果" prop="consequence">
        <el-input v-model="form.consequence" type="textarea" :rows="3" placeholder="请描述可能导致的后果（至少20字）" maxlength="2000" show-word-limit />
      </el-form-item>
      <el-form-item label="影响范围">
        <el-input v-model="form.impact_scope" placeholder="请输入影响范围" maxlength="500" />
      </el-form-item>

      <el-divider content-position="left">现有控制措施</el-divider>
      <el-form-item label="现有控制措施">
        <el-input v-model="form.current_controls" type="textarea" :rows="2" placeholder="选填" maxlength="2000" />
      </el-form-item>
      <el-form-item label="控制措施有效性">
        <el-select v-model="form.control_effectiveness" clearable placeholder="选填" style="width:180px">
          <el-option label="有效" value="effective" /><el-option label="部分有效" value="partial" /><el-option label="无效" value="ineffective" />
        </el-select>
      </el-form-item>

      <el-divider content-position="left">辨识信息</el-divider>
      <el-form-item label="辨识日期">
        <el-date-picker v-model="form.identify_date" type="date" value-format="yyyy-MM-dd" style="width:180px" />
      </el-form-item>

      <el-divider content-position="left">附件与备注</el-divider>
      <el-form-item label="附件上传">
        <el-upload action="/api/upload" :headers="uploadHeaders" list-type="picture-card" :limit="9" :file-list="fileList"
          :on-success="onUploadSuccess" :on-remove="onUploadRemove" accept="image/*">
          <i class="el-icon-plus" />
        </el-upload>
        <div style="margin-top:6px">
          <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
        </div>
        <drive-file-picker :visible="driveVisible" mode="image" :multiple="true" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
        <div style="color:#909399;font-size:12px;">支持照片/图片（单个≤20MB）；其他文件暂不支持</div>
      </el-form-item>
      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="选填" maxlength="1000" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="handleSave">提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addRisk, editRisk, getResponsibleCandidates } from '@/api/safetyRisk'
import { getToken } from '@/utils/auth'

export default {
  name: 'RiskFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
    typeOptions: { type: Array, default: () => [] },
    levelOptions: { type: Array, default: () => [] },
    deptOptions: { type: Array, default: () => [] },
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    uploadHeaders() { return { Authorization: 'Bearer ' + (getToken() || '') } },
  },
  data() {
    return {
      saving: false, fileList: [], personOptions: [], respLoading: false, driveVisible: false,
      form: {
        risk_name: '', risk_type: '', risk_level: 'low', area: '', department_id: null,
        responsible_person_id: null, hazard_source: '', consequence: '', impact_scope: '',
        current_controls: '', control_effectiveness: '', identify_date: this.today(), attachments: [], remark: '',
      },
      rules: {
        risk_name: [{ required: true, message: '请输入风险名称', trigger: 'blur' }],
        risk_type: [{ required: true, message: '请选择风险类型', trigger: 'change' }],
        area: [{ required: true, message: '请输入所属区域', trigger: 'blur' }],
        department_id: [{ required: true, message: '请选择所属部门', trigger: 'change' }],
        responsible_person_id: [{ required: true, message: '请选择责任人', trigger: 'change' }],
        hazard_source: [{ required: true, message: '请输入危险源描述', trigger: 'blur' }],
        consequence: [{ required: true, message: '请输入可能导致的后果', trigger: 'blur' }],
      },
    }
  },
  watch: {
    visible(val) { if (val) this.init() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    today() {
      const d = new Date()
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
    },
    deptName(p) { return (p.department && p.department.name) || '' },
    posName(p) { return (p.position && p.position.name) || '' },
    async searchPersons(keyword) {
      this.respLoading = true
      try {
        const r = await getResponsibleCandidates(keyword || '')
        this.personOptions = (r.data && r.data.list) || []
      } catch (e) {}
      this.respLoading = false
    },
    init() {
      this.fileList = []
      this.searchPersons('')
      if (this.isEdit) {
        const r = this.row
        this.form = {
          risk_name: r.risk_name, risk_type: r.risk_type, risk_level: r.risk_level || 'low', area: r.area,
          department_id: r.department_id, responsible_person_id: r.responsible_person_id,
          hazard_source: r.hazard_source, consequence: r.consequence, impact_scope: r.impact_scope || '',
          current_controls: r.current_controls || '', control_effectiveness: r.control_effectiveness || '',
          identify_date: r.identify_date, attachments: Array.isArray(r.attachments) ? r.attachments : [], remark: r.remark || '',
        }
        this.fileList = (r.attachments || []).map(a => ({ name: a.name || '附件', url: a.url }))
      } else {
        this.form = {
          risk_name: '', risk_type: '', risk_level: 'low', area: '', department_id: null,
          responsible_person_id: null, hazard_source: '', consequence: '', impact_scope: '',
          current_controls: '', control_effectiveness: '', identify_date: this.today(), attachments: [], remark: '',
        }
      }
      this.$nextTick(() => { if (this.$refs.formRef) this.$refs.formRef.clearValidate() })
    },
    onUploadSuccess(res, file) {
      if (res.code === 0 && res.data && res.data.url) {
        this.form.attachments.push({ name: file.name, url: res.data.url })
      } else {
        this.$message.error(res.msg || '上传失败')
      }
    },
    onUploadRemove(file) {
      const url = file.url || (file.response && file.response.data && file.response.data.url)
      this.form.attachments = this.form.attachments.filter(a => a.url !== url)
    },
    onDrivePick(list) {
      list.forEach(f => {
        if (this.form.attachments.length >= 9) return
        this.form.attachments.push({ name: f.name, url: f.url })
        this.fileList.push({ name: f.name, url: f.url })
      })
    },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        if ((this.form.hazard_source || '').trim().length < 20) { this.$message.error('危险源描述不少于20字符'); return }
        if ((this.form.consequence || '').trim().length < 20) { this.$message.error('可能导致的后果不少于20字符'); return }
        this.saving = true
        try {
          const r = this.isEdit
            ? await editRisk(this.row.id, this.form)
            : await addRisk(this.form)
          if (r.code === 0) {
            this.$message.success(this.isEdit ? '保存成功' : '新增成功')
            this.handleVisibleChange(false)
            this.$emit('saved')
          }
        } catch (e) {}
        this.saving = false
      })
    },
  },
}
</script>
