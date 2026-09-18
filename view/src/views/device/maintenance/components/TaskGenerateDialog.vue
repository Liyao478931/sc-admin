<template>
  <el-dialog title="手动生成任务" :visible.sync="visible" width="500px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="90px" size="small">
      <el-form-item label="保养计划" prop="plan_id">
        <el-select v-model="form.plan_id" filterable placeholder="选择计划" style="width:100%">
          <el-option v-for="p in planOptions" :key="p.id" :label="p.plan_name + '（' + p.device_name + '）'" :value="p.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="执行日期" prop="execute_date">
        <el-date-picker v-model="form.execute_date" type="date" value-format="yyyy-MM-dd" style="width:100%" :picker-options="{ disabledDate: (t) => t.getTime() < Date.now() - 86400000 }" />
      </el-form-item>
      <el-form-item label="执行人">
        <el-select v-model="form.executor_id" filterable clearable placeholder="不选则使用计划默认执行人" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">确认</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { generateTask } from '@/api/maintenanceTask'
import { getPlanList } from '@/api/maintenance'
import { getUserList } from '@/api/user'

export default {
  name: 'TaskGenerateDialog',
  props: {
    visible: Boolean
  },
  data() {
    return {
      saving: false, planOptions: [], userOptions: [],
      form: { plan_id: null, execute_date: null, executor_id: null },
      rules: {
        plan_id: [{ required: true, message: '请选择计划', trigger: 'change' }],
        execute_date: [{ required: true, message: '请选择执行日期', trigger: 'change' }]
      }
    }
  },
  watch: {
    visible(v) {
      if (v) { this.loadPlans(); this.loadUsers(); this.form = { plan_id: null, execute_date: null, executor_id: null } }
    }
  },
  methods: {
    async loadPlans() { try { const r = await getPlanList({ limit: 500 }); if (r.code === 0) this.planOptions = r.data.list || [] } catch (e) {} },
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const d = { ...this.form }
        if (!d.executor_id) delete d.executor_id
        const r = await generateTask(d)
        if (r.code === 0) { this.$message.success('任务生成成功'); this.$emit('saved') }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
