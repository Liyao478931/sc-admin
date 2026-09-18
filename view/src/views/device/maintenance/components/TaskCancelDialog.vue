<template>
  <el-dialog title="取消任务" :visible.sync="visible" width="450px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="90px" size="small">
      <el-form-item label="取消原因" prop="cancel_reason">
        <el-input v-model="form.cancel_reason" type="textarea" :rows="3" maxlength="255" placeholder="请填写取消原因" />
      </el-form-item>
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button type="danger" :loading="saving" @click="handleSave">确认取消</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { cancelTask } from '@/api/maintenanceTask'

export default {
  name: 'TaskCancelDialog',
  props: {
    visible: Boolean,
    taskId: { type: Number, default: 0 }
  },
  data() {
    return {
      saving: false,
      form: { cancel_reason: '' },
      rules: { cancel_reason: [{ required: true, message: '请填写取消原因', trigger: 'blur' }] }
    }
  },
  watch: {
    visible(v) { if (v) this.form = { cancel_reason: '' } }
  },
  methods: {
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const r = await cancelTask(this.taskId, { ...this.form })
        if (r.code === 0) { this.$message.success('已取消'); this.$emit('saved') }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
