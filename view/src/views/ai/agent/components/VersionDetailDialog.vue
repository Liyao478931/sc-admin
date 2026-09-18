<template>
  <el-dialog title="版本详情" :visible.sync="visible" width="620px" append-to-body>
    <div v-if="detail" class="ver-detail">
      <div class="ver-head">
        <el-tag size="small" :type="statusType(detail.status)">{{ detail.status_text }}</el-tag>
        <span class="ver-num">v{{ detail.version_number }}</span>
        <span v-if="detail.version_name" class="ver-name">{{ detail.version_name }}</span>
      </div>
      <p v-if="detail.version_desc" class="ver-desc">{{ detail.version_desc }}</p>

      <div class="sub-title">配置快照</div>
      <el-descriptions :column="1" size="small" border>
        <el-descriptions-item label="智能体名称">{{ snap.agent_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="描述">{{ snap.description || '--' }}</el-descriptions-item>
        <el-descriptions-item label="系统人设">{{ snap.system_prompt || '--' }}</el-descriptions-item>
        <el-descriptions-item label="模型ID">{{ snap.model_id || '--' }}</el-descriptions-item>
        <el-descriptions-item label="知识库">
          <el-tag v-for="k in snap.knowledge_base_ids || []" :key="k" size="mini" class="tag-item">{{ k }}</el-tag>
          <span v-if="!(snap.knowledge_base_ids || []).length">--</span>
        </el-descriptions-item>
        <el-descriptions-item label="工具">
          <el-tag v-for="t in snap.tool_ids || []" :key="t" size="mini" class="tag-item">{{ t }}</el-tag>
          <span v-if="!(snap.tool_ids || []).length">--</span>
        </el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">发布信息</div>
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="发布类型">{{ detail.publish_type === 'gray' ? '灰度发布' : '全量发布' }}</el-descriptions-item>
        <el-descriptions-item label="灰度比例">{{ detail.publish_type === 'gray' ? (detail.gray_ratio + '%') : '--' }}</el-descriptions-item>
        <el-descriptions-item label="发布人">{{ detail.published_by_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="发布时间">{{ detail.published_at || '--' }}</el-descriptions-item>
        <el-descriptions-item label="审核人">{{ detail.reviewed_by_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ detail.reviewed_at || '--' }}</el-descriptions-item>
        <el-descriptions-item label="审核意见" :span="2">{{ detail.review_comment || '--' }}</el-descriptions-item>
      </el-descriptions>
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getPublishVersionDetail } from '../../../../api/aiPublish'

export default {
  name: 'VersionDetailDialog',
  data() {
    return { visible: false, detail: null }
  },
  computed: {
    snap() {
      if (!this.detail || !this.detail.config_snapshot) return {}
      return typeof this.detail.config_snapshot === 'string' ? JSON.parse(this.detail.config_snapshot) : this.detail.config_snapshot
    }
  },
  methods: {
    statusType(st) { return { draft: 'info', reviewing: 'warning', approved: 'success', published: 'primary', offline: 'danger' }[st] || 'info' },
    async open(id) {
      this.visible = true
      this.detail = null
      try {
        const res = await getPublishVersionDetail(id)
        this.detail = res.data || {}
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.ver-head { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.ver-num { font-weight: 700; font-size: 16px; }
.ver-name { color: #606266; }
.ver-desc { color: #909399; font-size: 13px; margin: 0 0 10px; }
.sub-title { font-weight: 600; margin: 14px 0 8px; font-size: 13px; }
.tag-item { margin: 2px 4px 2px 0; }
</style>
