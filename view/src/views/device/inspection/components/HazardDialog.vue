<template>
  <el-dialog title="隐患处理" :visible.sync="dialogVisible" width="600px" @open="handleOpen">
    <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
      <el-form-item label="设备名称"><el-input :value="hz.device_name" disabled /></el-form-item>
      <el-form-item label="隐患描述"><el-input :value="hz.hazard_desc" type="textarea" :rows="2" disabled /></el-form-item>
      <el-form-item label="严重程度">
        <el-select v-model="form.severity" style="width:100%">
          <el-option v-for="s in severityOptions" :key="s.value" :label="s.label" :value="s.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="处理人">
        <el-select v-model="form.handler_id" filterable style="width:100%">
          <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="处理措施" prop="handle_measure"><el-input v-model="form.handle_measure" type="textarea" :rows="2" /></el-form-item>
      <el-form-item label="处理结果"><el-input v-model="form.handle_result" type="textarea" :rows="2" /></el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getHazardDetail, handleHazard, closeHazard } from '@/api/deviceInspection'
import { getManagers } from '@/api/deviceAsset'
import { getDictionaryBatch } from '@/utils/dict'

export default {
  name: 'InspectionHazardDialog',
  props: { visible: Boolean, hazardId: { type: Number, default: 0 } },
  data() {
    return {
      dialogVisible: this.visible, submitting: false,
      hz: {}, severityOptions: [], managerList: [],
      form: { severity: 'general', handler_id: null, handle_measure: '', handle_result: '' },
      rules: { handle_measure: [{ required: true, message: '请填写处理措施', trigger: 'blur' }] }
    }
  },
  watch: { visible(val) { this.dialogVisible = val } },
  methods: {
    async handleOpen() {
      this.form = { severity: 'general', handler_id: null, handle_measure: '', handle_result: '' }
      try {
        const dict = await getDictionaryBatch(['hazard_severity'])
        this.severityOptions = dict['hazard_severity'] || []
        const m = await getManagers()
        this.managerList = m.data || []
        if (this.hazardId) {
          const res = await getHazardDetail(this.hazardId)
          if (res.code === 0) { this.hz = res.data; this.form.severity = res.data.severity || 'general' }
        }
      } catch (e) {}
    },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        this.submitting = true
        try {
          if (this.form.handle_result) {
            // 有处理结果 → 处理并关闭
            await handleHazard(this.hazardId, this.form)
            await closeHazard(this.hazardId, { handle_result: this.form.handle_result })
            this.$message.success('已处理并关闭')
          } else {
            await handleHazard(this.hazardId, this.form)
            this.$message.success('已处理')
          }
          this.$emit('saved')
          this.dialogVisible = false
        } catch (e) { /* 拦截器已提示 */ }
        this.submitting = false
      })
    }
  }
}
</script>
