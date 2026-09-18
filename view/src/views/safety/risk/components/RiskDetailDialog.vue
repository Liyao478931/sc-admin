<template>
  <el-dialog title="风险详情" :visible="visible" width="900px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-tabs v-model="tab" v-if="detail">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <el-descriptions :column="3" size="small" border style="margin-bottom:14px;">
            <el-descriptions-item label="风险编号">{{ detail.risk_code }}</el-descriptions-item>
            <el-descriptions-item label="风险名称">{{ detail.risk_name }}</el-descriptions-item>
            <el-descriptions-item label="风险类型">{{ detail.type_text }}</el-descriptions-item>
            <el-descriptions-item label="风险等级">{{ detail.level_text }}</el-descriptions-item>
            <el-descriptions-item label="所属区域">{{ detail.area }}</el-descriptions-item>
            <el-descriptions-item label="所属部门">{{ detail.department_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="责任人">{{ detail.responsible_person_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="辨识人">{{ detail.identifier_name }}</el-descriptions-item>
            <el-descriptions-item label="辨识日期">{{ detail.identify_date }}</el-descriptions-item>
            <el-descriptions-item label="状态">{{ detail.status_text }}</el-descriptions-item>
          </el-descriptions>
          <el-card shadow="never" style="margin-bottom:12px;">
            <div class="sec-title">危险源描述</div>
            <div class="sec-text">{{ detail.hazard_source }}</div>
            <div class="sec-title" style="margin-top:12px;">可能导致的后果</div>
            <div class="sec-text">{{ detail.consequence }}</div>
            <div v-if="detail.impact_scope" style="margin-top:8px;"><span class="sec-title">影响范围：</span><span class="sec-text">{{ detail.impact_scope }}</span></div>
          </el-card>
          <el-card shadow="never" style="margin-bottom:12px;">
            <div class="sec-title">现有控制措施</div>
            <div class="sec-text">{{ detail.current_controls || '无' }}</div>
            <div v-if="detail.control_effectiveness" style="margin-top:8px;">有效性：{{ detail.control_effectiveness_text }}</div>
          </el-card>
          <el-card shadow="never">
            <div class="sec-title">备注</div>
            <div class="sec-text">{{ detail.remark || '-' }}</div>
          </el-card>
        </el-tab-pane>

        <!-- 附件 -->
        <el-tab-pane label="附件列表" name="files">
          <el-image v-for="(a, i) in detail.attachments" :key="i" :src="a.url" :preview-src-list="detail.attachments.map(x => x.url)"
            fit="cover" style="width:120px;height:120px;margin:0 10px 10px 0;border-radius:6px;" />
          <div v-if="!detail.attachments.length" class="sec-text">暂无附件</div>
        </el-tab-pane>

        <!-- 状态历史 -->
        <el-tab-pane label="状态变更历史" name="logs">
          <el-table v-if="detail.logs && detail.logs.length" :data="detail.logs" size="mini" border>
            <el-table-column prop="action" label="操作" width="110" />
            <el-table-column prop="target_name" label="内容" show-overflow-tooltip />
            <el-table-column prop="real_name" label="操作人" width="100" />
            <el-table-column prop="created_at" label="时间" width="160" />
          </el-table>
          <div v-else class="sec-text">暂无记录</div>
        </el-tab-pane>
      </el-tabs>
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getRiskDetail } from '@/api/safetyRisk'

export default {
  name: 'RiskDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { loading: false, tab: 'info', detail: null }
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.id) return
      this.loading = true; this.detail = null; this.tab = 'info'
      try {
        const r = await getRiskDetail(this.row.id)
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
