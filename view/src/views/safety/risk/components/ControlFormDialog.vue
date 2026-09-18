<template>
  <el-dialog :title="isEdit ? '编辑措施' : '新增措施'" :visible="visible" width="700px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="110px" size="small">
      <el-form-item label="选择风险点" prop="risk_id">
        <el-select v-model="form.risk_id" placeholder="请选择已评估的风险" style="width:100%;" :disabled="isEdit">
          <el-option v-for="r in riskOptions" :key="r.id" :label="`${r.risk_name}（${r.risk_level_text}）`" :value="r.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="措施类型" prop="measure_type">
        <el-select v-model="form.measure_type" placeholder="请选择措施类型" style="width:220px" :disabled="isInProgress">
          <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="措施内容" prop="measure_content">
        <el-input v-model="form.measure_content" type="textarea" :rows="3" placeholder="请详细描述管控措施（至少20字）" maxlength="2000" show-word-limit :disabled="isInProgress" />
      </el-form-item>
      <el-form-item label="责任人" prop="responsible_person_id">
        <el-select v-model="form.responsible_person_id" filterable :filter-method="searchPersons" placeholder="请选择责任人" style="width:280px">
          <el-option v-for="p in personOptions" :key="p.user_id || p.id" :label="`${p.name || '员工'}（${deptName(p)} ${posName(p)}）`" :value="p.user_id || p.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="完成期限" prop="deadline">
        <el-date-picker v-model="form.deadline" type="date" value-format="yyyy-MM-dd" :picker-options="{ disabledDate: d => d.getTime() < Date.now() - 86400000 }" style="width:180px;" />
      </el-form-item>
      <el-form-item v-if="isInProgress" label="进度备注">
        <el-input v-model="form.progress_remark" type="textarea" :rows="2" maxlength="500" placeholder="填写实施进度备注（实施中可修改）" />
      </el-form-item>
      <el-form-item label="备注" v-if="!isInProgress">
        <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="1000" placeholder="选填" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="handleSave">提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addControl, editControl, getResponsibleCandidates } from '@/api/safetyRisk'

export default {
  name: 'ControlFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
    typeOptions: { type: Array, default: () => [] },
    riskOptions: { type: Array, default: () => [] },
    personOptions: { type: Array, default: () => [] },
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    isInProgress() { return !!(this.row && this.row.implement_status === 'in_progress') },
  },
  data() {
    return {
      saving: false,
      form: { risk_id: null, measure_type: '', measure_content: '', responsible_person_id: null, deadline: '', progress_remark: '', remark: '' },
      rules: {
        risk_id: [{ required: true, message: '请选择风险点', trigger: 'change' }],
        measure_type: [{ required: true, message: '请选择措施类型', trigger: 'change' }],
        measure_content: [{ required: true, message: '请输入措施内容', trigger: 'blur' }],
        responsible_person_id: [{ required: true, message: '请选择责任人', trigger: 'change' }],
        deadline: [{ required: true, message: '请选择完成期限', trigger: 'change' }],
      },
    }
  },
  watch: {
    visible(val) { if (val) this.init() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    deptName(p) { return (p.department && p.department.name) || '' },
    posName(p) { return (p.position && p.position.name) || '' },
    async searchPersons(keyword) {
      try {
        const r = await getResponsibleCandidates(keyword || '')
        if (keyword) this.$emit('update:personOptions', (r.data && r.data.list) || [])
      } catch (e) {}
    },
    init() {
      if (this.isEdit) {
        this.form = {
          risk_id: this.row.risk_id, measure_type: this.row.measure_type, measure_content: this.row.measure_content,
          responsible_person_id: this.row.responsible_person_id, deadline: this.row.deadline,
          progress_remark: this.row.progress_remark || '', remark: this.row.remark || '',
        }
      } else {
        this.form = { risk_id: null, measure_type: '', measure_content: '', responsible_person_id: null, deadline: '', progress_remark: '', remark: '' }
      }
      this.$nextTick(() => { if (this.$refs.formRef) this.$refs.formRef.clearValidate() })
    },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        if ((this.form.measure_content || '').trim().length < 20) { this.$message.error('措施内容不少于20字符'); return }
        this.saving = true
        try {
          const r = this.isEdit
            ? await editControl(this.row.id, this.form)
            : await addControl(this.form)
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
