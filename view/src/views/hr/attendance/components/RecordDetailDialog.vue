<template>
  <el-dialog title="打卡记录详情" :visible="visible" @update:visible="$emit('update:visible', $event)" width="600px" top="8vh" @open="load">
    <div v-loading="loading">
      <template v-if="detail.id">
        <div class="sec-title">员工信息</div>
        <div class="info-grid">
          <span><b>姓名：</b>{{ detail.employee_name }}</span>
          <span><b>部门：</b>{{ detail.department_name || '-' }}</span>
          <span><b>岗位：</b>{{ detail.position_name || '-' }}</span>
        </div>

        <div class="sec-title">打卡信息</div>
        <div class="info-grid">
          <span><b>打卡日期：</b>{{ detail.check_date }}</span>
          <span><b>打卡时间：</b>{{ detail.check_time }}</span>
          <span><b>打卡结果：</b><el-tag size="mini" :type="resultType(detail.check_result)">{{ detail.check_result_text }}</el-tag></span>
          <span><b>打卡方式：</b>{{ detail.check_type_text }}</span>
          <span><b>打卡地址：</b>{{ detail.check_location || '-' }}</span>
          <span><b>打卡设备：</b>{{ detail.check_device || '-' }}</span>
        </div>

        <div class="sec-title">数据信息</div>
        <div class="info-grid">
          <span><b>数据来源：</b><el-tag size="mini" :type="detail.source === 'manual' ? 'success' : 'primary'">{{ detail.source_text }}</el-tag></span>
          <span><b>同步时间：</b>{{ detail.sync_time || '-' }}</span>
          <span><b>备注：</b>{{ detail.remark || '-' }}</span>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getRecordDetail } from '@/api/attendanceRecord'

export default {
  name: 'RecordDetailDialog',
  props: { visible: { type: Boolean, default: false }, recordId: { type: Number, default: 0 } },
  data () {
    return { loading: false, detail: {} }
  },
  methods: {
    resultType (r) { return { normal: 'success', late: 'warning', early: 'danger', miss: 'info' }[r] || 'info' },
    async load () {
      if (!this.recordId) return
      this.loading = true
      try {
        const r = await getRecordDetail(this.recordId)
        if (r.code === 0) this.detail = r.data || {}
      } catch (e) {} finally { this.loading = false }
    }
  }
}
</script>

<style scoped>
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 10px 0 8px; }
.info-grid { display: flex; flex-wrap: wrap; gap: 8px 24px; font-size: 13px; color: #333; margin-bottom: 6px; }
</style>
