<template>
  <el-dialog title="批量排班" :visible="visible" @update:visible="$emit('update:visible', $event)" width="560px" top="8vh" @open="onOpen">
    <el-form label-width="100px" size="small">
      <el-form-item label="排班方式">
        <el-radio-group v-model="mode">
          <el-radio label="dept">按部门排班</el-radio>
          <el-radio label="employee">按员工排班</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item v-if="mode === 'dept'" label="选择部门">
        <el-select v-model="departmentId" filterable placeholder="请选择部门" style="width:100%">
          <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-else label="选择员工">
        <el-select v-model="employeeIds" multiple filterable collapse-tags placeholder="请选择员工" style="width:100%">
          <el-option v-for="e in empOptions" :key="e.id" :label="e.name + '（' + (e.employee_id || '') + '）'" :value="e.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="选择班次">
        <el-select v-model="shiftId" filterable placeholder="请选择班次" style="width:100%">
          <el-option v-for="s in shiftOptions" :key="s.id" :label="s.shift_name + '（' + s.shift_code + '）'" :value="s.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="日期范围">
        <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" style="width:100%" />
      </el-form-item>
      <el-form-item label="覆盖已有">
        <el-switch v-model="override" :active-value="true" :inactive-value="false" active-text="覆盖" inactive-text="跳过" />
        <span class="tip">关闭则跳过已有排班的日期</span>
      </el-form-item>
      <el-form-item label="备注"><el-input v-model="remark" maxlength="255" /></el-form-item>
    </el-form>
    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认排班</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getShiftOptions } from '@/api/attendanceShift'
import { getDeptTree } from '@/api/organization'
import { getScheduleEmployees, batchSetSchedule, batchSetScheduleByDept } from '@/api/attendanceSchedule'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'ScheduleBatchDialog',
  props: { visible: { type: Boolean, default: false } },
  data () {
    return {
      mode: 'dept', departmentId: '', employeeIds: [], shiftId: '',
      dateRange: null, override: false, remark: '', saving: false,
      deptOptions: [], empOptions: [], shiftOptions: []
    }
  },
  methods: {
    async onOpen () {
      this.mode = 'dept'; this.departmentId = ''; this.employeeIds = []; this.shiftId = ''; this.dateRange = null; this.override = false; this.remark = ''
      try {
        const [d, s] = await Promise.all([getDeptTree(), getShiftOptions()])
        if (d.code === 0) this.deptOptions = flattenDept(d.data || []).map(x => ({ id: x.id, name: x.name }))
        if (s.code === 0) this.shiftOptions = s.data || []
      } catch (e) {}
      this.loadEmployees()
    },
    async loadEmployees () {
      try {
        const r = await getScheduleEmployees({})
        if (r.code === 0) this.empOptions = r.data || []
      } catch (e) {}
    },
    async submit () {
      if (!this.shiftId) { this.$message.warning('请选择班次'); return }
      if (!this.dateRange || this.dateRange.length !== 2) { this.$message.warning('请选择日期范围'); return }
      this.saving = true
      try {
        const base = { shift_id: this.shiftId, start_date: this.dateRange[0], end_date: this.dateRange[1], override: this.override, shift_type: 'full', remark: this.remark }
        let r
        if (this.mode === 'dept') {
          if (!this.departmentId) { this.$message.warning('请选择部门'); return }
          r = await batchSetScheduleByDept({ ...base, department_id: this.departmentId })
        } else {
          if (!this.employeeIds.length) { this.$message.warning('请选择员工'); return }
          r = await batchSetSchedule({ ...base, employee_ids: this.employeeIds })
        }
        if (r.code === 0) {
          this.$message.success(r.msg || '排班完成')
          this.$emit('update:visible', false)
          this.$emit('saved')
        }
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.tip { font-size: 12px; color: #909399; margin-left: 8px; }
</style>
