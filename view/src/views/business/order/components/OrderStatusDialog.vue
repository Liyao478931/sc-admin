<!--
  文件：admin/src/views/business/order/components/OrderStatusDialog.vue
  功能：订单状态变更弹窗（450px）
    - 当前状态
    - 目标状态下拉
    - 变更原因
    - 确认
-->
<template>
  <el-dialog title="变更订单状态" :visible="visible" width="450px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <el-form label-width="90px" size="small">
      <el-form-item label="订单编号">{{ row ? row.order_no : '' }}</el-form-item>
      <el-form-item label="当前状态">
        <el-tag size="mini" :type="statusTag(currentStatus)">{{ statusText(currentStatus) }}</el-tag>
      </el-form-item>
      <el-form-item label="目标状态" required>
        <el-select v-model="targetStatus" style="width:100%" placeholder="选择目标状态">
          <el-option v-for="opt in targetOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="变更原因">
        <el-input v-model="remark" type="textarea" :rows="3" maxlength="255" placeholder="变更原因（选填）" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" :disabled="!targetStatus" @click="handleSubmit">确认变更</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { changeOrderStatus } from '../../../../api/businessOrder'

export default {
  name: 'OrderStatusDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }
  },
  data() {
    return { targetStatus: '', remark: '', submitting: false, statusOptions: [] }
  },
  computed: {
    currentStatus() { return this.row ? this.row.order_status : '' },
    targetOptions() { return this.statusOptions.filter(s => s.value !== this.currentStatus) }
  },
  watch: {
    visible(val) {
      if (val) {
        this.targetStatus = ''
        this.remark = ''
        this.loadDicts()
      }
    }
  },
  methods: {
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('order_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    statusTag(s) { return { pending: 'warning', reviewed: 'primary', production: 'danger', shipping: 'success', completed: 'info', cancelled: 'danger' }[s] || 'info' },
    statusText(s) { return { pending: '待评审', reviewed: '已评审', production: '生产中', shipping: '待发货', completed: '已完成', cancelled: '已取消' }[s] || s },
    async handleSubmit() {
      this.submitting = true
      try {
        const r = await changeOrderStatus(this.row.id, { order_status: this.targetStatus, remark: this.remark })
        if (r.code === 0) { this.$message.success(r.msg); this.$emit('success') }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>
