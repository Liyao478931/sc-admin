<template>
  <el-dialog :title="mode === 'accept' ? '验收通过' : '验收驳回'" :visible.sync="visible" width="500px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="100px" size="small">
      <el-form-item :label="mode === 'accept' ? '验收意见' : '驳回原因'" :prop="mode === 'accept' ? 'accept_remark' : 'reject_reason'">
        <el-input v-model="form[mode === 'accept' ? 'accept_remark' : 'reject_reason']" type="textarea" :rows="3" maxlength="255"
          :placeholder="mode === 'accept' ? '请填写验收意见（至少10字）' : '请填写驳回原因（至少10字）'" />
      </el-form-item>
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button v-if="mode === 'accept'" type="success" :loading="saving" @click="handleSave">确认通过</el-button>
      <el-button v-else type="danger" :loading="saving" @click="handleSave">确认驳回</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { acceptOrder, rejectOrder } from '@/api/repairOrder'

export default {
  name: 'OrderAcceptDialog',
  props: {
    visible: Boolean,
    orderId: { type: Number, default: 0 },
    mode: { type: String, default: 'accept' }
  },
  data() {
    return {
      saving: false,
      form: { accept_remark: '', reject_reason: '' },
      rules: {}
    }
  },
  watch: {
    visible(v) {
      if (v) {
        this.form = { accept_remark: '', reject_reason: '' }
        this.rules = this.mode === 'accept'
          ? { accept_remark: [{ required: true, min: 10, message: '验收意见至少10字', trigger: 'blur' }] }
          : { reject_reason: [{ required: true, min: 10, message: '驳回原因至少10字', trigger: 'blur' }] }
      }
    }
  },
  methods: {
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const r = this.mode === 'accept'
          ? await acceptOrder(this.orderId, { accept_remark: this.form.accept_remark })
          : await rejectOrder(this.orderId, { reject_reason: this.form.reject_reason })
        if (r.code === 0) { this.$message.success(this.mode === 'accept' ? '验收通过' : '已驳回'); this.$emit('saved'); this.visible = false }
        else this.$message.error(r.msg || '操作失败')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
