<template>
  <el-dialog title="巡检记录详情" :visible.sync="dialogVisible" width="800px" @open="loadData">
    <div v-loading="loading">
      <el-descriptions :column="3" border size="small" title="基础信息">
        <el-descriptions-item label="记录编号">{{ d.record_code || '-' }}</el-descriptions-item>
        <el-descriptions-item label="设备名称">{{ d.device_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="执行人">{{ d.executor_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="执行时间">{{ d.execute_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="检查项数">{{ d.total_count ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="异常项数">{{ d.abnormal_count ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="整体结果"><el-tag :type="d.result === 'abnormal' ? 'danger' : 'success'" size="mini">{{ d.result === 'abnormal' ? '异常' : '正常' }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="审核状态"><el-tag size="mini" :type="auditType">{{ auditLabel }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="备注">{{ d.remark || '-' }}</el-descriptions-item>
      </el-descriptions>

      <el-divider content-position="left">检查项明细</el-divider>
      <el-table :data="items" size="mini" border style="width:100%">
        <el-table-column type="index" label="#" width="50" />
        <el-table-column prop="name" label="检查项" min-width="120" />
        <el-table-column prop="standard" label="检查标准" min-width="120" />
        <el-table-column label="结果" width="80">
          <template slot-scope="{ row }"><el-tag size="mini" :type="row.result === 'abnormal' ? 'danger' : (row.result === 'na' ? 'info' : 'success')">{{ resultLabel(row.result) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="异常描述" min-width="140">
          <template slot-scope="{ row }"><span style="font-size:12px">{{ row.desc || '-' }}</span></template>
        </el-table-column>
      </el-table>
    </div>
  </el-dialog>
</template>

<script>
import { getRecordDetail } from '@/api/deviceInspection'

export default {
  name: 'InspectionRecordDetailDialog',
  props: { visible: Boolean, recordId: { type: Number, default: 0 } },
  data() { return { dialogVisible: this.visible, loading: false, d: {}, items: [] } },
  watch: { visible(val) { this.dialogVisible = val } },
  computed: {
    auditLabel() { return { pending: '待审核', approved: '通过', rejected: '驳回' }[this.d.audit_status] || '-' },
    auditType() { return { pending: 'warning', approved: 'success', rejected: 'danger' }[this.d.audit_status] || 'info' }
  },
  methods: {
    resultLabel(v) { return { normal: '正常', abnormal: '异常', na: '不适用' }[v] || v || '-' },
    async loadData() {
      if (!this.recordId) return
      this.loading = true
      try {
        const res = await getRecordDetail(this.recordId)
        if (res.code === 0) { this.d = res.data; this.items = this.d.items || [] }
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>
