<template>
  <el-dialog title="派单" :visible.sync="visible" width="500px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="100px" size="small">
      <el-form-item label="处理人" prop="handler_id">
        <el-select v-model="form.handler_id" filterable placeholder="请选择维修人员" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="计划完成">
        <el-date-picker v-model="form.plan_complete_time" type="date" value-format="yyyy-MM-dd" placeholder="可选" style="width:100%" />
      </el-form-item>
      <el-form-item label="派单备注">
        <el-input v-model="form.assign_remark" type="textarea" :rows="2" maxlength="255" placeholder="可选" />
      </el-form-item>
      <el-alert v-if="isBatch" type="info" :closable="false" show-icon title="批量派单" description="将派单给选中的多个工单" />
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">确认派单</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { assignOrder, batchAssignOrders } from '@/api/repairOrder'
import { getUserList } from '@/api/user'

export default {
  name: 'OrderAssignDialog',
  props: {
    visible: Boolean,
    orderId: { type: Number, default: 0 },
    batchIds: { type: Array, default: () => [] }
  },
  data() {
    return {
      saving: false, userOptions: [],
      form: { handler_id: null, plan_complete_time: '', assign_remark: '' },
      rules: { handler_id: [{ required: true, message: '请选择处理人', trigger: 'change' }] }
    }
  },
  computed: { isBatch() { return this.batchIds && this.batchIds.length > 0 } },
  watch: { visible(v) { if (v) { this.form = { handler_id: null, plan_complete_time: '', assign_remark: '' }; this.loadUsers() } } },
  methods: {
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        let r
        if (this.isBatch) r = await batchAssignOrders(this.batchIds, this.form.handler_id)
        else r = await assignOrder(this.orderId, this.form)
        if (r.code === 0) { this.$message.success(r.msg || '派单成功'); this.$emit('saved'); this.visible = false }
        else this.$message.error(r.msg || '派单失败')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
