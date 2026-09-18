<template>
  <el-dialog title="验证措施" :visible="visible" width="550px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form label-width="110px" size="small">
      <el-form-item label="措施">
        <span style="font-size:13px;color:#606266;">{{ row ? row.measure_code : '' }}（{{ row ? row.risk_name : '' }}）</span>
      </el-form-item>
      <el-form-item label="验证结果" required>
        <el-radio-group v-model="status">
          <el-radio v-for="opt in verifyOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio>
        </el-radio-group>
        <div style="color:#909399;font-size:12px;line-height:1.6;">验证有效：风险等级将下调一级；验证无效：需重新制定措施。</div>
      </el-form-item>
      <el-form-item label="验证意见" required>
        <el-input v-model="opinion" type="textarea" :rows="3" placeholder="请填写验证意见" maxlength="500" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" :type="status === 'effective' ? 'success' : 'danger'" :loading="saving" @click="submit">确认验证</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { verifyControl } from '@/api/safetyRisk'

export default {
  name: 'ControlVerifyDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { status: 'effective', opinion: '', saving: false, verifyOptions: [] }
  },
  watch: {
    visible(val) { if (val) { this.status = 'effective'; this.opinion = ''; this.loadDicts() } },
  },
  methods: {
    // 验证结果从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('control_verify_status'); this.verifyOptions = r.data || [] } catch (e) { this.verifyOptions = [] }
    },
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async submit() {
      if (!this.opinion.trim()) { this.$message.warning('请填写验证意见'); return }
      this.saving = true
      try {
        const r = await verifyControl(this.row.id, this.status, this.opinion)
        if (r.code === 0) {
          this.$message.success('验证完成')
          this.handleVisibleChange(false)
          this.$emit('saved')
        }
      } catch (e) {}
      this.saving = false
    },
  },
}
</script>
