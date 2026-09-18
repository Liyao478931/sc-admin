<template>
  <el-dialog title="数据源详情" :visible.sync="visible" width="600px" append-to-body>
    <div v-if="detail" class="ds-detail">
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="数据源名称">{{ detail.ds_name }}</el-descriptions-item>
        <el-descriptions-item label="类型">
          <el-tag size="mini">{{ detail.ds_type_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag size="mini" :type="detail.status === 1 ? 'success' : 'info'">{{ detail.status === 1 ? '启用' : '停用' }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="同步状态">
          <el-tag size="mini" :type="syncType(detail.sync_status)">{{ detail.sync_status_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="最后同步时间">{{ detail.last_sync_time || '--' }}</el-descriptions-item>
        <el-descriptions-item label="同步次数">{{ detail.sync_count }}</el-descriptions-item>
        <el-descriptions-item label="最后同步记录数">{{ detail.last_sync_count }}</el-descriptions-item>
        <el-descriptions-item label="总同步记录数">{{ detail.total_sync_count }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detail.created_by_name }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.create_time }}</el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">数据源配置</div>
      <pre class="config-json">{{ JSON.stringify(detail.config, null, 2) }}</pre>

      <div class="sub-title">同步配置</div>
      <pre class="config-json">{{ JSON.stringify(detail.sync_config || {}, null, 2) }}</pre>

      <div class="sub-title">字段映射</div>
      <pre class="config-json">{{ JSON.stringify(detail.field_mapping || {}, null, 2) }}</pre>
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getDatasourceDetail } from '../../../../api/aiDatasource'

export default {
  name: 'DatasourceDetailDialog',
  data() {
    return { visible: false, detail: null }
  },
  methods: {
    syncType(st) { return { idle: 'info', syncing: 'warning', success: 'success', failed: 'danger' }[st] || 'info' },
    async open(id) {
      this.visible = true
      this.detail = null
      try {
        const res = await getDatasourceDetail(id)
        this.detail = res.data || {}
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.sub-title { font-weight: 600; margin: 14px 0 8px; font-size: 13px; }
.config-json { background: #f5f7fa; padding: 10px; border-radius: 4px; font-size: 12px; max-height: 200px; overflow: auto; margin: 0; }
</style>
