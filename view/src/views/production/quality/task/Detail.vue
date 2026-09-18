<!--
  文件：admin/src/views/production/quality/task/Detail.vue
  功能：检验详情（检验概要 + 检验项目明细）
  权限：quality:task:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>检验任务</el-breadcrumb-item>
      <el-breadcrumb-item>检验详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ inspection.inspection_no || '检验详情' }}</span>
      <div class="header-actions">
        <el-button v-if="inspection.status === 0 || inspection.status === 1" v-permission="'quality:task:execute'" size="small" type="primary" @click="handleExecute">执行检验</el-button>
        <el-button size="small" @click="$router.push('/production/quality/task')">返回列表</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card" v-loading="loading">
      <div class="sub-title">检验概要</div>
      <el-descriptions :column="3" border size="small">
        <el-descriptions-item label="检验单编号">{{ inspection.inspection_no }}</el-descriptions-item>
        <el-descriptions-item label="关联工单">
          <span class="link-blue" @click="$router.push(`/production/plan/order/detail/${inspection.work_order_id}`)">{{ inspection.work_order_no }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="产品名称">{{ inspection.product_name }}</el-descriptions-item>
        <el-descriptions-item label="质检标准">{{ inspection.standard_name }}</el-descriptions-item>
        <el-descriptions-item label="质检员">{{ inspection.inspector_name }}</el-descriptions-item>
        <el-descriptions-item label="检验日期">{{ inspection.inspection_date }}</el-descriptions-item>
        <el-descriptions-item label="检验结果">
          <el-tag :type="inspection.result_tag" size="mini">{{ inspection.result_label }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="检验状态">
          <el-tag :type="inspection.status_tag" size="mini">{{ inspection.status_label }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="检验时间">{{ inspection.inspection_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="检验结论" :span="3">{{ inspection.conclusion || '-' }}</el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">检验项目明细</div>
      <el-table :data="items" size="small" border empty-text="暂无检验项目">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="item_name" label="项目名称" min-width="130" />
        <el-table-column label="类型" width="70" align="center"><template slot-scope="s">{{ itemTypeOptions[s.row.item_type] }}</template></el-table-column>
        <el-table-column prop="standard_value" label="标准值" width="140" show-overflow-tooltip />
        <el-table-column label="上下限" width="130" align="center"><template slot-scope="s">{{ s.row.lower_limit ?? '-' }} ~ {{ s.row.upper_limit ?? '-' }} {{ s.row.unit || '' }}</template></el-table-column>
        <el-table-column prop="measured_value" label="实测值" width="130" align="center"><template slot-scope="s">{{ s.row.measured_value || '-' }}</template></el-table-column>
        <el-table-column label="判定" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.is_qualified === 1 ? 'success' : 'danger'" size="mini">{{ s.row.is_qualified_label }}</el-tag></template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getQualityTaskDetail, executeQualityTask } from '@/api/production'

export default {
  name: 'QualityTaskDetail',
  data () {
    return { inspection: {}, items: [], itemTypeOptions: { 1: '文本', 2: '数值', 3: '布尔' }, loading: false }
  },
  created () { this.loadData() },
  methods: {
    async loadData () {
      this.loading = true
      try {
        const r = await getQualityTaskDetail(this.$route.params.id)
        if (r.code === 0 && r.data) { this.inspection = r.data.inspection || {}; this.items = r.data.items || [] }
      } catch (e) {} finally { this.loading = false }
    },
    handleExecute () {
      this.$confirm(`确认执行检验单 ${this.inspection.inspection_no}？执行后判定为「${this.inspection.result_label}」并联动工单与接收单状态。`, '执行检验', { type: 'warning' }).then(async () => {
        try {
          const r = await executeQualityTask(this.inspection.id)
          if (r.code === 0) { this.$message.success(r.msg || '执行完成'); this.loadData() } else this.$message.error(r.msg || '执行失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 14px 20px; border-radius: 8px 8px 0 0; border-bottom: 1px solid #ebeef5; }
.page-title { font-size: 18px; font-weight: 700; }
.header-actions { display: flex; gap: 10px; }
.form-card { margin-top: 12px; border-radius: 8px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 16px 0 10px; color: #303133; }
.link-blue { color: #409EFF; cursor: pointer; }
</style>
