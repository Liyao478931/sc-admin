<template>
  <el-dialog title="事故状态变更" :visible="visible" width="480px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form label-width="100px" size="small">
      <el-form-item label="当前状态">
        <el-tag size="mini" :type="statusTag(row && row.status)">{{ row ? row.status_text : '' }}</el-tag>
      </el-form-item>
      <el-form-item label="目标状态" required>
        <el-select v-model="target" placeholder="请选择目标状态" style="width:260px">
          <el-option v-for="o in targetOptions" :key="o.value" :label="o.label" :value="o.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="变更原因">
        <el-input v-model="reason" type="textarea" :rows="2" placeholder="选填" maxlength="200" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认变更</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { changeAccidentStatus } from '@/api/safetyAccident'

export default {
  name: 'AccidentStatusDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { target: '', reason: '', saving: false }
  },
  computed: {
    targetOptions() {
      const map = {
        pending: [{ label: '调查中', value: 'investigating' }],
        investigating: [{ label: '已结案', value: 'closed' }],
        closed: [{ label: '已归档', value: 'archived' }],
        archived: [],
      }
      return map[this.row && this.row.status] || []
    },
  },
  watch: {
    visible(val) { if (val) { this.target = ''; this.reason = '' } },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    statusTag(s) { return { pending: 'warning', investigating: '', closed: 'success', archived: 'info' }[s] || 'info' },
    async submit() {
      if (!this.target) { this.$message.warning('请选择目标状态'); return }
      this.saving = true
      try {
        const r = await changeAccidentStatus(this.row.id, this.target, this.reason)
        if (r.code === 0) {
          this.$message.success('状态已更新')
          this.handleVisibleChange(false)
          this.$emit('saved')
        }
      } catch (e) {}
      this.saving = false
    },
  },
}
</script>
