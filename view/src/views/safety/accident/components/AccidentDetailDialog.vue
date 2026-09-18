<template>
  <el-dialog title="事故详情" :visible="visible" width="900px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-descriptions v-if="detail" :column="3" size="small" border style="margin-bottom:14px;">
        <el-descriptions-item label="事故编号">{{ detail.accident_code }}</el-descriptions-item>
        <el-descriptions-item label="事故名称">{{ detail.accident_name }}</el-descriptions-item>
        <el-descriptions-item label="事故等级">{{ detail.level_text }}</el-descriptions-item>
        <el-descriptions-item label="事故类型">{{ detail.type_text }}</el-descriptions-item>
        <el-descriptions-item label="发生时间">{{ detail.happen_time }}</el-descriptions-item>
        <el-descriptions-item label="发生地点">{{ detail.happen_location }}</el-descriptions-item>
        <el-descriptions-item label="发生部门">{{ detail.happen_department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="登记人">{{ detail.registrant_name }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ detail.status_text }}</el-descriptions-item>
      </el-descriptions>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">事故经过</div>
        <div class="sec-text">{{ detail ? detail.accident_process : '' }}</div>
        <div class="sec-title" style="margin-top:12px;">事故原因</div>
        <div class="sec-text">{{ detail ? detail.accident_cause : '' }}</div>
      </el-card>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">伤亡与损失</div>
        <div class="sec-text">死亡 {{ detail ? detail.death_count : 0 }} 人，重伤 {{ detail ? detail.serious_injury_count : 0 }} 人，轻伤 {{ detail ? detail.minor_injury_count : 0 }} 人</div>
        <div class="sec-text">直接经济损失 {{ detail ? detail.economic_loss : 0 }} 万元</div>
      </el-card>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">责任人信息</div>
        <div class="sec-text" v-if="detail">
          姓名：{{ detail.responsible_person || '-' }}　部门：{{ detail.responsible_department || '-' }}　岗位：{{ detail.responsible_position || '-' }}
        </div>
        <div class="sec-text">处理意见：{{ detail ? (detail.handle_opinion || '-') : '' }}</div>
      </el-card>

      <el-card shadow="never" style="margin-bottom:12px;">
        <div class="sec-title">附件</div>
        <div v-if="detail && detail.attachments && detail.attachments.length">
          <el-image v-for="(a, i) in detail.attachments" :key="i" :src="a.url" :preview-src-list="detail.attachments.map(x => x.url)"
            fit="cover" style="width:90px;height:90px;margin:0 8px 8px 0;border-radius:6px;" />
        </div>
        <div v-else class="sec-text">暂无附件</div>
      </el-card>

      <el-card shadow="never">
        <div class="sec-title">状态变更历史</div>
        <el-table v-if="detail && detail.logs && detail.logs.length" :data="detail.logs" size="mini" border>
          <el-table-column prop="action" label="操作" width="110" />
          <el-table-column prop="target_name" label="内容" show-overflow-tooltip />
          <el-table-column prop="real_name" label="操作人" width="100" />
          <el-table-column prop="created_at" label="时间" width="160" />
        </el-table>
        <div v-else class="sec-text">暂无操作记录</div>
      </el-card>
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getAccidentDetail } from '@/api/safetyAccident'

export default {
  name: 'AccidentDetailDialog',
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
        const r = await getAccidentDetail(this.row.id)
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
