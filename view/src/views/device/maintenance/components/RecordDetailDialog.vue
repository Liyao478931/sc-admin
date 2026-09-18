<template>
  <el-dialog title="保养记录详情" :visible.sync="visible" width="900px" :close-on-click-modal="false">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <div class="info-section">
            <div class="section-title">记录信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="记录编号">{{ detail.record_code || '-' }}</el-descriptions-item>
              <el-descriptions-item label="验收状态"><el-tag :type="statusType(detail.accept_status)" size="mini">{{ detail.accept_status_text }}</el-tag></el-descriptions-item>
              <el-descriptions-item label="执行日期">{{ detail.execute_time || '-' }}</el-descriptions-item>
              <el-descriptions-item label="计划名称">{{ detail.plan_name || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
          <div class="info-section">
            <div class="section-title">设备信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="设备名称">{{ detail.device_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="设备编码">{{ detail.device_code || '-' }}</el-descriptions-item>
              <el-descriptions-item label="保养等级">{{ detail.level_name || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
          <div class="info-section">
            <div class="section-title">执行信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="执行人">{{ detail.executor_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="验收人">{{ detail.acceptor_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="项目数">{{ detail.total_count || 0 }}</el-descriptions-item>
              <el-descriptions-item label="异常项"><span style="color:#F56C6C">{{ detail.abnormal_count || 0 }}</span></el-descriptions-item>
            </el-descriptions>
          </div>
          <div class="info-section">
            <div class="section-title">验收信息</div>
            <el-descriptions :column="2" border size="small">
              <el-descriptions-item label="验收时间">{{ detail.accept_time || '-' }}</el-descriptions-item>
              <el-descriptions-item label="驳回次数">{{ detail.reject_count || 0 }}</el-descriptions-item>
              <el-descriptions-item label="验收意见">{{ detail.accept_remark || '-' }}</el-descriptions-item>
              <el-descriptions-item label="驳回原因"><span style="color:#F56C6C">{{ detail.reject_reason || '-' }}</span></el-descriptions-item>
              <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
            </el-descriptions>
          </div>
        </el-tab-pane>

        <!-- 保养项目 -->
        <el-tab-pane label="保养项目" name="items">
          <el-table :data="detail.items || []" size="small" border stripe>
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="item_name" label="项目名称" min-width="140" />
            <el-table-column prop="operation_content" label="操作内容" min-width="140" show-overflow-tooltip />
            <el-table-column prop="check_standard" label="检查标准" min-width="130" show-overflow-tooltip />
            <el-table-column label="结果" width="80">
              <template slot-scope="{row}">
                <el-tag :type="row.result === 'normal' ? 'success' : 'danger'" size="mini">{{ row.result === 'normal' ? '✓ 正常' : '✗ 异常' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="异常描述" min-width="140" show-overflow-tooltip />
            <el-table-column label="异常照片" width="80">
              <template slot-scope="{row}">
                <el-image v-if="row.photo" :src="row.photo" :preview-src-list="[row.photo]" style="width:40px;height:40px;border-radius:4px" fit="cover" />
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 耗材使用 -->
        <el-tab-pane label="耗材使用" name="materials">
          <el-table :data="detail.materials || []" size="small" border stripe>
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="material_name" label="耗材名称" min-width="140" />
            <el-table-column prop="specification" label="规格" min-width="100" />
            <el-table-column prop="quantity" label="数量" width="80" />
            <el-table-column prop="unit" label="单位" width="80" />
          </el-table>
          <el-empty v-if="!(detail.materials || []).length" description="无耗材记录" :image-size="60" />
        </el-tab-pane>

        <!-- 附件 -->
        <el-tab-pane label="附件" name="attachments">
          <div class="attachment-grid">
            <el-image v-for="(img, i) in detail.attachments || []" :key="i" :src="img" :preview-src-list="detail.attachments" :initial-index="i"
              style="width:120px;height:120px;border-radius:8px;margin:6px" fit="cover" />
          </div>
          <el-empty v-if="!(detail.attachments || []).length" description="无附件" :image-size="60" />
        </el-tab-pane>
      </el-tabs>
    </div>
    <span slot="footer"><el-button type="primary" @click="visible = false">关闭</el-button></span>
  </el-dialog>
</template>

<script>
import { getRecordDetail } from '@/api/maintenanceRecord'

export default {
  name: 'RecordDetailDialog',
  props: {
    visible: Boolean,
    recordId: { type: Number, default: 0 }
  },
  data() {
    return {
      activeTab: 'info', loading: false, detail: {}
    }
  },
  watch: {
    visible(v) { if (v) this.loadDetail() }
  },
  methods: {
    async loadDetail() {
      this.loading = true
      try { const r = await getRecordDetail(this.recordId); if (r.code === 0) this.detail = r.data } catch (e) {}
      this.loading = false
    },
    statusType(s) { return { pending: 'warning', approved: 'success', rejected: 'danger' }[s] || '' }
  }
}
</script>

<style scoped>
.info-section { margin-bottom: 16px; }
.section-title { font-weight: 600; margin-bottom: 8px; padding-left: 8px; border-left: 3px solid #409EFF; }
.attachment-grid { display: flex; flex-wrap: wrap; }
</style>
