<template>
  <el-dialog :title="isEdit ? '编辑事故' : '新增事故'" :visible="visible" width="850px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="110px" size="small">
      <el-divider content-position="left">基本信息</el-divider>
      <el-form-item label="事故名称" prop="accident_name">
        <el-input v-model="form.accident_name" placeholder="请输入事故名称" maxlength="200" />
      </el-form-item>
      <el-form-item label="事故类型" prop="accident_type">
        <el-select v-model="form.accident_type" placeholder="请选择事故类型" style="width:220px">
          <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="事故等级" prop="accident_level">
        <el-select v-model="form.accident_level" placeholder="请选择事故等级" style="width:220px">
          <el-option v-for="l in levelOptions" :key="l.value" :label="l.label" :value="l.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="发生时间" prop="happen_time">
        <el-date-picker v-model="form.happen_time" type="datetime" placeholder="选择发生时间" style="width:260px" />
      </el-form-item>
      <el-form-item label="发生地点" prop="happen_location">
        <el-input v-model="form.happen_location" placeholder="请输入发生地点" maxlength="200" />
      </el-form-item>
      <el-form-item label="发生部门" prop="happen_department">
        <el-select v-model="form.happen_department" placeholder="请选择发生部门" style="width:260px">
          <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
      </el-form-item>

      <el-divider content-position="left">事故经过与原因</el-divider>
      <el-form-item label="事故经过" prop="accident_process">
        <el-input v-model="form.accident_process" type="textarea" :rows="4" placeholder="详细描述事故经过（不少于20字符）" maxlength="5000" show-word-limit />
      </el-form-item>
      <el-form-item label="事故原因" prop="accident_cause">
        <el-input v-model="form.accident_cause" type="textarea" :rows="3" placeholder="初步分析事故原因（不少于10字符）" maxlength="3000" show-word-limit />
      </el-form-item>

      <el-divider content-position="left">伤亡与经济</el-divider>
      <el-form-item label="伤亡情况">
        <span style="margin-right:10px;">死亡</span><el-input-number v-model="form.death_count" :min="0" size="small" />
        <span style="margin:0 10px 0 20px;">重伤</span><el-input-number v-model="form.serious_injury_count" :min="0" size="small" />
        <span style="margin:0 10px 0 20px;">轻伤</span><el-input-number v-model="form.minor_injury_count" :min="0" size="small" />
      </el-form-item>
      <el-form-item label="经济损失">
        <el-input-number v-model="form.economic_loss" :min="0" :precision="2" :step="1" /> <span style="color:#909399;">万元</span>
      </el-form-item>

      <el-divider content-position="left">责任人信息</el-divider>
      <el-form-item label="责任人">
        <div style="display:flex;gap:8px;align-items:center;width:100%;">
          <el-input v-model="form.responsible_person" placeholder="责任人姓名" style="width:200px" maxlength="50" />
          <el-select v-model="responsibleUserId" filterable remote :remote-method="searchResponsible" :loading="respLoading"
            placeholder="从员工档案选择" clearable style="width:240px" @change="onResponsibleSelect">
            <el-option v-for="p in responsibleOptions" :key="p.id" :label="`${p.name}（${deptName(p)} ${posName(p)}）`" :value="p.id" />
          </el-select>
        </div>
      </el-form-item>
      <el-form-item label="责任人部门">
        <el-input v-model="form.responsible_department" placeholder="选填（选择员工后自动填充）" style="width:260px" maxlength="100" />
      </el-form-item>
      <el-form-item label="责任人岗位">
        <el-input v-model="form.responsible_position" placeholder="选填（选择员工后自动填充）" style="width:260px" maxlength="100" />
      </el-form-item>
      <el-form-item label="处理意见">
        <el-input v-model="form.handle_opinion" type="textarea" :rows="2" placeholder="选填" maxlength="500" />
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
        <div style="color:#909399;font-size:12px;line-height:1.6;">支持事故现场照片（图片，单个≤20MB）；报告文件暂不支持上传</div>
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
import { addAccident, editAccident, getResponsibleCandidates } from '@/api/safetyAccident'
import { getToken } from '@/utils/auth'

export default {
  name: 'AccidentFormDialog',
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
      saving: false, fileList: [], driveVisible: false,
      responsibleUserId: null, responsibleOptions: [], respLoading: false,
      form: {
        accident_name: '', accident_type: '', accident_level: '', happen_time: '', happen_location: '',
        happen_department: null, accident_process: '', accident_cause: '',
        death_count: 0, serious_injury_count: 0, minor_injury_count: 0, economic_loss: 0,
        responsible_person: '', responsible_department: '', responsible_position: '', handle_opinion: '',
        attachments: [], remark: '',
      },
      rules: {
        accident_name: [{ required: true, message: '请输入事故名称', trigger: 'blur' }],
        accident_type: [{ required: true, message: '请选择事故类型', trigger: 'change' }],
        accident_level: [{ required: true, message: '请选择事故等级', trigger: 'change' }],
        happen_time: [{ required: true, message: '请选择发生时间', trigger: 'change' }],
        happen_location: [{ required: true, message: '请输入发生地点', trigger: 'blur' }],
        happen_department: [{ required: true, message: '请选择发生部门', trigger: 'change' }],
        accident_process: [{ required: true, message: '请输入事故经过', trigger: 'blur' }],
        accident_cause: [{ required: true, message: '请输入事故原因', trigger: 'blur' }],
      },
    }
  },
  watch: {
    visible(val) { if (val) this.init() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    init() {
      this.fileList = []
      this.responsibleUserId = null
      this.searchResponsible('')
      if (this.isEdit) {
        const r = this.row
        this.form = {
          accident_name: r.accident_name, accident_type: r.accident_type, accident_level: r.accident_level,
          happen_time: r.happen_time, happen_location: r.happen_location, happen_department: r.happen_department,
          accident_process: r.accident_process, accident_cause: r.accident_cause,
          death_count: r.death_count, serious_injury_count: r.serious_injury_count, minor_injury_count: r.minor_injury_count,
          economic_loss: Number(r.economic_loss) || 0,
          responsible_person: r.responsible_person || '', responsible_department: r.responsible_department || '',
          responsible_position: r.responsible_position || '', handle_opinion: r.handle_opinion || '',
          attachments: Array.isArray(r.attachments) ? r.attachments : [], remark: r.remark || '',
        }
        this.fileList = (r.attachments || []).map(a => ({ name: a.name, url: a.url }))
      } else {
        this.form = {
          accident_name: '', accident_type: '', accident_level: '', happen_time: '', happen_location: '',
          happen_department: null, accident_process: '', accident_cause: '',
          death_count: 0, serious_injury_count: 0, minor_injury_count: 0, economic_loss: 0,
          responsible_person: '', responsible_department: '', responsible_position: '', handle_opinion: '',
          attachments: [], remark: '',
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
    deptName(p) { return (p.department && p.department.name) || '' },
    posName(p) { return (p.position && p.position.name) || '' },
    async searchResponsible(keyword) {
      this.respLoading = true
      try {
        const r = await getResponsibleCandidates(keyword || '')
        this.responsibleOptions = (r.data && r.data.list) || []
      } catch (e) {}
      this.respLoading = false
    },
    onResponsibleSelect(id) {
      const p = this.responsibleOptions.find(x => x.id === id)
      if (!p) return
      this.form.responsible_person = p.name || ''
      this.form.responsible_department = this.deptName(p)
      this.form.responsible_position = this.posName(p)
    },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        if ((this.form.accident_process || '').trim().length < 20) { this.$message.error('事故经过不少于20字符'); return }
        if ((this.form.accident_cause || '').trim().length < 10) { this.$message.error('事故原因不少于10字符'); return }
        this.saving = true
        try {
          const payload = { ...this.form }
          const r = this.isEdit
            ? await editAccident(this.row.id, payload)
            : await addAccident(payload)
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
