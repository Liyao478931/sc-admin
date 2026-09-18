<template>
  <el-dialog title="调班换班" :visible="visible" @update:visible="$emit('update:visible', $event)" width="520px" top="8vh" @open="onOpen">
    <el-form label-width="100px" size="small">
      <el-form-item label="员工A">
        <el-select v-model="employeeA" filterable placeholder="请选择员工A" style="width:100%" @change="querySwapInfo">
          <el-option v-for="e in empOptions" :key="e.id" :label="e.name + '（' + (e.employee_id || '') + '）'" :value="e.id" />
        </el-select>
        <div v-if="aShiftText" class="cur-shift">当前班次：{{ aShiftText }}</div>
      </el-form-item>
      <el-form-item label="员工B">
        <el-select v-model="employeeB" filterable placeholder="请选择员工B" style="width:100%" @change="querySwapInfo">
          <el-option v-for="e in empOptions" :key="e.id" :label="e.name + '（' + (e.employee_id || '') + '）'" :value="e.id" />
        </el-select>
        <div v-if="bShiftText" class="cur-shift">当前班次：{{ bShiftText }}</div>
      </el-form-item>
      <el-form-item label="调班日期">
        <el-date-picker v-model="swapDate" type="date" value-format="yyyy-MM-dd" placeholder="选择日期" style="width:100%" @change="querySwapInfo" />
      </el-form-item>
      <el-form-item label="调班原因"><el-input v-model="reason" maxlength="255" placeholder="选填" /></el-form-item>
      <el-alert v-if="swapHint" :title="swapHint" type="warning" :closable="false" show-icon style="margin-bottom:8px;" />
    </el-form>
    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认调班</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getScheduleEmployees, getEmployeeScheduleList, swapSchedule } from '@/api/attendanceSchedule'

export default {
  name: 'ScheduleSwapDialog',
  props: { visible: { type: Boolean, default: false } },
  data () {
    return { empOptions: [], employeeA: '', employeeB: '', swapDate: '', reason: '', saving: false, aShiftText: '', bShiftText: '', swapHint: '' }
  },
  methods: {
    async onOpen () {
      this.employeeA = ''; this.employeeB = ''; this.swapDate = ''; this.reason = ''; this.aShiftText = ''; this.bShiftText = ''; this.swapHint = ''
      try {
        const r = await getScheduleEmployees({})
        if (r.code === 0) this.empOptions = r.data || []
      } catch (e) {}
    },
    async querySwapInfo () {
      this.aShiftText = ''; this.bShiftText = ''; this.swapHint = ''
      if (!this.swapDate) return
      if (this.employeeA) this.aShiftText = await this.getShiftText(this.employeeA)
      if (this.employeeB) this.bShiftText = await this.getShiftText(this.employeeB)
      if (this.employeeA && this.employeeB && (!this.aShiftText || !this.bShiftText)) {
        this.swapHint = '调班日期两位员工均需有排班'
      }
    },
    async getShiftText (empId) {
      try {
        const r = await getEmployeeScheduleList({ employee_id: empId, start_date: this.swapDate, end_date: this.swapDate })
        const list = (r.data || []).filter(x => x.schedule_date === this.swapDate)
        return list.length ? (list[0].shift_name || '休息') : ''
      } catch (e) { return '' }
    },
    async submit () {
      if (!this.employeeA || !this.employeeB) { this.$message.warning('请选择两位员工'); return }
      if (!this.swapDate) { this.$message.warning('请选择调班日期'); return }
      this.saving = true
      try {
        const r = await swapSchedule({ employee_a_id: this.employeeA, employee_b_id: this.employeeB, swap_date: this.swapDate, reason: this.reason })
        if (r.code === 0) { this.$message.success('调班成功'); this.$emit('update:visible', false); this.$emit('saved') }
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.cur-shift { font-size: 12px; color: #909399; margin-top: 4px; }
</style>
