<template>
  <el-dialog :title="recordId ? '编辑审批记录' : '录入审批记录'" :visible="visible" @update:visible="$emit('update:visible', $event)" width="600px" top="8vh" @open="onOpen">
    <el-form ref="form" :model="form" label-width="110px" size="small" :rules="rules">
      <el-form-item label="员工" prop="employee_id">
        <el-select v-model="form.employee_id" filterable :disabled="!!recordId" placeholder="请选择员工" style="width:100%">
          <el-option v-for="e in empOptions" :key="e.id" :label="e.name + '（' + (e.employee_id || '') + '）'" :value="e.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="审批类型" prop="approval_type">
        <el-select v-model="form.approval_type" :disabled="!!recordId" style="width:100%"><el-option label="请假" value="leave" /><el-option label="外出" value="outing" /><el-option label="出差" value="travel" /><el-option label="用车申请" value="car_apply" /></el-select>
      </el-form-item>
      <el-form-item label="申请日期" prop="apply_date">
        <el-date-picker v-model="form.apply_date" type="date" value-format="yyyy-MM-dd" placeholder="选择日期" style="width:100%" />
      </el-form-item>
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="开始时间" prop="start_time"><el-date-picker v-model="form.start_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="开始时间" style="width:100%" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="结束时间" prop="end_time"><el-date-picker v-model="form.end_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="结束时间" style="width:100%" /></el-form-item></el-col>
      </el-row>
      <el-form-item label="审批状态" prop="approval_status">
        <el-select v-model="form.approval_status" style="width:100%"><el-option label="待审批" value="pending" /><el-option label="已通过" value="approved" /><el-option label="已驳回" value="rejected" /><el-option label="已撤销" value="canceled" /></el-select>
      </el-form-item>
      <el-form-item label="审批人"><el-input v-model="form.approver" maxlength="50" /></el-form-item>
      <el-form-item label="审批时间"><el-date-picker v-model="form.approve_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="选填" style="width:100%" /></el-form-item>
      <el-form-item label="审批意见"><el-input v-model="form.approve_opinion" type="textarea" :rows="2" maxlength="500" /></el-form-item>
      <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" maxlength="255" /></el-form-item>
    </el-form>
    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">提交</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getScheduleEmployees } from '@/api/attendanceSchedule'
import { getApprovalDetail, addApproval, editApproval } from '@/api/attendanceApproval'

const defaultForm = () => ({ employee_id: '', approval_type: 'leave', apply_date: '', start_time: '', end_time: '', approval_status: 'approved', approver: '', approve_time: '', approve_opinion: '', remark: '' })

export default {
  name: 'ApprovalFormDialog',
  props: { visible: { type: Boolean, default: false }, recordId: { type: Number, default: 0 } },
  data () {
    return { empOptions: [], saving: false, form: defaultForm(), rules: {
      employee_id: [{ required: true, message: '请选择员工', trigger: 'change' }],
      approval_type: [{ required: true, message: '请选择审批类型', trigger: 'change' }],
      apply_date: [{ required: true, message: '请选择申请日期', trigger: 'change' }],
      start_time: [{ required: true, message: '请选择开始时间', trigger: 'change' }],
      end_time: [{ required: true, message: '请选择结束时间', trigger: 'change' }],
      approval_status: [{ required: true, message: '请选择审批状态', trigger: 'change' }]
    } }
  },
  methods: {
    async onOpen () {
      this.form = defaultForm()
      try {
        const r = await getScheduleEmployees({})
        if (r.code === 0) this.empOptions = r.data || []
      } catch (e) {}
      if (this.recordId) {
        try {
          const r = await getApprovalDetail(this.recordId)
          if (r.code === 0) {
            const d = r.data || {}
            this.form = {
              employee_id: d.employee_id, approval_type: d.approval_type, apply_date: d.apply_date,
              start_time: d.start_time, end_time: d.end_time, approval_status: d.approval_status,
              approver: d.approver || '', approve_time: d.approve_time || '', approve_opinion: d.approve_opinion || '', remark: d.remark || ''
            }
          }
        } catch (e) {}
      }
    },
    submit () {
      this.$refs.form.validate(async (ok) => {
        if (!ok) return
        if (this.form.start_time >= this.form.end_time) { this.$message.warning('开始时间必须早于结束时间'); return }
        this.saving = true
        try {
          const d = { ...this.form }
          if (d.approve_time === '') d.approve_time = null
          const r = this.recordId ? await editApproval(this.recordId, d) : await addApproval(d)
          if (r.code === 0) { this.$message.success('保存成功'); this.$emit('update:visible', false); this.$emit('saved') }
        } catch (e) {} finally { this.saving = false }
      })
    }
  }
}
</script>
