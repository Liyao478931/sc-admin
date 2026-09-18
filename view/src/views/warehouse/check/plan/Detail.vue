<!--
  文件：admin/src/views/warehouse/check/plan/Detail.vue
  功能：盘点计划详情（审核走统一审批）
  权限：warehouse:check:plan:view / edit / execute
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存盘点</el-breadcrumb-item>
      <el-breadcrumb-item>盘点计划</el-breadcrumb-item>
      <el-breadcrumb-item>计划详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">盘点计划详情 - {{ plan.plan_name || '' }}</span>
      <div class="header-right">
        <el-button size="small" @click="$router.push('/warehouse/check/plan')">返回列表</el-button>
        <el-button v-if="plan.status === 0" v-permission="'warehouse:check:plan:edit'" size="small" @click="$router.push(`/warehouse/check/plan/edit/${plan.id}`)">编辑</el-button>
        <el-button v-if="plan.status === 0" v-permission="'warehouse:check:plan:edit'" size="small" type="primary" @click="handleSubmit">提交审批</el-button>
        <el-button v-if="plan.status === 1" size="small" type="primary" @click="$router.push('/approval/my-tasks')">去统一审批待办审核</el-button>
        <el-button v-if="plan.status === 2" v-permission="'warehouse:check:plan:execute'" size="small" type="primary" @click="handleStart">开始执行</el-button>
        <el-button v-if="plan.status === 3" v-permission="'warehouse:check:plan:execute'" size="small" type="success" @click="handleComplete">完成任务</el-button>
        <el-button size="small" icon="el-icon-printer" @click="windowPrint">打印</el-button>
      </div>
    </div>

    <el-alert v-if="plan.status === 1" type="warning" :closable="false" class="approval-tip"
      title="盘点计划已提交统一审批，请到「统一审批 → 我的待办」执行审核通过/驳回；审核通过后将自动生成盘点任务。" />

    <el-card class="info-card" shadow="never">
      <div slot="header" class="card-header">
        <span>计划信息</span>
        <el-tag :type="plan.status_tag" size="mini">{{ plan.status_label }}</el-tag>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="计划编号">{{ plan.plan_no }}</el-descriptions-item>
        <el-descriptions-item label="计划名称">{{ plan.plan_name }}</el-descriptions-item>
        <el-descriptions-item label="盘点类型">{{ plan.plan_type_label }}</el-descriptions-item>
        <el-descriptions-item label="盘点仓库">{{ plan.warehouse_name }}</el-descriptions-item>
        <el-descriptions-item label="盘点方式">{{ plan.inventory_method_label }}</el-descriptions-item>
        <el-descriptions-item label="范围类型">{{ plan.scope_type_label }}</el-descriptions-item>
        <el-descriptions-item label="计划日期" :span="2">{{ plan.plan_date_range }}</el-descriptions-item>
        <el-descriptions-item label="预计耗时">{{ plan.expected_duration }} 小时</el-descriptions-item>
        <el-descriptions-item label="负责人">{{ plan.responsible_person_name }}</el-descriptions-item>
        <el-descriptions-item label="参与人员" :span="2">{{ participantsText }}</el-descriptions-item>
        <el-descriptions-item label="审批状态">{{ plan.approval_status_label }}</el-descriptions-item>
        <el-descriptions-item label="审批时间">{{ plan.approval_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="实际开始">{{ plan.actual_start_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="实际结束">{{ plan.actual_end_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ plan.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card class="info-card" shadow="never">
      <div slot="header" class="card-header"><span>盘点范围</span></div>
      <div v-if="plan.scope_type === 1" class="scope-empty">全仓库盘点</div>
      <el-tag v-else v-for="(it, i) in scope.items" :key="i" class="scope-tag" size="small">{{ it.name }}</el-tag>
      <div class="scope-count">范围 {{ scope.type_label }}，共 {{ scope.count }} 项</div>
    </el-card>

    <el-card v-if="plan.status >= 2" class="info-card" shadow="never">
      <div slot="header" class="card-header"><span>盘点任务</span></div>
      <el-table :data="tasks" size="small" border empty-text="暂无盘点任务">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column prop="task_no" label="任务编号" width="150" />
        <el-table-column prop="assignee_name" label="被分配人" width="100" />
        <el-table-column prop="location_name" label="货位" min-width="120" />
        <el-table-column label="物料数量" width="90" align="center">
          <template slot-scope="s">{{ (s.row.material_ids || []).length }}</template>
        </el-table-column>
        <el-table-column label="任务状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="expected_start_time" label="预计开始" width="160" align="center" />
        <el-table-column prop="expected_end_time" label="预计结束" width="160" align="center" />
      </el-table>
    </el-card>

    <el-card v-if="plan.status === 4" class="info-card" shadow="never">
      <div slot="header" class="card-header">
        <span>盘点结果</span>
        <span class="summary-text">总物料 {{ summary.total }} ｜ 盘盈 {{ summary.gain }}（{{ summary.gain_qty }}）｜ 盘亏 {{ summary.loss }}（{{ summary.loss_qty }}）</span>
      </div>
      <el-table :data="results" size="small" border empty-text="暂无盘点结果数据">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="130" />
        <el-table-column prop="material_name" label="物料名称" min-width="130" />
        <el-table-column prop="specification" label="规格型号" width="110" />
        <el-table-column prop="unit" label="单位" width="70" align="center" />
        <el-table-column prop="system_quantity" label="系统库存" width="100" align="center" />
        <el-table-column prop="actual_quantity" label="实际库存" width="100" align="center" />
        <el-table-column prop="difference_quantity" label="差异数量" width="100" align="center" />
        <el-table-column prop="location_name" label="货位" width="120" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 0 ? 'info' : (s.row.status === 1 ? 'success' : 'warning')">{{ ['待确认', '已确认', '已调整'][s.row.status] || '-' }}</el-tag></template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getPlanDetail, submitPlan, startPlan, completePlan } from '@/api/warehouse'

export default {
  name: 'InventoryPlanDetail',
  data () {
    return {
      plan: {}, scope: { items: [] }, tasks: [], results: [], summary: { total: 0, gain: 0, loss: 0 },
      loading: false
    }
  },
  computed: {
    participantsText () {
      const names = []
      this.tasks.forEach(t => { if (t.assignee_name && !names.includes(t.assignee_name)) names.push(t.assignee_name) })
      return names.join('、') || (this.plan.responsible_person_name || '-')
    }
  },
  created () { this.loadData() },
  methods: {
    async loadData () {
      this.loading = true
      try {
        const r = await getPlanDetail(this.$route.params.id)
        if (r.code === 0 && r.data) {
          this.plan = r.data.plan || {}
          this.scope = r.data.scope || { items: [] }
          this.tasks = r.data.tasks || []
          this.results = r.data.results || []
          this.summary = r.data.summary || { total: 0, gain: 0, loss: 0 }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSubmit () {
      this.$confirm('确认提交该盘点计划审批吗？提交后将进入统一审批待办审核', '提交审批', { type: 'warning' }).then(async () => {
        try {
          const r = await submitPlan(this.plan.id)
          if (r.code === 0) { this.$message.success(r.msg || '已提交审批'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleStart () {
      this.$confirm('确认开始执行该盘点计划吗？', '开始执行', { type: 'warning' }).then(async () => {
        try {
          const r = await startPlan(this.plan.id)
          if (r.code === 0) { this.$message.success('已开始执行'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleComplete () {
      this.$confirm('确认完成该盘点计划吗？完成后生成盘点结果', '完成任务', { type: 'warning' }).then(async () => {
        try {
          const r = await completePlan(this.plan.id)
          if (r.code === 0) { this.$message.success('盘点已完成'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    windowPrint () { window.print() }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 16px 20px; border-radius: 8px; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 600; color: #303133; }
.header-right { display: flex; gap: 8px; flex-wrap: wrap; }
.approval-tip { margin-bottom: 14px; }
.info-card { margin-bottom: 14px; border-radius: 8px; }
.card-header { display: flex; justify-content: space-between; align-items: center; font-weight: 600; }
.scope-tag { margin: 4px 6px 4px 0; }
.scope-empty { color: #909399; }
.scope-count { color: #909399; font-size: 12px; margin-top: 10px; }
.summary-text { color: #606266; font-size: 13px; font-weight: 400; }
</style>
