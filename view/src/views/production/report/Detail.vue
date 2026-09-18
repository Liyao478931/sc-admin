<!--
  文件：admin/src/views/production/report/Detail.vue
  功能：报工详情（基本信息/分配明细/审核日志）
  权限：production:report:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>生产报工</el-breadcrumb-item>
      <el-breadcrumb-item>报工详情</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="detail-card" v-loading="loading">
      <div slot="header" class="detail-header">
        <span class="detail-title">{{ detail.report_no || '' }}</span>
        <el-tag v-if="detail.status_label" :type="detail.status_tag" size="small">{{ detail.status_label }}</el-tag>
      </div>

      <div v-if="detail.id" class="detail-body">
        <el-descriptions :column="3" border size="small">
          <el-descriptions-item label="关联工单"><span class="link-blue" @click="goOrder">{{ detail.work_order_no }}</span></el-descriptions-item>
          <el-descriptions-item label="报工模式">{{ detail.report_type_label }}</el-descriptions-item>
          <el-descriptions-item label="任务类型">{{ detail.task_type_label }}</el-descriptions-item>
          <el-descriptions-item label="报工人">{{ detail.reporter_name }}</el-descriptions-item>
          <el-descriptions-item label="部门">{{ detail.department_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="报工日期">{{ detail.report_date }}</el-descriptions-item>
          <el-descriptions-item label="总工分"><b>{{ Number(detail.total_score) }}</b></el-descriptions-item>
          <el-descriptions-item label="审核人">{{ detail.auditor_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核时间">{{ detail.audit_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="任务描述" :span="3">{{ detail.task_description || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核备注" :span="3">{{ detail.audit_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="3">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <div class="sub-title">设备信息</div>
        <el-descriptions :column="3" border size="small" style="margin-bottom:16px">
          <el-descriptions-item label="设备名称">{{ detail.device_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="设备编码">{{ detail.device_code || '-' }}</el-descriptions-item>
          <el-descriptions-item label="设备使用时长">{{ Number(detail.duration || 0) }} 小时</el-descriptions-item>
          <el-descriptions-item label="完成数量">{{ detail.quantity || 1 }} 件</el-descriptions-item>
          <el-descriptions-item label="工分（定额×数量）">{{ Number(detail.calculated_score || 0) }}</el-descriptions-item>
          <el-descriptions-item label="报工日期">{{ detail.report_date }}</el-descriptions-item>
        </el-descriptions>

        <div v-if="detail.materials && detail.materials.length" class="sub-title">材料配件</div>
        <el-table v-if="detail.materials && detail.materials.length" :data="detail.materials" size="small" border style="margin-bottom:16px">
          <el-table-column prop="material_code" label="物料编码" width="120" />
          <el-table-column prop="material_name" label="物料名称" min-width="140" />
          <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
          <el-table-column prop="unit" label="单位" width="60" align="center" />
          <el-table-column label="使用数量" width="100" align="right"><template slot-scope="s">{{ s.row.quantity }}</template></el-table-column>
        </el-table>

        <div v-if="detail.photos && detail.photos.length" class="sub-title">作业照片</div>
        <div v-if="detail.photos && detail.photos.length" class="photo-grid">
          <el-image v-for="(u, idx) in detail.photos" :key="idx" :src="u" fit="cover" class="photo-img" :preview-src-list="detail.photos" :initial-index="idx" />
        </div>

        <div class="sub-title">工分分配明细</div>
        <el-table :data="detail.items || []" size="small" border>
          <el-table-column type="index" label="#" width="55" align="center" />
          <el-table-column prop="worker_name" label="员工姓名" min-width="160" />
          <el-table-column label="分配工分" width="120" align="right"><template slot-scope="s"><b>{{ Number(s.row.allocated_score) }}</b></template></el-table-column>
          <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
        </el-table>

        <div class="sub-title">审核日志</div>
        <el-timeline v-if="detail.logs && detail.logs.length" class="log-timeline">
          <el-timeline-item v-for="l in detail.logs" :key="l.id" :timestamp="l.created_at" placement="top">
            <b>{{ l.action_label }}</b>（{{ l.operator_name }}）
            <span v-if="l.before_status !== l.after_status">：{{ statusText(l.before_status) }} → {{ statusText(l.after_status) }}</span>
            <div v-if="l.remark" class="log-remark">{{ l.remark }}</div>
          </el-timeline-item>
        </el-timeline>
        <div v-else class="no-data">暂无审核日志</div>

        <div class="action-bar">
          <el-button size="small" @click="$router.push('/production/report/list')">返回列表</el-button>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
import { getReportDetail } from '@/api/production'

export default {
  name: 'ProductionReportDetail',
  data () {
    return { detail: {}, loading: false }
  },
  created () { this.loadData() },
  methods: {
    statusText (s) { return { 0: '草稿', 1: '待审核', 2: '已通过', 3: '已驳回', 4: '已撤销' }[s] || (s ?? '--') },
    async loadData () {
      this.loading = true
      try {
        const r = await getReportDetail(this.$route.params.id)
        if (r.code === 0 && r.data) this.detail = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {} finally { this.loading = false }
    },
    goOrder () { this.$router.push(`/production/plan/order/detail/${this.detail.work_order_id}`) }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.detail-card { border-radius: 8px; }
.detail-header { display: flex; align-items: center; gap: 12px; }
.detail-title { font-size: 16px; font-weight: 600; }
.detail-body { padding: 4px 8px; }
.link-blue { color: #409EFF; cursor: pointer; }
.sub-title { font-size: 14px; font-weight: 600; margin: 16px 0 10px; }
.log-timeline { padding-left: 4px; }
.log-remark { color: #909399; font-size: 12px; }
.no-data { color: #909399; font-size: 12px; padding: 10px 0; }
.photo-grid { display: flex; flex-wrap: wrap; gap: 10px; margin: 4px 0 16px; }
.photo-img { width: 100px; height: 100px; border-radius: 4px; border: 1px solid #ebeef5; }
.action-bar { margin-top: 16px; }
</style>
