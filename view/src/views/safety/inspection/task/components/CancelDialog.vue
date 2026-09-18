<template>
  <el-dialog title="取消任务" :visible.sync="dialogVisible" width="450px" append-to-body>
    <el-form :model="form" :rules="rules" ref="formRef" label-width="90px" size="small">
      <el-form-item label="任务编号">
        <el-input :value="row ? row.task_code : ''" disabled />
      </el-form-item>
      <el-form-item label="取消原因" prop="cancel_reason">
        <el-input v-model="form.cancel_reason" type="textarea" :rows="3" maxlength="255" show-word-limit placeholder="请填写取消原因（必填）" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="danger" :loading="saving" @click="submit">确认取消</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { cancelTask } from '@/api/safetyInspectionTask'

export default {
  name: 'TaskCancelDialog',
  props: {
    visible: Boolean,
    row: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      dialogVisible: this.visible,
      saving: false,
      form: { cancel_reason: '' },
      rules: { cancel_reason: [{ required: true, message: '请填写取消原因', trigger: 'blur' }] },
    }
  },
  watch: {
    visible(val) {
      this.dialogVisible = val
      if (val) this.form = { cancel_reason: '' }
    },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    submit() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await cancelTask(this.row.id, this.form.cancel_reason)
          if (r.code === 0) { this.$message.success(r.msg || '任务已取消'); this.dialogVisible = false; this.$emit('saved') }
        } catch (e) {}
        this.saving = false
      })
    },
  },
}
</script>
