<template>
  <el-dialog title="手动生成任务" :visible.sync="dialogVisible" width="500px" append-to-body @open="loadPlans">
    <el-form :model="form" :rules="rules" ref="formRef" label-width="90px" size="small">
      <el-form-item label="检查计划" prop="plan_id">
        <el-select v-model="form.plan_id" filterable placeholder="请选择检查计划" style="width:100%">
          <el-option v-for="p in planOptions" :key="p.id" :label="`${p.plan_name}（${p.plan_code}）`" :value="p.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="执行日期" prop="execute_date">
        <el-date-picker v-model="form.execute_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择执行日期" style="width:100%" />
      </el-form-item>
      <el-form-item label="执行人">
        <el-select v-model="form.executor_id" clearable filterable placeholder="不选则使用计划默认执行人" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确认生成</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { generateTask, getPlanOptions } from '@/api/safetyInspectionTask'
import { getUserList } from '@/api/user'

export default {
  name: 'TaskGenerateDialog',
  props: { visible: Boolean },
  data() {
    return {
      dialogVisible: this.visible,
      saving: false,
      planOptions: [],
      userOptions: [],
      form: { plan_id: null, execute_date: '', executor_id: null },
      rules: {
        plan_id: [{ required: true, message: '请选择检查计划', trigger: 'change' }],
        execute_date: [{ required: true, message: '请选择执行日期', trigger: 'change' }],
      },
    }
  },
  watch: {
    visible(val) {
      this.dialogVisible = val
      if (val) { this.form = { plan_id: null, execute_date: '', executor_id: null }; this.loadUsers() }
    },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    async loadPlans() {
      try {
        const r = await getPlanOptions()
        if (r.code === 0) this.planOptions = (r.data.list || []).filter(p => p.status === 'active')
      } catch (e) {}
    },
    async loadUsers() {
      try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {}
    },
    submit() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await generateTask(this.form)
          if (r.code === 0) { this.$message.success(r.msg || '任务生成成功'); this.dialogVisible = false; this.$emit('saved') }
        } catch (e) {}
        this.saving = false
      })
    },
  },
}
</script>
