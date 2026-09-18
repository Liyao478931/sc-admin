<template>
  <el-dialog title="转派" :visible.sync="visible" width="500px" :close-on-click-modal="false">
    <el-form :model="form" :rules="rules" ref="form" label-width="100px" size="small">
      <el-form-item label="当前处理人">
        <el-input :value="currentHandler" disabled />
      </el-form-item>
      <el-form-item label="新处理人" prop="handler_id">
        <el-select v-model="form.handler_id" filterable placeholder="请选择新的维修人员" style="width:100%">
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="转派原因" prop="transfer_reason">
        <el-input v-model="form.transfer_reason" type="textarea" :rows="3" maxlength="255" placeholder="请填写转派原因（至少5字）" />
      </el-form-item>
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">确认转派</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { transferOrder } from '@/api/repairOrder'
import { getUserList } from '@/api/user'

export default {
  name: 'OrderTransferDialog',
  props: {
    visible: Boolean,
    orderId: { type: Number, default: 0 }
  },
  data() {
    return {
      saving: false, userOptions: [], currentHandler: '',
      form: { handler_id: null, transfer_reason: '' },
      rules: {
        handler_id: [{ required: true, message: '请选择新处理人', trigger: 'change' }],
        transfer_reason: [{ required: true, min: 5, message: '转派原因至少5字', trigger: 'blur' }]
      }
    }
  },
  watch: {
    visible(v) {
      if (v) { this.form = { handler_id: null, transfer_reason: '' }; this.loadUsers(); this.loadCurrent() }
    }
  },
  methods: {
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async loadCurrent() {
      try {
        const { getOrderDetail } = await import('@/api/repairOrder')
        const r = await getOrderDetail(this.orderId)
        if (r.code === 0) this.currentHandler = r.data.handler_name || '-'
      } catch (e) {}
    },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const r = await transferOrder(this.orderId, this.form)
        if (r.code === 0) { this.$message.success('转派成功'); this.$emit('saved'); this.visible = false }
        else this.$message.error(r.msg || '转派失败')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
