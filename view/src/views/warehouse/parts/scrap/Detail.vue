<!--
  文件：admin/src/views/warehouse/parts/scrap/Detail.vue
  功能：报废单详情（信息/流水/操作日志）
  权限：warehouse:scrap:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>报废出库</el-breadcrumb-item>
      <el-breadcrumb-item>报废单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">报废单详情 - {{ detail.scrap_no || '' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push({ path: '/warehouse/parts/scrap/list' })">返回列表</el-button>
        <el-button v-if="detail.status === 0 || detail.status === 4" v-permission="'warehouse:scrap:edit'" size="small" type="primary" @click="goEdit">编辑</el-button>
        <el-button v-if="detail.status === 0" size="small" @click="handleSubmit">提交审核</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:scrap:audit'" size="small" type="success" @click="handleApprove">审核通过</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:scrap:audit'" size="small" type="danger" @click="handleReject">审核驳回</el-button>
        <el-button v-if="detail.status === 2" v-permission="'warehouse:scrap:confirm'" size="small" type="warning" @click="handleConfirm">确认报废</el-button>
        <el-button size="small" icon="el-icon-printer" @click="window.print()">打印</el-button>
      </div>
    </div>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-header">
        <span>报废单信息</span>
        <el-tag :type="detail.status_tag" size="small">{{ detail.status_label }}</el-tag>
      </div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="报废单编号">{{ detail.scrap_no }}</el-descriptions-item>
        <el-descriptions-item label="报废类型">{{ detail.scrap_type_label }}</el-descriptions-item>
        <el-descriptions-item label="关联领料单">
          <el-link v-if="detail.pick_no" type="primary" @click="goPickDetail">{{ detail.pick_no }}</el-link><span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="物料">{{ detail.material_name }}<span v-if="detail.spec"> / {{ detail.spec }}</span></el-descriptions-item>
        <el-descriptions-item label="单位">{{ detail.unit || '-' }}</el-descriptions-item>
        <el-descriptions-item label="报废部门">{{ detail.department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请人">{{ detail.applicant_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="报废日期">{{ detail.scrap_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="报废数量">{{ Number(detail.scrap_quantity).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="报废单价">¥ {{ Number(detail.scrap_price).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="报废总价">¥ {{ Number(detail.scrap_total).toFixed(2) }}</el-descriptions-item>
        <el-descriptions-item label="处理方式">{{ detail.disposal_label || '-' }}</el-descriptions-item>
        <el-descriptions-item label="报废状态">{{ detail.status_label }}</el-descriptions-item>
        <el-descriptions-item label="当前库存">{{ Number(detail.current_stock || 0).toLocaleString() }}</el-descriptions-item>
        <el-descriptions-item label="审核人">{{ detail.auditor_name || detail.auditor_id || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ detail.audit_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="审核备注" :span="2">{{ detail.audit_remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="报废原因" :span="2">{{ detail.scrap_reason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.create_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detail.update_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card v-if="detail.status === 3" shadow="never" class="logs-card">
      <div slot="header" class="card-header"><span>库存流水</span></div>
      <el-table :data="detail.stock_flows || []" size="small" border empty-text="暂无流水">
        <el-table-column label="变动类型" width="100" align="center"><template slot-scope="s"><el-tag size="mini" type="danger">报废出库</el-tag></template></el-table-column>
        <el-table-column prop="flow_quantity" label="变动数量" width="100" align="right" />
        <el-table-column prop="cost_price" label="成本单价" width="100" align="right" />
        <el-table-column prop="cost_total" label="成本总价" width="110" align="right" />
        <el-table-column prop="before_stock" label="变动前库存" width="100" align="right" />
        <el-table-column prop="after_stock" label="变动后库存" width="100" align="right" />
        <el-table-column prop="operator_name" label="操作人" width="100" align="center" />
        <el-table-column prop="flow_time" label="变动时间" width="160" align="center" />
      </el-table>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="card-header">
        <span>操作日志</span>
        <span class="log-count">共 {{ (detail.logs || []).length }} 条记录</span>
      </div>
      <el-timeline v-if="detail.logs && detail.logs.length">
        <el-timeline-item v-for="lg in detail.logs" :key="lg.id" :timestamp="lg.action_time || ''" placement="top" :type="lg.action_tag === 'danger' ? 'danger' : (lg.action_tag === 'success' ? 'success' : 'primary')">
          <div>
            <el-tag :type="lg.action_tag" size="mini">{{ lg.action_label }}</el-tag>
            <span class="log-operator">{{ lg.operator_name }}</span>
            <span v-if="lg.from_status_text || lg.to_status_text" class="log-status">{{ lg.from_status_text }} → {{ lg.to_status_text }}</span>
            <div v-if="lg.remark" class="log-remark">{{ lg.remark }}</div>
          </div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无操作记录" />
    </el-card>
  </div>
</template>

<script>
import { getScrapDetail, submitScrap, approveScrap, rejectScrap, confirmScrap } from '../../../../api/warehouse'

export default {
  name: 'WarehouseScrapDetail',
  data () {
    return { id: 0, loading: false, detail: {} }
  },
  created () {
    this.id = Number(this.$route.params.id)
    this.loadDetail()
  },
  methods: {
    async loadDetail () {
      this.loading = true
      try {
        const r = await getScrapDetail(this.id)
        if (r.code === 0 && r.data) this.detail = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {} finally { this.loading = false }
    },
    goEdit () { this.$router.push({ path: `/warehouse/parts/scrap/edit/${this.id}` }) },
    goPickDetail () { this.$router.push({ path: `/warehouse/parts/pick/detail/${this.detail.pick_id}` }) },
    handleSubmit () {
      this.$confirm(`确认提交报废单 ${this.detail.scrap_no} 审核吗？提交后不可再编辑。`, '提交审核', { type: 'warning' }).then(async () => {
        try {
          const r = await submitScrap(this.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.loadDetail() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleApprove () {
      this.$prompt('请输入审核备注（可选）', '审核通过', { inputPlaceholder: '审核备注', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await approveScrap(this.id, value || '')
          if (r.code === 0) { this.$message.success('审核已通过'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject () {
      this.$prompt('请输入驳回原因（必填）', '审核驳回', { inputPlaceholder: '驳回原因' }).then(async ({ value }) => {
        if (!value || !value.trim()) { this.$message.warning('驳回原因必填'); return }
        try {
          const r = await rejectScrap(this.id, value.trim())
          if (r.code === 0) { this.$message.success('已驳回'); this.loadDetail() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleConfirm () {
      this.$confirm('确认执行报废出库操作吗？将扣减库存并生成库存流水。', '确认报废', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmScrap(this.id)
          if (r.code === 0) { this.$message.success(r.msg || '报废成功'); this.loadDetail() } else this.$message.error(r.msg || '报废失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.info-card { margin-bottom: 16px; }
.logs-card { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.log-count { color: #909399; font-size: 12px; }
.log-operator { margin-left: 8px; color: #606266; font-size: 13px; }
.log-status { margin-left: 8px; color: #909399; font-size: 12px; }
.log-remark { color: #606266; font-size: 13px; margin-top: 4px; }
</style>
