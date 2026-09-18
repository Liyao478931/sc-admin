<template>
  <el-dialog title="分配执行人" :visible.sync="visible" width="450px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="90px" size="small">
      <el-form-item label="执行人" prop="executor_id">
        <el-select v-model="form.executor_id" filterable placeholder="选择执行人" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="验收人">
        <el-select v-model="form.acceptor_id" filterable clearable placeholder="选择验收人（可选）" style="width:100%">
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
import { assignTask } from '@/api/maintenanceTask'
import { getUserList } from '@/api/user'

export default {
  name: 'TaskAssignDialog',
  props: {
    visible: Boolean,
    taskId: { type: Number, default: 0 }
  },
  data() {
    return {
      saving: false, userOptions: [],
      form: { executor_id: null, acceptor_id: null },
      rules: { executor_id: [{ required: true, message: '请选择执行人', trigger: 'change' }] }
    }
  },
  watch: {
    visible(v) {
      if (v) { this.loadUsers(); this.form = { executor_id: null, acceptor_id: null } }
    }
  },
  methods: {
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const d = { ...this.form }
        if (!d.acceptor_id) delete d.acceptor_id
        const r = await assignTask(this.taskId, d)
        if (r.code === 0) { this.$message.success('分配成功'); this.$emit('saved') }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
