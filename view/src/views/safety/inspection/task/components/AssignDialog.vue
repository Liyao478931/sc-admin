<template>
  <el-dialog title="分配执行人" :visible.sync="dialogVisible" width="450px" append-to-body>
    <el-form :model="form" :rules="rules" ref="formRef" label-width="90px" size="small">
      <el-form-item label="任务编号">
        <el-input :value="row ? row.task_code : ''" disabled />
      </el-form-item>
      <el-form-item label="当前执行人">
        <el-tag size="small">{{ row?.executor_name || '未分配' }}</el-tag>
      </el-form-item>
      <el-form-item label="执行人" prop="executor_id">
        <el-select v-model="form.executor_id" filterable placeholder="请选择执行人" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { assignTask } from '@/api/safetyInspectionTask'

export default {
  name: 'TaskAssignDialog',
  props: {
    visible: Boolean,
    row: { type: Object, default: () => ({}) },
    userOptions: { type: Array, default: () => [] },
  },
  data() {
    return {
      dialogVisible: this.visible,
      saving: false,
      form: { executor_id: null },
      rules: { executor_id: [{ required: true, message: '请选择执行人', trigger: 'change' }] },
    }
  },
  watch: {
    visible(val) {
      this.dialogVisible = val
      if (val) this.form = { executor_id: null }
    },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    submit() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await assignTask(this.row.id, this.form.executor_id)
          if (r.code === 0) { this.$message.success(r.msg || '分配成功'); this.dialogVisible = false; this.$emit('saved') }
        } catch (e) {}
        this.saving = false
      })
    },
  },
}
</script>
