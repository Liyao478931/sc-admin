<!--
  文件：admin/src/views/production/execute/dispatch/Detail.vue
  功能：派工详情（工单概要 + 工序任务明细 + 状态流转操作）
  权限：production:dispatch:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>工单派工</el-breadcrumb-item>
      <el-breadcrumb-item>派工详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ dispatch.dispatch_no || '派工详情' }}</span>
      <div class="header-actions">
        <el-button v-if="dispatch.status === 0" v-permission="'production:dispatch:edit'" size="small" @click="$router.push(`/production/execute/dispatch/edit/${dispatch.id}`)">编辑</el-button>
        <el-button v-if="dispatch.status === 0" v-permission="'production:dispatch:edit'" size="small" type="primary" @click="handleAction('confirm')">确认派工</el-button>
        <el-button v-if="dispatch.status === 1" v-permission="'production:dispatch:edit'" size="small" type="primary" @click="handleAction('start')">开始执行</el-button>
        <el-button v-if="dispatch.status === 2" v-permission="'production:dispatch:edit'" size="small" type="success" @click="handleAction('complete')">完成任务</el-button>
        <el-button v-if="dispatch.status === 0 || dispatch.status === 1" v-permission="'production:dispatch:edit'" size="small" type="danger" plain @click="handleAction('cancel')">撤销</el-button>
        <el-button size="small" @click="$router.push('/production/execute/dispatch/list')">返回列表</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card" v-loading="loading">
      <div class="sub-title">派工概要</div>
      <el-descriptions :column="3" border size="small">
        <el-descriptions-item label="派工单编号">{{ dispatch.dispatch_no }}</el-descriptions-item>
        <el-descriptions-item label="关联工单">
          <span class="link-blue" @click="$router.push(`/production/plan/order/detail/${dispatch.work_order_id}`)">{{ dispatch.work_order_no }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="派工类型">
          <el-tag :type="dispatch.dispatch_type_tag" size="mini">{{ dispatch.dispatch_type_label }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="派工人">{{ dispatch.dispatcher_name }}</el-descriptions-item>
        <el-descriptions-item label="派工日期">{{ dispatch.dispatch_date }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="dispatch.status_tag" size="mini">{{ dispatch.status_label }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="计划开始日期">{{ dispatch.planned_start_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="计划完成日期">{{ dispatch.planned_end_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注">{{ dispatch.remark || '-' }}</el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">工序任务明细</div>
      <el-table :data="tasks" size="small" border empty-text="暂无工序任务">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="process_name" label="工序名称" min-width="110" />
        <el-table-column prop="workstation_name" label="指定工位" width="120" show-overflow-tooltip />
        <el-table-column prop="device_name" label="指定设备" width="140" show-overflow-tooltip />
        <el-table-column :label="dispatch.dispatch_type === 2 ? '被派班组' : '被派工人'" width="110">
          <template slot-scope="s">{{ dispatch.dispatch_type === 2 ? s.row.team_name : s.row.worker_name }}</template>
        </el-table-column>
        <el-table-column label="计划数量" width="90" align="right"><template slot-scope="s">{{ Number(s.row.planned_quantity) }}</template></el-table-column>
        <el-table-column label="已完成数量" width="100" align="right"><template slot-scope="s">{{ Number(s.row.completed_quantity) }}</template></el-table-column>
        <el-table-column label="任务状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getDispatchDetail, confirmDispatch, startDispatch, completeDispatch, cancelDispatch } from '@/api/production'

export default {
  name: 'ProductionDispatchDetail',
  data () {
    return {
      dispatch: {}, tasks: [], loading: false, acting: false
    }
  },
  created () { this.loadData() },
  methods: {
    async loadData () {
      this.loading = true
      try {
        const r = await getDispatchDetail(this.$route.params.id)
        if (r.code === 0 && r.data) {
          this.dispatch = r.data.dispatch || {}
          this.tasks = r.data.tasks || []
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleAction (cmd) {
      const map = {
        confirm: { api: confirmDispatch, tip: '确认派工后，工单状态将变为「已派工」且不可再编辑，是否确认？', title: '确认派工' },
        start: { api: startDispatch, tip: '确认开始执行？工单状态将变为「进行中」。', title: '开始执行' },
        complete: { api: completeDispatch, tip: '确认所有工序任务已完成？工单状态将变为「待质检」。', title: '完成任务' },
        cancel: { api: cancelDispatch, tip: '确认撤销该派工单？工单将恢复为「待派工」。', title: '撤销派工' }
      }
      const m = map[cmd]
      this.$confirm(m.tip, m.title, { type: 'warning' }).then(async () => {
        this.acting = true
        try {
          const r = await m.api(this.dispatch.id)
          if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {} finally { this.acting = false }
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
