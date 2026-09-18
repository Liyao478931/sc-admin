<template>
  <el-dialog title="分配调查人" :visible="visible" width="500px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form label-width="100px" size="small">
      <el-form-item label="事故">
        <span style="font-size:13px;color:#606266;">{{ row ? row.accident_name : '' }}</span>
      </el-form-item>
      <el-form-item label="调查人" required>
        <el-select v-model="investigatorId" filterable remote :remote-method="searchUsers" :loading="loading" placeholder="输入姓名从员工档案选择" style="width:280px">
          <el-option v-for="u in userOptions" :key="u.user_id || u.id" :label="`${u.name || '员工'}（${deptName(u)} ${posName(u)}）`" :value="u.user_id || u.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="调查期限">
        <el-date-picker v-model="deadline" type="date" value-format="yyyy-MM-dd" placeholder="默认15天" style="width:200px" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认分配</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { assignInvestigator, getResponsibleCandidates } from '@/api/safetyAccident'

export default {
  name: 'InvestigateAssignDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { investigatorId: null, deadline: '', userOptions: [], loading: false, saving: false }
  },
  watch: {
    visible(val) {
      if (val) {
        this.investigatorId = null
        this.deadline = this.futureDate(15)
        this.searchUsers('')
      }
    },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    futureDate(days) {
      const d = new Date(Date.now() + days * 86400000)
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
    },
    deptName(u) { return (u.department && u.department.name) || '' },
    posName(u) { return (u.position && u.position.name) || '' },
    async searchUsers(keyword) {
      this.loading = true
      try {
        const r = await getResponsibleCandidates(keyword || '')
        this.userOptions = (r.data && r.data.list) || []
      } catch (e) {}
      this.loading = false
    },
    async submit() {
      if (!this.investigatorId) { this.$message.warning('请选择调查人'); return }
      this.saving = true
      try {
        const r = await assignInvestigator({ accident_id: this.row.id, investigator_id: this.investigatorId, investigation_deadline: this.deadline })
        if (r.code === 0) {
          this.$message.success('分配成功，事故已进入调查中')
          this.handleVisibleChange(false)
          this.$emit('saved')
        }
      } catch (e) {}
      this.saving = false
    },
  },
}
</script>
