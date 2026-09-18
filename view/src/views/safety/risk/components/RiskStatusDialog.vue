<template>
  <el-dialog title="变更风险状态" :visible="visible" width="450px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form label-width="100px" size="small">
      <el-form-item label="当前状态">
        <el-tag size="mini" :type="statusTag(row && row.status)">{{ row ? row.status_text : '' }}</el-tag>
      </el-form-item>
      <el-form-item label="目标状态" required>
        <el-select v-model="target" placeholder="请选择目标状态" style="width:240px">
          <el-option v-for="o in targetOptions" :key="o.value" :label="o.label" :value="o.value" />
        </el-select>
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认变更</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { changeRiskStatus } from '@/api/safetyRisk'

export default {
  name: 'RiskStatusDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { target: '', saving: false }
  },
  computed: {
    targetOptions() {
      const map = {
        pending: [{ label: '已评估', value: 'assessed' }],
        assessed: [{ label: '已管控', value: 'controlled' }],
        controlled: [],
      }
      return map[this.row && this.row.status] || []
    },
  },
  watch: {
    visible(val) { if (val) this.target = '' },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    statusTag(s) { return { pending: 'warning', assessed: 'success', controlled: '' }[s] || 'info' },
    async submit() {
      if (!this.target) { this.$message.warning('请选择目标状态'); return }
      this.saving = true
      try {
        const r = await changeRiskStatus(this.row.id, this.target)
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
