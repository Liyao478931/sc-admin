<!-- 文件：admin/src/views/ai/app/components/AppDetailDialog.vue -->
<!-- 应用详情：基本信息 / 配置信息 / 调用趋势（待明细表）/ 最近调用（待明细表） -->
<template>
  <el-dialog title="应用详情" :visible="visible" @update:visible="$emit('update:visible', $event)" width="750px" top="6vh" @open="load">
    <div v-loading="loading">
      <template v-if="detail.id">
        <!-- 基本信息 -->
        <div class="sec-title">基本信息</div>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="应用名称">{{ detail.app_name }}</el-descriptions-item>
          <el-descriptions-item label="应用类型">
            <el-tag size="mini" :type="typeTag(detail.app_type)">{{ detail.type_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="detail.status === 1 ? 'success' : 'info'">{{ detail.status === 1 ? '启用' : '停用' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detail.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="调用次数">{{ detail.call_count || 0 }}</el-descriptions-item>
          <el-descriptions-item label="最后调用时间">{{ detail.last_call_time || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div class="desc-box" v-if="detail.description">描述：{{ detail.description }}</div>

        <!-- 配置信息 -->
        <div class="sec-title">配置信息</div>
        <div class="cfg-ref" v-if="detail.ref_name"><b>绑定：</b>{{ detail.ref_name }}</div>
        <div class="cfg-box"><pre>{{ formatJson(detail.config) }}</pre></div>

        <!-- 调用趋势 -->
        <div class="sec-title">调用趋势（近30天）</div>
        <div class="cfg-none">调用明细表（ai_app_call_logs）待建设，趋势数据暂不可用；当前累计调用 {{ detail.call_count || 0 }} 次。</div>

        <!-- 最近调用记录 -->
        <div class="sec-title">最近调用记录</div>
        <div class="cfg-none">（调用明细表待建设，暂无调用记录）</div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getAppDetail } from '@/api/aiApp'

export default {
  name: 'AppDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    appId: { type: Number, default: 0 }
  },
  data () {
    return { loading: false, detail: {} }
  },
  methods: {
    async load () {
      if (!this.appId) return
      this.loading = true
      try { const r = await getAppDetail(this.appId); if (r.code === 0) this.detail = r.data || {} } catch (e) {} finally { this.loading = false }
    },
    formatJson (obj) {
      if (obj === null || obj === undefined) return '(空)'
      try { return JSON.stringify(typeof obj === 'string' ? JSON.parse(obj) : obj, null, 2) } catch (e) { return String(obj) }
    },
    typeTag (t) { return { agent: 'primary', workflow: 'success', chat: 'warning' }[t] || 'info' }
  }
}
</script>

<style scoped>
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 14px 0 8px; }
.desc-box { margin-top: 8px; font-size: 13px; color: #606266; }
.cfg-ref { font-size: 13px; color: #409EFF; margin-bottom: 6px; }
.cfg-box { background: #f8f9fb; border-radius: 6px; padding: 10px; }
.cfg-box pre { font-size: 12px; margin: 0; white-space: pre-wrap; word-break: break-all; }
.cfg-none { font-size: 12px; color: #c0c4cc; padding: 6px 0; }
</style>
