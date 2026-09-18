<template>
  <el-dialog title="变更设备状态" :visible.sync="dialogVisible" width="500px" @open="resetForm">
    <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small">
      <el-form-item label="当前状态">
        <el-input :value="currentStatusLabel" disabled />
      </el-form-item>
      <el-form-item label="目标状态" prop="status">
        <el-select v-model="form.status" placeholder="请选择目标状态" style="width:100%">
          <el-option v-for="s in targetOptions" :key="s.value" :label="s.label" :value="s.value" />
        </el-select>
        <div class="field-tip" v-if="!targetOptions.length">当前状态不可再变更</div>
      </el-form-item>
      <el-form-item label="变更原因" prop="reason">
        <el-input v-model="form.reason" type="textarea" :rows="3" maxlength="255" show-word-limit placeholder="请输入变更原因" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" :disabled="!targetOptions.length" @click="submit">确认变更</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { changeAssetStatus } from '@/api/deviceAsset'

// 状态流转规则（与后端一致）
const TRANSITIONS = {
  in_use: ['repairing', 'idle', 'scrapped'],
  repairing: ['in_use', 'scrapped'],
  idle: ['in_use', 'scrapped'],
  scrapped: [],
  transferred: ['in_use']
}

export default {
  name: 'AssetStatusDialog',
  props: {
    visible: Boolean,
    asset: { type: Object, default: () => ({}) },
    statusOptions: { type: Array, default: () => [] }
  },
  data() {
    return {
      dialogVisible: this.visible,
      submitting: false,
      form: { status: '', reason: '' },
      rules: {
        status: [{ required: true, message: '请选择目标状态', trigger: 'change' }],
        reason: [{ required: true, message: '请输入变更原因', trigger: 'blur' }]
      }
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  computed: {
    currentStatusLabel() {
      const s = this.statusOptions.find(x => x.value === this.asset.status)
      return s ? s.label : (this.asset.status || '-')
    },
    targetOptions() {
      const keys = TRANSITIONS[this.asset.status] || []
      return this.statusOptions.filter(s => keys.includes(s.value))
    }
  },
  methods: {
    resetForm() {
      this.form = { status: '', reason: '' }
      this.$refs.form && this.$refs.form.clearValidate()
    },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        this.submitting = true
        try {
          await changeAssetStatus(this.asset.id, { status: this.form.status, reason: this.form.reason })
          this.$message.success('状态已变更')
          this.$emit('saved')
          this.dialogVisible = false
        } catch (e) { /* 拦截器已提示 */ }
        this.submitting = false
      })
    }
  }
}
</script>

<style scoped>
.field-tip { color: #909399; font-size: 12px; }
</style>
