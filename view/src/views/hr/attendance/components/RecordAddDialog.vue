<template>
  <el-dialog title="补录打卡" :visible="visible" @update:visible="$emit('update:visible', $event)" width="500px" top="8vh" @open="onOpen">
    <el-form ref="form" :model="form" label-width="100px" size="small" :rules="rules">
      <el-form-item label="员工" prop="employee_id">
        <el-select v-model="form.employee_id" filterable placeholder="请选择员工" style="width:100%">
          <el-option v-for="e in empOptions" :key="e.id" :label="e.name + '（' + (e.employee_id || '') + '）'" :value="e.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="打卡日期" prop="check_date">
        <el-date-picker v-model="form.check_date" type="date" value-format="yyyy-MM-dd" placeholder="选择日期" style="width:100%" />
      </el-form-item>
      <el-form-item label="打卡时间" prop="check_time">
        <el-time-picker v-model="form.check_time" placeholder="选择时间" format="HH:mm" value-format="HH:mm" style="width:100%" />
      </el-form-item>
      <el-form-item label="打卡结果" prop="check_result">
        <el-select v-model="form.check_result" style="width:100%">
          <el-option label="正常" value="normal" /><el-option label="迟到" value="late" />
          <el-option label="早退" value="early" /><el-option label="缺卡" value="miss" />
        </el-select>
      </el-form-item>
      <el-form-item label="打卡方式" prop="check_type">
        <el-select v-model="form.check_type" style="width:100%">
          <el-option label="手动" value="manual" /><el-option label="人脸" value="face" />
          <el-option label="蓝牙" value="bluetooth" /><el-option label="指纹" value="fingerprint" /><el-option label="定位" value="gps" />
        </el-select>
      </el-form-item>
      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="255" placeholder="选填" />
      </el-form-item>
      <el-alert v-if="duplicateHint" :title="duplicateHint" type="warning" :closable="false" show-icon style="margin-bottom:8px;" />
    </el-form>
    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">提交</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getScheduleEmployees } from '@/api/attendanceSchedule'
import { addRecord } from '@/api/attendanceRecord'

export default {
  name: 'RecordAddDialog',
  props: { visible: { type: Boolean, default: false } },
  data () {
    return {
      empOptions: [], saving: false, duplicateHint: '',
      form: { employee_id: '', check_date: '', check_time: '', check_result: 'normal', check_type: 'manual', remark: '' },
      rules: {
        employee_id: [{ required: true, message: '请选择员工', trigger: 'change' }],
        check_date: [{ required: true, message: '请选择打卡日期', trigger: 'change' }],
        check_time: [{ required: true, message: '请选择打卡时间', trigger: 'change' }],
        check_result: [{ required: true, message: '请选择打卡结果', trigger: 'change' }],
        check_type: [{ required: true, message: '请选择打卡方式', trigger: 'change' }]
      }
    }
  },
  methods: {
    async onOpen () {
      this.form = { employee_id: '', check_date: '', check_time: '', check_result: 'normal', check_type: 'manual', remark: '' }
      this.duplicateHint = ''
      try {
        const r = await getScheduleEmployees({})
        if (r.code === 0) this.empOptions = r.data || []
      } catch (e) {}
    },
    async submit (override = false) {
      this.$refs.form.validate(async (ok) => {
        if (!ok) return
        this.saving = true
        this.duplicateHint = ''
        try {
          const r = await addRecord({ ...this.form, override })
          if (r.code === 0) {
            this.$message.success('补录成功')
            this.$emit('update:visible', false)
            this.$emit('saved')
          }
        } catch (e) {
          const msg = e && e.message ? e.message : ''
          if (!override && msg.indexOf('覆盖') > -1) {
            this.duplicateHint = '该员工当天已有打卡记录，可再次提交覆盖'
            this.$confirm('该员工当天已有打卡记录，是否覆盖？', '提示', { type: 'warning' }).then(() => this.submit(true)).catch(() => {})
          }
        } finally { this.saving = false }
      })
    }
  }
}
</script>
