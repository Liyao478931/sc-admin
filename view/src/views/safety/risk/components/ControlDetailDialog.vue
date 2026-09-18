<template>
  <el-dialog title="措施详情" :visible="visible" width="850px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-descriptions v-if="detail" :column="3" size="small" border style="margin-bottom:14px;">
        <el-descriptions-item label="措施编号">{{ detail.measure_code }}</el-descriptions-item>
        <el-descriptions-item label="风险名称">{{ detail.risk_name }}</el-descriptions-item>
        <el-descriptions-item label="风险等级">{{ detail.risk_level_text }}</el-descriptions-item>
        <el-descriptions-item label="措施类型">{{ detail.measure_type_text }}</el-descriptions-item>
        <el-descriptions-item label="责任人">{{ detail.responsible_person_name }}</el-descriptions-item>
        <el-descriptions-item label="完成期限">{{ detail.deadline }}</el-descriptions-item>
        <el-descriptions-item label="实施状态">{{ detail.implement_status_text }}</el-descriptions-item>
        <el-descriptions-item label="验证状态">{{ detail.verify_status_text }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.create_time }}</el-descriptions-item>
      </el-descriptions>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">措施内容</div>
        <div class="sec-text">{{ detail ? detail.measure_content : '' }}</div>
      </el-card>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">实施进度</div>
        <div class="sec-text" v-if="detail">
          开始时间：{{ detail.implement_start_time || '-' }}　完成时间：{{ detail.implement_complete_time || '-' }}
        </div>
        <div v-if="detail && detail.invalid_reason" class="sec-text" style="color:#F56C6C;">失效原因：{{ detail.invalid_reason }}</div>
        <div v-if="detail && detail.progress_remark" class="sec-text">进度备注：{{ detail.progress_remark }}</div>
      </el-card>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">验证信息</div>
        <div class="sec-text" v-if="detail">
          验证人：{{ detail.verify_by_name || '-' }}　验证时间：{{ detail.verify_time || '-' }}
        </div>
        <div v-if="detail && detail.verify_opinion" class="sec-text">验证意见：{{ detail.verify_opinion }}</div>
      </el-card>

      <el-card shadow="never">
        <div class="sec-title">备注</div>
        <div class="sec-text">{{ detail ? (detail.remark || '-') : '' }}</div>
      </el-card>
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getControlDetail } from '@/api/safetyRisk'

export default {
  name: 'ControlDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { loading: false, detail: null }
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.id) return
      this.loading = true; this.detail = null
      try {
        const r = await getControlDetail(this.row.id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>

<style scoped>
.sec-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 8px; }
.sec-text { font-size: 13px; color: #606266; line-height: 1.8; }
</style>
