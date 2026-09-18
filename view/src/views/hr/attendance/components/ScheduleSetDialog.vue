<template>
  <el-dialog title="排班设置" :visible="visible" @update:visible="$emit('update:visible', $event)" width="480px" top="8vh" @open="onOpen">
    <el-form label-width="90px" size="small">
      <el-form-item label="员工"><span class="readonly">{{ employeeName }}</span></el-form-item>
      <el-form-item label="日期"><span class="readonly">{{ date }}</span></el-form-item>
      <el-form-item label="班次">
        <el-select v-model="form.shift_id" placeholder="选择班次（休息=无班次）" clearable filterable style="width:100%">
          <el-option label="休息（无班次）" :value="null" />
          <el-option v-for="s in shiftOptions" :key="s.id" :label="s.shift_name + '（' + s.shift_code + '）'" :value="s.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="班次类型">
        <el-radio-group v-model="form.shift_type">
          <el-radio v-for="opt in shiftTypeOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="备注"><el-input v-model="form.remark" maxlength="255" /></el-form-item>
    </el-form>
    <span slot="footer">
      <el-button v-if="existing" size="small" type="danger" plain @click="doDelete">设为休息</el-button>
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getShiftOptions } from '@/api/attendanceShift'
import { setSchedule, deleteSchedule } from '@/api/attendanceSchedule'

export default {
  name: 'ScheduleSetDialog',
  props: {
    visible: { type: Boolean, default: false },
    employeeId: { type: Number, default: 0 },
    employeeName: { type: String, default: '' },
    date: { type: String, default: '' },
    existing: { type: Object, default: null }
  },
  data () {
    return { shiftOptions: [], shiftTypeOptions: [], saving: false, form: { shift_id: null, shift_type: 'full', remark: '' } }
  },
  methods: {
    async onOpen () {
      this.loadDicts()
      this.form = { shift_id: this.existing && this.existing.shift_id ? this.existing.shift_id : null, shift_type: this.existing && this.existing.shift_type ? this.existing.shift_type : 'full', remark: (this.existing && this.existing.remark) || '' }
      try {
        const r = await getShiftOptions()
        if (r.code === 0) this.shiftOptions = r.data || []
      } catch (e) {}
    },
    // 班次类型从字典动态加载
    async loadDicts () {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('attendance_shift_type'); this.shiftTypeOptions = r.data || [] } catch (e) { this.shiftTypeOptions = [] }
    },
    async submit () {
      this.saving = true
      try {
        const r = await setSchedule({ employee_id: this.employeeId, schedule_date: this.date, shift_id: this.form.shift_id, shift_type: this.form.shift_type, remark: this.form.remark })
        if (r.code === 0) { this.$message.success('排班成功'); this.$emit('update:visible', false); this.$emit('saved') }
      } catch (e) {} finally { this.saving = false }
    },
    async doDelete () {
      this.$confirm('确认将该员工此日设为休息？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSchedule({ employee_id: this.employeeId, schedule_date: this.date })
          if (r.code === 0) { this.$message.success('已设为休息'); this.$emit('update:visible', false); this.$emit('saved') }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.readonly { font-size: 14px; color: #303133; }
</style>
