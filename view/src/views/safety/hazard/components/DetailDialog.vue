<template>
  <el-dialog title="隐患详情" :visible.sync="dialogVisible" width="900px" @open="loadData">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="基本信息" name="base">
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="隐患编号">{{ d.hazard_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="隐患名称">{{ d.hazard_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="隐患类型">{{ typeLabel }}</el-descriptions-item>
            <el-descriptions-item label="隐患等级"><el-tag :type="levelType" size="mini">{{ levelLabel }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="来源类型">{{ sourceLabel }}</el-descriptions-item>
            <el-descriptions-item label="发现位置">{{ d.location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发现人">{{ d.discoverer_name || d.discovered_by_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发现时间">{{ d.discovered_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="状态"><el-tag :type="statusType" size="mini">{{ statusLabel }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="隐患描述" :span="3">{{ d.hazard_desc || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改人">{{ d.handler_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改期限">{{ d.handler_deadline || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改完成">{{ d.handle_completed_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="整改措施" :span="3">{{ d.handle_measure || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验证人">{{ d.verifier_name || d.verified_by_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验证时间">{{ d.verified_at || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验证结果">{{ verifyLabel }}</el-descriptions-item>
            <el-descriptions-item label="验证意见" :span="3">{{ d.verify_opinion || '-' }}</el-descriptions-item>
            <el-descriptions-item v-if="d.reject_reason" label="驳回原因" :span="3">{{ d.reject_reason }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="整改历史" name="handle">
          <el-timeline v-if="handleHistory.length">
            <el-timeline-item v-for="(h, i) in handleHistory" :key="i" :timestamp="h.time" placement="top">
              <div>{{ h.content }}</div><div style="color:#909399;font-size:12px">{{ h.by }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无整改记录" :image-size="60" />
        </el-tab-pane>
        <el-tab-pane label="验证历史" name="verify">
          <el-timeline v-if="verifyHistory.length">
            <el-timeline-item v-for="(v, i) in verifyHistory" :key="i" :timestamp="v.time" placement="top">
              <div>{{ v.content }}</div><div style="color:#909399;font-size:12px">{{ v.by }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无验证记录" :image-size="60" />
        </el-tab-pane>
        <el-tab-pane label="操作记录" name="logs">
          <el-timeline v-if="(d.operation_logs || []).length">
            <el-timeline-item v-for="l in d.operation_logs" :key="l.id" :timestamp="l.created_at" placement="top">
              <div>{{ l.action }}：{{ l.detail }}</div><div style="color:#909399;font-size:12px">{{ l.real_name }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无操作记录" :image-size="60" />
        </el-tab-pane>
      </el-tabs>
    </div>
  </el-dialog>
</template>

<script>
import { getHazardDetail } from '@/api/safetyHazard'

export default {
  name: 'SafetyHazardDetailDialog',
  props: { visible: Boolean, hazardId: { type: Number, default: 0 } },
  data() {
    return {
      dialogVisible: this.visible, loading: false, activeTab: 'base', d: {},
      dicts: { type: [], level: [], source: [], status: [], verify: [] }
    }
  },
  watch: { visible(val) { this.dialogVisible = val } },
  computed: {
    typeLabel() { const t = this.dicts.type.find(x => x.value === this.d.hazard_type); return t ? t.label : (this.d.hazard_type || '-') },
    levelLabel() { const t = this.dicts.level.find(x => x.value === this.d.hazard_level); return t ? t.label : (this.d.hazard_level || '-') },
    levelType() { const t = this.dicts.level.find(x => x.value === this.d.hazard_level); return (t && t.style) || 'info' },
    sourceLabel() { const t = this.dicts.source.find(x => x.value === this.d.source_type); return t ? t.label : (this.d.source_type || '-') },
    statusLabel() { const t = this.dicts.status.find(x => x.value === this.d.status); return t ? t.label : (this.d.status || '-') },
    statusType() { const t = this.dicts.status.find(x => x.value === this.d.status); return (t && t.style) || 'info' },
    verifyLabel() { const t = this.dicts.verify.find(x => x.value === this.d.verify_result); return t ? t.label : (this.d.verify_result || '-') },
    handleHistory() {
      const list = []
      if (this.d.handler_name && this.d.handle_measure) list.push({ by: this.d.handler_name, time: this.d.handle_completed_at || '-', content: '整改：' + this.d.handle_measure })
      return list
    },
    verifyHistory() {
      const list = []
      if (this.d.verifier_name && this.d.verified_at) {
        list.push({ by: this.d.verifier_name, time: this.d.verified_at, content: '验证：' + (this.verifyLabel) + ' ' + (this.d.verify_opinion || '') })
      }
      ;(this.d.reject_history || []).forEach(r => {
        list.push({ by: r.by || '', time: r.time || '', content: '驳回：' + (r.reason || '') })
      })
      return list
    }
  },
  methods: {
    async loadData() {
      if (!this.hazardId) return
      this.loading = true
      try {
        const { getDictionaryBatch } = await import('@/utils/dict')
        const dict = await getDictionaryBatch(['safety_hazard_type', 'safety_hazard_level', 'safety_hazard_source', 'safety_hazard_status', 'verify_result'])
        this.dicts = { type: dict['safety_hazard_type'] || [], level: dict['safety_hazard_level'] || [], source: dict['safety_hazard_source'] || [], status: dict['safety_hazard_status'] || [], verify: dict['verify_result'] || [] }
        const res = await getHazardDetail(this.hazardId)
        if (res.code === 0) this.d = res.data
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>
